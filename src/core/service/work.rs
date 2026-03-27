use {os_info::Type, which::which};

use super::arch::{Service, Provider, Spec, Systemd, Launchd, Winsc, Manager, AppResult, AppError};
use super::index::SERVICES;

impl Service {

    pub fn provider () -> AppResult<Provider> {

        match os_info::get().os_type() {
            Type::Windows => {
                return Ok(Provider::Winsc);
            },
            Type::Macos   => {
                if which("launchctl").is_ok() { return Ok(Provider::Launchd); }
                Err(AppError::cannot_detect("provider"))
            },
            _ => {
                if which("systemctl").is_ok() { return Ok(Provider::Systemd); }
                Err(AppError::cannot_detect("provider"))
            }
        }

    }

    pub fn get ( name: &str ) -> AppResult<Service> {

        let key = name.trim();
        let has = |spec: &Spec| spec.name.eq_ignore_ascii_case(key);

        SERVICES.iter().find(|(name, service)| {
            name.eq_ignore_ascii_case(key)
                || has(&service.winsc)
                || has(&service.launchd)
                || has(&service.systemd)
        }).map(|(_, tool)| *tool).ok_or_else(|| AppError::unsupported_service(key))

    }

    pub fn spec ( name: &str ) -> AppResult<Spec> {

        let service = Self::get(name)?;

        Ok(match Self::provider()? {
            Provider::Systemd => service.systemd,
            Provider::Launchd => service.launchd,
            Provider::Winsc   => service.winsc,
        })

    }


    pub fn has ( name: &str ) -> bool {

        match Self::provider() {
            Ok(Provider::Systemd) => Manager::try_run("systemctl", &["cat", name]).is_ok(),
            Ok(Provider::Launchd) => Manager::try_run("launchctl", &["print", &format!("system/{}", name)]).is_ok(),
            Ok(Provider::Winsc)   => Manager::try_run("sc", &["query", name]).is_ok(),
            Err(_) => false,
        }

    }

    pub fn need ( name: &str ) -> AppResult<()> {

        if Self::has(name) { return Ok(()); }
        Err(AppError::missing_service(name))

    }

    pub fn install ( name: &str ) -> AppResult<()> {

        let service = Self::get(name)?;

        match Self::provider()? {
            Provider::Systemd => Systemd::install(service.systemd),
            Provider::Launchd => Launchd::install(service.launchd),
            Provider::Winsc   => Winsc::install(service.winsc),
        }

    }

    pub fn remove ( name: &str ) -> AppResult<()> {

        match Self::provider()? {
            Provider::Systemd => Systemd::remove(name),
            Provider::Launchd => Launchd::remove(name),
            Provider::Winsc   => Winsc::remove(name),
        }

    }

    pub fn ensure ( name: &str ) -> AppResult<()> {

        if !Self::has(name) { Self::install(name)?; }
        Self::need(name)

    }

    pub fn start ( name: &str ) -> AppResult<()> {

        Self::ensure(name)?;

        match Self::provider()? {
            Provider::Systemd => Manager::try_run("systemctl", &["start", name]),
            Provider::Launchd => Manager::try_run("launchctl", &["start", name]),
            Provider::Winsc   => Manager::try_run("sc", &["start", name]),
        }

    }

    pub fn stop ( name: &str ) -> AppResult<()> {

        Self::need(name)?;

        match Self::provider()? {
            Provider::Systemd => Manager::try_run("systemctl", &["stop", name]),
            Provider::Launchd => Manager::try_run("launchctl", &["stop", name]),
            Provider::Winsc   => Manager::try_run("sc", &["stop", name]),
        }

    }

    pub fn restart ( name: &str ) -> AppResult<()> {

        Self::ensure(name)?;

        match Self::provider()? {
            Provider::Systemd => Manager::try_run("systemctl", &["restart", name]),
            Provider::Launchd => {
                let _ = Manager::try_run("launchctl", &["stop", name]);
                Manager::try_run("launchctl", &["start", name])
            }
            Provider::Winsc => {
                let _ = Manager::try_run("sc", &["stop", name]);
                Manager::try_run("sc", &["start", name])
            }
        }

    }

