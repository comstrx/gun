use std::{process::Command, io::IsTerminal, sync::OnceLock};
use os_info::Type;
use which::which;

use crate::core::app::{AppError, AppResult};
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

    pub fn run ( command: &str, args: &[&str] ) -> AppResult<()> {

        let status = Command::new(command).args(args).status()?;

        if !status.success() { return Err(AppError::command_failed(command, status)); }

        Ok(())

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

    pub fn run_output ( command: &str, args: &[&str] ) -> AppResult<std::process::Output> {

        let output = Command::new(command).args(args).output()?;

        if !output.status.success() {
            let stdout = (!output.stdout.is_empty()).then(|| String::from_utf8_lossy(&output.stdout).into_owned());
            let stderr = (!output.stderr.is_empty()).then(|| String::from_utf8_lossy(&output.stderr).into_owned());

            return Err(AppError::command_failed_output(command, output.status, stdout, stderr));
        }

        Ok(output)

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

}
