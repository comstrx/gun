use std::{process::Command, io::IsTerminal, path::PathBuf, sync::OnceLock, time::{Instant, Duration}};
use semver::Version;
use os_info::Type;
use regex::Regex;
use which::which;

use crate::core::app::{AppResult, AppError};
use super::arch::Manager;

impl Manager {

    pub fn as_str ( &self ) -> &'static str {

        match self {
            Self::Brew   => "brew",
            Self::Apt    => "apt",
            Self::Dnf    => "dnf",
            Self::Yum    => "yum",
            Self::Pacman => "pacman",
            Self::Zypper => "zypper",
            Self::Apk    => "apk",
            Self::Winget => "winget",
            Self::Scoop  => "scoop",
            Self::Choco  => "choco",
        }

    }

    pub fn resolve ( names: &[&str] ) -> AppResult<Self> {

        for name in names {

            if which(name).is_ok() {

                return Ok(match *name {
                    "brew"    => Self::Brew,
                    "apt"     => Self::Apt,
                    "apt-get" => Self::Apt,
                    "dnf"     => Self::Dnf,
                    "yum"     => Self::Yum,
                    "pacman"  => Self::Pacman,
                    "zypper"  => Self::Zypper,
                    "apk"     => Self::Apk,
                    "winget"  => Self::Winget,
                    "scoop"   => Self::Scoop,
                    "choco"   => Self::Choco,
                    _         => unreachable!(),
                });

            }

        }

        Err(AppError::message("no supported package manager found"))

    }

    pub fn detect () -> AppResult<Self> {

        static DETECTED: OnceLock<Manager> = OnceLock::new();
        if let Some(manager) = DETECTED.get() { return Ok(*manager); }

        let manager = match os_info::get().os_type() {
            Type::Macos => Self::resolve(&["brew"])?,
            Type::Ubuntu | Type::Debian | Type::Mint | Type::Pop | Type::Kali | Type::Elementary | Type::Raspbian => Self::resolve(&["apt-get", "apt"])?,
            Type::Fedora | Type::Redhat | Type::RedHatEnterprise | Type::CentOS | Type::RockyLinux | Type::AlmaLinux | Type::Nobara | Type::Ultramarine => Self::resolve(&["dnf", "yum"])?,
            Type::Arch | Type::Artix | Type::Manjaro | Type::Garuda | Type::EndeavourOS | Type::CachyOS => Self::resolve(&["pacman"])?,
            Type::Alpine => Self::resolve(&["apk"])?,
            Type::openSUSE | Type::SUSE => Self::resolve(&["zypper"])?,
            Type::Windows => Self::resolve(&["winget", "scoop", "choco"])?,
            _ => Self::resolve(&["brew", "apt-get", "apt", "dnf", "yum", "pacman", "zypper", "apk", "winget", "scoop", "choco"])?,
        };

        let _ = DETECTED.set(manager);
        Ok(manager)

    }

    pub fn refresh () -> AppResult<()> {

        match Self::detect()? {
            Self::Apt    => Self::sudo_run("apt-get", &["update"]),
            Self::Dnf    => Self::sudo_run("dnf", &["makecache"]),
            Self::Yum    => Self::sudo_run("yum", &["makecache"]),
            Self::Pacman => Self::sudo_run("pacman", &["-Sy"]),
            Self::Zypper => Self::sudo_run("zypper", &["refresh"]),
            Self::Apk    => Self::sudo_run("apk", &["update"]),
            _            => Ok(()),
        }

    }


    pub fn os_name () -> &'static str {

        match os_info::get().os_type() {
            Type::Windows => "windows",
            Type::Macos   => "macos",
            _             => "linux",
        }

    }

    pub fn is_windows () -> bool {

        matches!(os_info::get().os_type(), Type::Windows)

    }

    pub fn is_mac () -> bool {

        matches!(os_info::get().os_type(), Type::Macos)

    }

    pub fn is_linux () -> bool {

        !matches!(os_info::get().os_type(), Type::Windows | Type::Macos)

    }

    pub fn is_unix () -> bool {

        !Self::is_windows()

    }


    pub fn run ( command: &str, args: &[&str] ) -> AppResult<()> {

        let status = Command::new(command).args(args).status()?;

        if !status.success() { return Err(AppError::command_failed(command, status)); }

        Ok(())

    }

    pub fn run_output ( command: &str, args: &[&str] ) -> AppResult<std::process::Output> {

        let output = Command::new(command).args(args).output()?;

        if !output.status.success() { return Err(AppError::command_failed(command, output.status)); }

        Ok(output)

    }

    pub fn sudo_run ( command: &str, args: &[&str] ) -> AppResult<()> {

        #[cfg(unix)]
        {

            if rustix::process::geteuid().is_root() { return Self::run(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_binary("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).status() {
                Ok(status) if status.success() => return Ok(()),
                Ok(_) | Err(_) => {}
            }

            if std::io::stdin().is_terminal() && std::io::stderr().is_terminal() {

                let mut sudo_args = Vec::with_capacity(args.len() + 1);
                sudo_args.push(command);
                sudo_args.extend_from_slice(args);

                return Self::run("sudo", &sudo_args);

            }

            Self::run(command, args)

        }

        #[cfg(not(unix))]
        {

            Self::run(command, args)

        }

    }

    pub fn sudo_run_output ( command: &str, args: &[&str] ) -> AppResult<std::process::Output> {

        #[cfg(unix)]
        {

            if rustix::process::geteuid().is_root() { return Self::run_output(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_binary("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).output() {
                Ok(output) if output.status.success() => return Ok(output),
                Ok(_) | Err(_) => {}
            }

            if std::io::stdin().is_terminal() && std::io::stderr().is_terminal() {

                let mut sudo_args = Vec::with_capacity(args.len() + 1);
                sudo_args.push(command);
                sudo_args.extend_from_slice(args);

                return Self::run_output("sudo", &sudo_args);

            }

            Self::run_output(command, args)

        }

        #[cfg(not(unix))]
        {

            Self::run_output(command, args)

        }

    }


    pub fn env_path ( key: &str ) -> Option<PathBuf> {

        std::env::var_os(key).filter(|value| !value.is_empty()).map(PathBuf::from)

    }

    pub fn path_var () -> Vec<PathBuf> {

        std::env::var_os("PATH").map(|value| std::env::split_paths(&value).collect()).unwrap_or_default()

    }

    pub fn measure <T> ( callback: impl FnOnce() -> AppResult<T> ) -> AppResult<Duration> {

        let start = Instant::now();

        callback()?;

        Ok(start.elapsed())

    }

    pub fn version ( binary: &str ) -> AppResult<String> {

        Self::need(binary)?;

        static RE: OnceLock<Regex> = OnceLock::new();
        let mut first_error = None;

        let re = RE.get_or_init(|| {
            Regex::new(r"(?i)(?:^|[^0-9])(?:[a-z]+)?(\d+)\.(\d+)(?:\.(\d+))?([0-9a-z.+-]*)")
                .expect("invalid version regex")
        });

        for args in [&["--version"][..], &["-v"][..], &["-V"][..], &["version"][..]] {

            let output = match Command::new(binary).args(args).output() {
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
        Err(AppError::message(format!("failed to detect version for {binary}")))

    }

}
