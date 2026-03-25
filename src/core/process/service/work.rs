use {os_info::Type, which::which};

use super::arch::{Service, Launcher, Spec, Manager, AppResult, AppError};
use super::index::SERVICES;

impl Service {

    pub fn get ( name: &str ) -> AppResult<Self> {

        let key = name.trim();
        let has = |spec: &Spec| spec.name.eq_ignore_ascii_case(key);

        SERVICES.iter().find(|(name, service)| {
            name.eq_ignore_ascii_case(key)
                || has(&service.windows)
                || has(&service.launchd)
                || has(&service.systemd)
        }).map(|(_, tool)| *tool).ok_or_else(|| AppError::command_not_found(key))

    }

    pub fn launcher () -> AppResult<Launcher> {

        match os_info::get().os_type() {
            Type::Windows => Ok(Launcher::Windows),
            Type::Macos   => {
                if which("launchctl").is_ok() { return Ok(Launcher::Launchd); }
                Err(AppError::cannot_detect("launcher"))
            },
            _ => {
                if which("systemctl").is_ok() { return Ok(Launcher::Systemd); }
                Err(AppError::cannot_detect("launcher"))
            }
        }

    }

    pub fn spec ( name: &str ) -> AppResult<Spec> {

        let service = Self::get(name)?;

        Ok(match Self::launcher()? {
            Launcher::Windows => service.windows,
            Launcher::Launchd => service.launchd,
            Launcher::Systemd => service.systemd,
        })

    }

    pub fn has ( name: &str ) -> bool {

        match Self::launcher() {
            Ok(Launcher::Windows) => Manager::try_run("sc", &["query", name]).is_ok(),
            Ok(Launcher::Launchd) => Manager::try_run("launchctl", &["print", &format!("system/{}", name)]).is_ok(),
            Ok(Launcher::Systemd) => Manager::try_run("systemctl", &["cat", name]).is_ok(),
            Err(_) => false,
        }

    }

    pub fn need ( name: &str ) -> AppResult<()> {

        if Self::has(name) { return Ok(()); }
        Err(AppError::command_not_found(name))

    }

    pub fn install ( name: &str ) -> AppResult<()> {

        let service = Self::get(name)?;

        match Self::launcher()? {
            Launcher::Windows => Launcher::windows_install(service.windows),
            Launcher::Launchd => Launcher::launchd_install(service.launchd),
            Launcher::Systemd => Launcher::systemd_install(service.systemd),
        }

    }

    pub fn remove ( name: &str ) -> AppResult<()> {

        match Self::launcher()? {
            Launcher::Windows => Launcher::windows_remove(name),
            Launcher::Launchd => Launcher::launchd_remove(name),
            Launcher::Systemd => Launcher::systemd_remove(name),
        }

    }

    pub fn ensure ( name: &str ) -> AppResult<()> {

        if !Self::has(name) { Self::install(name)?; }
        Self::need(name)

    }

    pub fn start ( name: &str ) -> AppResult<()> {

        Self::ensure(name)?;

        match Self::launcher()? {
            Launcher::Windows => Manager::try_run("sc", &["start", name]),
            Launcher::Launchd => Manager::try_run("launchctl", &["start", name]),
            Launcher::Systemd => Manager::try_run("systemctl", &["start", name]),
        }

    }

    pub fn stop ( name: &str ) -> AppResult<()> {

        Self::need(name)?;

        match Self::launcher()? {
            Launcher::Windows => Manager::try_run("sc", &["stop", name]),
            Launcher::Launchd => Manager::try_run("launchctl", &["stop", name]),
            Launcher::Systemd => Manager::try_run("systemctl", &["stop", name]),
        }

    }

    pub fn restart ( name: &str ) -> AppResult<()> {

        Self::ensure(name)?;

        match Self::launcher()? {
            Launcher::Systemd => Manager::try_run("systemctl", &["restart", name]),
            Launcher::Launchd => {
                let _ = Manager::try_run("launchctl", &["stop", name]);
                Manager::try_run("launchctl", &["start", name])
            }
            Launcher::Windows => {
                let _ = Manager::try_run("sc", &["stop", name]);
                Manager::try_run("sc", &["start", name])
            }
        }

    }

    pub fn enable ( name: &str ) -> AppResult<()> {

        Self::ensure(name)?;

        match Self::launcher()? {
            Launcher::Windows => Manager::try_run("sc", &["config", name, "start= auto"]),
            Launcher::Launchd => Manager::try_run("launchctl", &["enable", &format!("system/{}", name)]),
            Launcher::Systemd => Manager::try_run("systemctl", &["enable", name]),
        }

    }

    pub fn disable ( name: &str ) -> AppResult<()> {

        Self::need(name)?;

        match Self::launcher()? {
            Launcher::Windows => Manager::try_run("sc", &["config", name, "start= disabled"]),
            Launcher::Launchd => Manager::try_run("launchctl", &["disable", &format!("system/{}", name)]),
            Launcher::Systemd => Manager::try_run("systemctl", &["disable", name]),
        }

    }

    pub fn status ( name: &str ) -> AppResult<()> {

        Self::need(name)?;

        match Self::launcher()? {
            Launcher::Windows => Manager::try_run("sc", &["query", name]),
            Launcher::Launchd => Manager::try_run("launchctl", &["print", &format!("system/{}", name)]),
            Launcher::Systemd => Manager::try_run("systemctl", &["status", name, "--no-pager"]),
        }

    }

    pub fn logs ( name: &str, lines: usize ) -> AppResult<()> {

        Self::need(name)?;
        let lines = lines.max(1).to_string();

        match Self::launcher()? {
            Launcher::Windows => Manager::try_run("wevtutil", &["qe", "System", &format!("/c:{}", lines), "/rd:true", "/f:text"]),
            Launcher::Systemd => Manager::try_run("journalctl", &["-u", name, "-n", &lines, "--no-pager"]),
            Launcher::Launchd => {
                Manager::try_run("log", &[
                    "show", "--style", "compact", "--last", "1h", "--predicate",
                    &format!("process == \"{}\" OR eventMessage CONTAINS[c] \"{}\"", name, name),
                ])
            }
        }

    }

    pub fn running ( name: &str ) -> bool {

        if !Self::has(name) { return false; }

        match Self::launcher() {
            Ok(Launcher::Windows) =>
                Manager::try_run_output("sc", &["query", name])
                    .ok()
                    .and_then(|output| String::from_utf8(output.stdout).ok())
                    .map(|text| text.lines().any(|line| line.trim().starts_with("STATE") && line.contains("RUNNING")))
                    .unwrap_or(false),
            Ok(Launcher::Launchd) =>
                Manager::try_run_output("launchctl", &["print", &format!("system/{}", name)])
                    .ok()
                    .and_then(|output| String::from_utf8(output.stdout).ok())
                    .map(|text| text.contains("state = running") || text.contains("\"state\" = \"running\""))
                    .unwrap_or(false),
            Ok(Launcher::Systemd) => Manager::try_run("systemctl", &["is-active", "--quiet", name]).is_ok(),
            Err(_) => false,
        }

    }

}
