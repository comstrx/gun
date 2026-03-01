use std::process::Command;
use os_info::Type;
use which::which;

use super::error::{ManagerError, ManagerResult};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Manager {
    Brew,
    Apt,
    Dnf,
    Yum,
    Pacman,
    Zypper,
    Apk,
    Winget,
    Scoop,
    Choco,
}

impl Manager {

    pub fn run ( command: &str, args: &[&str] ) -> ManagerResult<()> {

        let status = Command::new(command).args(args).status()?;

        if !status.success() {

            return Err(ManagerError::command_failed(command, status));

        }

        Ok(())

    }

    pub fn sudo_run ( command: &str, args: &[&str] ) -> ManagerResult<()> {

        #[cfg(unix)]
        {

            if rustix::process::geteuid().is_root() {

                return Self::run(command, args);

            }

            if which("sudo").is_err() {

                return Err(ManagerError::missing_binary("sudo"));

            }

            let mut sudo_args = Vec::with_capacity(args.len() + 1);
            sudo_args.push(command);
            sudo_args.extend_from_slice(args);

            Self::run("sudo", &sudo_args)

        }

        #[cfg(not(unix))]
        {

            Self::run(command, args)

        }

    }

    pub fn from ( names: &[&str] ) -> ManagerResult<Self> {

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

        Err(ManagerError::message("no supported package manager found"))

    }

    pub fn refresh ( manager: Manager ) -> ManagerResult<()> {

        match manager {
            Self::Apt    => Self::sudo_run("apt-get", &["update"]),
            Self::Dnf    => Self::sudo_run("dnf", &["makecache"]),
            Self::Yum    => Self::sudo_run("yum", &["makecache"]),
            Self::Zypper => Self::sudo_run("zypper", &["refresh"]),
            Self::Apk    => Self::sudo_run("apk", &["update"]),
            _            => Ok(()),
        }

    }

    pub fn detect () -> ManagerResult<Self> {

        let manager = match os_info::get().os_type() {
            Type::Macos => Self::from(&["brew"]),
            Type::Ubuntu | Type::Debian | Type::Mint | Type::Pop | Type::Kali | Type::Elementary | Type::Raspbian => Self::from(&["apt-get", "apt"]),
            Type::Fedora | Type::Redhat | Type::RedHatEnterprise | Type::CentOS | Type::RockyLinux | Type::AlmaLinux | Type::Nobara | Type::Ultramarine => Self::from(&["dnf", "yum"]),
            Type::Arch | Type::Artix | Type::Manjaro | Type::Garuda | Type::EndeavourOS | Type::CachyOS => Self::from(&["pacman"]),
            Type::Alpine => Self::from(&["apk"]),
            Type::openSUSE | Type::SUSE => Self::from(&["zypper"]),
            Type::Windows => Self::from(&["winget", "scoop", "choco"]),
            _ => Self::from(&["brew", "apt-get", "apt", "dnf", "yum", "pacman", "zypper", "apk", "winget", "scoop", "choco"]),
        }?;

        Self::refresh(manager.clone())?;
        Ok(manager)

    }

}
