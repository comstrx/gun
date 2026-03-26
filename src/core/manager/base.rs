use std::{io, io::IsTerminal, sync::OnceLock, process::{Command, Output}};
use {os_info::Type, which::which, rustix::process::geteuid};

use super::arch::{Manager, AppResult, AppError};

impl Manager {

    pub fn as_str ( &self ) -> &'static str {

        match self {
            Self::Apt => "apt",
            Self::Apk => "apk",
            Self::Dnf => "dnf",
            Self::Yum => "yum",
            Self::Pacman => "pacman",
            Self::Zypper => "zypper",
            Self::Brew => "brew",
            Self::Winget => "winget",
            Self::Scoop => "scoop",
            Self::Choco => "choco",
        }

    }

    pub fn resolve ( names: &[&str] ) -> AppResult<Self> {

        for name in names {

            if which(name).is_ok() {

                return Ok(match *name {
                    "apt" | "apt-get" => Self::Apt,
                    "apk"             => Self::Apk,
                    "dnf"             => Self::Dnf,
                    "yum"             => Self::Yum,
                    "pacman"          => Self::Pacman,
                    "zypper"          => Self::Zypper,
                    "brew"            => Self::Brew,
                    "winget"          => Self::Winget,
                    "scoop"           => Self::Scoop,
                    "choco"           => Self::Choco,
                    _                 => continue,
                });

            }

        }

        Err(AppError::cannot_detect("manager"))

    }

    pub fn detect () -> AppResult<Self> {

        static DETECTED: OnceLock<Manager> = OnceLock::new();

        if let Some(manager) = DETECTED.get() { return Ok(*manager); }

        let manager = match os_info::get().os_type() {
            Type::Ubuntu
            | Type::Debian
            | Type::Mint
            | Type::Pop
            | Type::Kali
            | Type::Elementary
            | Type::Raspbian => Self::resolve(&["apt-get", "apt"])?,

            Type::Fedora
            | Type::Redhat
            | Type::RedHatEnterprise
            | Type::CentOS
            | Type::RockyLinux
            | Type::AlmaLinux
            | Type::Nobara
            | Type::Ultramarine => Self::resolve(&["dnf", "yum"])?,

            Type::Arch
            | Type::Artix
            | Type::Manjaro
            | Type::Garuda
            | Type::EndeavourOS
            | Type::CachyOS => Self::resolve(&["pacman"])?,

            Type::Alpine => Self::resolve(&["apk"])?,
            Type::openSUSE | Type::SUSE => Self::resolve(&["zypper"])?,

            Type::Macos => Self::resolve(&["brew"])?,
            Type::Windows => Self::resolve(&["winget", "scoop", "choco"])?,

            _ => Self::resolve(&["apt", "apt-get", "apk", "dnf", "yum", "pacman", "zypper", "brew", "winget", "scoop", "choco"])?,
        };

        let _ = DETECTED.set(manager);
        Ok(manager)

    }


    pub fn run ( command: &str, args: &[&str] ) -> AppResult<()> {

        let status = Command::new(command).args(args).status()?;

        if !status.success() { return Err(AppError::command_failed(command, status)); }

        Ok(())

    }

    pub fn run_output ( command: &str, args: &[&str] ) -> AppResult<Output> {

        let output = Command::new(command).args(args).output()?;

        if !output.status.success() {

            let stdout = (!output.stdout.is_empty()).then(|| String::from_utf8_lossy(&output.stdout).into_owned());
            let stderr = (!output.stderr.is_empty()).then(|| String::from_utf8_lossy(&output.stderr).into_owned());

            return Err(AppError::command_failed_output(command, output.status, stdout, stderr));

        }

        Ok(output)

    }

    pub fn run_capture ( command: &str, args: &[&str] ) -> AppResult<Output> {

        Ok(Command::new(command).args(args).output()?)

    }


    pub fn try_run ( command: &str, args: &[&str] ) -> AppResult<()> {

        #[cfg(unix)]
        {

            if geteuid().is_root() { return Self::run(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_tool("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).status() {
                Ok(status) if status.success() => return Ok(()),
                Ok(_) | Err(_) => {}
            }

            if io::stdin().is_terminal() && io::stderr().is_terminal() {

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

    pub fn try_run_output ( command: &str, args: &[&str] ) -> AppResult<Output> {

        #[cfg(unix)]
        {

            if geteuid().is_root() { return Self::run_output(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_tool("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).output() {
                Ok(output) if output.status.success() => return Ok(output),
                Ok(_) | Err(_) => {}
            }

            if io::stdin().is_terminal() && io::stderr().is_terminal() {

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

    pub fn try_run_capture ( command: &str, args: &[&str] ) -> AppResult<Output> {

        #[cfg(unix)]
        {

            if geteuid().is_root() { return Self::run_capture(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_tool("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).output() {
                Ok(output) if output.status.success() => return Ok(output),
                Ok(_) | Err(_) => {}
            }

            if io::stdin().is_terminal() && io::stderr().is_terminal() {

                let mut sudo_args = Vec::with_capacity(args.len() + 1);
                sudo_args.push(command);
                sudo_args.extend_from_slice(args);

                return Self::run_capture("sudo", &sudo_args);

            }

            Self::run_capture(command, args)

        }

        #[cfg(not(unix))]
        {

            Self::run_capture(command, args)

        }

    }

}
