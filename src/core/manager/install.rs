use std::{process::Command, path::PathBuf, sync::OnceLock};
use semver::Version;
use regex::Regex;

use crate::core::app::{AppResult, AppError};
use crate::core::graph::{Tool, Strategy, Method};

use super::arch::Manager;

impl Manager {

    fn env_path ( key: &str ) -> Option<PathBuf> {

        std::env::var_os(key).filter(|value| !value.is_empty()).map(PathBuf::from)

    }

    fn find_paths ( bin: &str ) -> Vec<PathBuf> {

        let mut paths = Vec::new();

        if let Ok(path) = which::which(bin) { return vec![path]; }

        #[cfg(unix)]
        {
            if let Some(home) = Self::env_path("HOME") {
                paths.push(home.join(".local").join("bin").join(bin));
                paths.push(home.join(".cargo").join("bin").join(bin));
                paths.push(home.join(".local").join("share").join("mise").join("shims").join(bin));
                paths.push(home.join(".config").join("mise").join("shims").join(bin));
                paths.push(home.join(".local").join("share").join("aquaproj-aqua").join("bin").join(bin));
                paths.push(home.join(".nix-profile").join("bin").join(bin));
            }
        }

        #[cfg(windows)]
        {
            if let Some(local) = Self::env_path("LOCALAPPDATA") {
                paths.push(local.join("Microsoft").join("WinGet").join("Links").join(format!("{bin}.exe")));
                paths.push(local.join("mise").join("shims").join(format!("{bin}.exe")));
            }

            if let Some(user) = Self::env_path("USERPROFILE") {
                paths.push(user.join(".cargo").join("bin").join(format!("{bin}.exe")));
                paths.push(user.join("scoop").join("shims").join(format!("{bin}.exe")));
            }

            if let Some(program_data) = Self::env_path("ProgramData") {
                paths.push(program_data.join("chocolatey").join("bin").join(format!("{bin}.exe")));
            }
        }

        paths

    }
    
    fn find_path ( bin: &str ) -> Option<PathBuf> {

        for path in Self::find_paths(bin) {
            if path.is_file() {
                return Some(path);
            }
        }

        None

    }

    fn native_install ( info: Strategy ) -> AppResult<()> {

        match Self::detect()? {
            Self::Apt    => Self::sudo_run("apt-get", &["install", "-y", info.name]),
            Self::Dnf    => Self::sudo_run("dnf", &["install", "-y", info.name]),
            Self::Yum    => Self::sudo_run("yum", &["install", "-y", info.name]),
            Self::Apk    => Self::sudo_run("apk", &["add", info.name]),
            Self::Zypper => Self::sudo_run("zypper", &["install", "-y", info.name]),
            Self::Pacman => Self::sudo_run("pacman", &["-S", "--needed", "--noconfirm", "--noprogressbar", info.name]),
            Self::Brew   => Self::run("brew", &["install", info.name]),
            Self::Scoop  => Self::run("scoop", &["install", info.name]),
            Self::Choco  => Self::run("choco", &["install", "-y", info.name]),
            Self::Winget => Self::run("winget", &[
                "install", "-e", "--id", info.name,
                "--source", "winget", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity",
            ]),
        }

    }

    fn shell_install ( info: Strategy, bash: bool ) -> AppResult<()> {

        if info.source.is_empty() {
            return Err(AppError::invalid_argument("source", "required installer source"));
        }

        let path = std::env::temp_dir().join(format!("{}-installer", info.name));
        let path_str = path.to_string_lossy().into_owned();

        let cmd = if bash { "bash" } else { "sh" };

        let result = (|| -> AppResult<()> {

            Self::run("curl", &["-fsSL", info.source, "-o", &path_str])?;

            let mut args = Vec::with_capacity(info.args.len() + 1);
            args.push(path_str.as_str());
            args.extend_from_slice(info.args);

            Self::run(cmd, &args)

        })();

        let _ = std::fs::remove_file(path);
        result

    }

    fn mise_install ( info: Strategy ) -> AppResult<()> {

        Self::run("mise", &["use", "--global", info.source])

    }

    fn nix_install ( info: Strategy ) -> AppResult<()> {

        Self::run("nix", &["profile", "install", info.name])

    }