    pub fn enable ( name: &str ) -> AppResult<()> {

        Self::ensure(name)?;

        match Self::provider()? {
            Provider::Systemd => Manager::try_run("systemctl", &["enable", name]),
            Provider::Launchd => Manager::try_run("launchctl", &["enable", &format!("system/{}", name)]),
            Provider::Winsc   => Manager::try_run("sc", &["config", name, "start= auto"]),
        }

    }

    pub fn disable ( name: &str ) -> AppResult<()> {

        Self::need(name)?;

        match Self::provider()? {
            Provider::Systemd => Manager::try_run("systemctl", &["disable", name]),
            Provider::Launchd => Manager::try_run("launchctl", &["disable", &format!("system/{}", name)]),
            Provider::Winsc   => Manager::try_run("sc", &["config", name, "start= disabled"]),
        }

    }

    pub fn alive ( name: &str ) -> bool {

        if !Self::has(name) { return false; }

        match Self::provider() {
            Ok(Provider::Systemd) => Manager::try_run("systemctl", &["is-active", "--quiet", name]).is_ok(),
            Ok(Provider::Launchd) =>
                Manager::try_run_output("launchctl", &["print", &format!("system/{}", name)])
                    .ok()
                    .and_then(|output| String::from_utf8(output.stdout).ok())
                    .map(|text| text.contains("state = running") || text.contains("\"state\" = \"running\""))
                    .unwrap_or(false),
            Ok(Provider::Winsc)   =>
                Manager::try_run_output("sc", &["query", name])
                    .ok()
                    .and_then(|output| String::from_utf8(output.stdout).ok())
                    .map(|text| text.lines().any(|line| line.trim().starts_with("STATE") && line.contains("RUNNING")))
                    .unwrap_or(false),
            Err(_) => false,
        }

    }

    pub fn status ( name: &str ) -> AppResult<()> {

        Self::need(name)?;

        match Self::provider()? {
            Provider::Systemd => Manager::try_run("systemctl", &["status", name, "--no-pager"]),
            Provider::Launchd => Manager::try_run("launchctl", &["print", &format!("system/{}", name)]),
            Provider::Winsc   => Manager::try_run("sc", &["query", name]),
        }

    }

    pub fn logs ( name: &str, lines: usize ) -> AppResult<()> {

        Self::need(name)?;
        let lines = lines.max(1).to_string();

        match Self::provider()? {
            Provider::Systemd => Manager::try_run("journalctl", &["-u", name, "-n", &lines, "--no-pager"]),
            Provider::Launchd =>
                Manager::try_run("log", &[
                    "show", "--style", "compact", "--last", "1h", "--predicate",
                    &format!("process == \"{}\" OR eventMessage CONTAINS[c] \"{}\"", name, name),
                ]),
            Provider::Winsc   => Manager::try_run("wevtutil", &["qe", "System", &format!("/c:{}", lines), "/rd:true", "/f:text"]),
        }

    }


    pub fn has_all ( bins: &[&str] ) -> bool {

        bins.iter().all(|bin| Self::has(bin))

    }

    pub fn need_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::need(bin)?; }
        Ok(())

    }

    pub fn install_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::install(bin)?; }
        Ok(())

    }

    pub fn remove_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::remove(bin)?; }
        Ok(())

    }

    pub fn ensure_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::ensure(bin)?; }
        Ok(())

    }

    pub fn start_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::start(bin)?; }
        Ok(())

    }

    pub fn stop_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::stop(bin)?; }
        Ok(())

    }

    pub fn restart_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::restart(bin)?; }
        Ok(())

    }

    pub fn enable_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::enable(bin)?; }
        Ok(())

    }

    pub fn disable_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::disable(bin)?; }
        Ok(())

    }

    pub fn all_alive ( bins: &[&str] ) -> bool {

        bins.iter().all(|bin| Self::alive(bin))

    }

}