    fn full_remove ( bin: &str ) -> AppResult<()> {

        let mut name = bin;

        match Tool::get(bin) {
            Ok(info) => {
                name = if info.name.is_empty() { info.bin } else { info.name };
                if name.is_empty() { name = bin; }

                if !info.source.is_empty() {
                    if Self::has("mise") { let _ = Self::run("mise", &["unuse", "--global", info.source]); }
                    if Self::has("nix") { let _ = Self::run("nix", &["profile", "remove", info.source]); }
                }

                if Self::has("mise") { let _ = Self::run("mise", &["unuse", "--global", info.bin]); }
                if Self::has("nix") { let _ = Self::run("nix", &["profile", "remove", info.bin]); }
            },
            Err(_) => name = bin
        };
        match Self::detect()? {
            Self::Apt    => Self::sudo_run("apt-get", &["remove", "-y", name]),
            Self::Dnf    => Self::sudo_run("dnf", &["remove", "-y", name]),
            Self::Yum    => Self::sudo_run("yum", &["remove", "-y", name]),
            Self::Pacman => Self::sudo_run("pacman", &["-R", "--noconfirm", name]),
            Self::Zypper => Self::sudo_run("zypper", &["remove", "-y", name]),
            Self::Apk    => Self::sudo_run("apk", &["del", name]),
            Self::Brew   => Self::run("brew", &["uninstall", name]),
            Self::Scoop  => Self::run("scoop", &["uninstall", name]),
            Self::Choco  => Self::run("choco", &["uninstall", "-y", name]),
            Self::Winget => Self::run("winget", &["uninstall", "-e", "--id", name, "--source", "winget", "--disable-interactivity"]),
        };
        Self::find_paths(bin).into_iter().for_each(|path| {
            let _ = std::fs::remove_file(path);
        });

        Ok(())

    }


    pub fn install ( bin: &str ) -> AppResult<()> {

        let info = Tool::get(bin)?;

        match info.method {
            Method::Native => Self::native_install(info),
            Method::Shell  => Self::shell_install(info, false),
            Method::Bash   => Self::shell_install(info, true),
            Method::Mise   => Self::mise_install(info),
            Method::Nix    => Self::nix_install(info),
        }

    }

    pub fn ensure ( bin: &str ) -> AppResult<()> {

        if !Self::has(bin) { Self::install(bin)?; }

        match Self::version(bin) {
            Ok(_) => Ok(()),
            Err(_) => {
                let info = Tool::get(bin)?;

                if info.path.is_empty() {
                    let _ = Self::version(info.bin)?;
                    return Ok(());
                }

                match Self::version(info.path) {
                    Ok(_) => Ok(()),
                    Err(_) => {
                        let _ = Self::version(info.bin)?;
                        Ok(())
                    }
                }
            }
        }

    }

    pub fn remove ( bin: &str ) -> AppResult<()> {

        Self::full_remove(bin)

    }

    pub fn upgrade ( bin: &str ) -> AppResult<()> {

        Self::full_remove(bin)?;
        Self::install(bin)

    }

    pub fn has ( bin: &str ) -> bool {

        if Self::find_path(bin).is_some() { return true; }

        match Tool::get(bin) {
            Ok(info) => {
                if !info.path.is_empty() && PathBuf::from(info.path).is_file() { return true; }
                Self::find_path(info.bin).is_some()
            }
            Err(_) => false,
        }

    }

    pub fn need ( bin: &str ) -> AppResult<()> {

        if Self::has(bin) { return Ok(()); }
        Err(AppError::missing_binary(bin))

    }

    pub fn version ( bin: &str ) -> AppResult<String> {

        Self::need(bin)?;

        static RE: OnceLock<Regex> = OnceLock::new();
        let mut first_error = None;

        let re = RE.get_or_init(|| {
            Regex::new(r"(?i)(?:^|[^0-9])(?:[a-z]+)?(\d+)\.(\d+)(?:\.(\d+))?([0-9a-z.+-]*)")
                .expect("invalid version regex")
        });

        for args in [&["--version"][..], &["-v"][..], &["-V"][..], &["version"][..]] {

            let output = match Command::new(bin).args(args).output() {
                Ok(output) => output,
                Err(err) => {
                    if first_error.is_none() { first_error = Some(err); }
                    continue;
                }
            };

            for text in [&output.stdout[..], &output.stderr[..]] {

                let text = String::from_utf8_lossy(text);

                if let Some(caps) = re.captures(&text) {

                    let major = &caps[1];
                    let minor = &caps[2];
                    let patch = caps.get(3).map_or("0", |m| m.as_str());
                    let tail  = caps.get(4).map_or("", |m| m.as_str()).trim_start_matches(['.', '-', '+']);

                    let pre = if tail.is_empty() { String::new() } else {
                        let tail = tail
                            .split(['.', '-', '+'])
                            .filter(|part| !part.is_empty())
                            .collect::<Vec<_>>()
                            .join(".");

                        if tail.is_empty() { String::new() }
                        else { format!("-{tail}") }
                    };

                    let version = format!("{major}.{minor}.{patch}{pre}");
                    if Version::parse(&version).is_ok() { return Ok(version); }

                }

            }

        }

        if let Some(err) = first_error { return Err(err.into()); }
        Err(AppError::message(format!("failed to detect version for {bin}")))

    }


    pub fn install_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::install(bin)?; }

        Ok(())

    }

    pub fn ensure_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::ensure(bin)?; }

        Ok(())

    }

    pub fn remove_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::remove(bin)?; }

        Ok(())

    }

    pub fn upgrade_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::upgrade(bin)?; }

        Ok(())

    }

    pub fn has_all ( bins: &[&str] ) -> bool {

        bins.iter().all(|bin| Self::has(bin))

    }

    pub fn need_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::need(bin)?; }

        Ok(())

    }

}
