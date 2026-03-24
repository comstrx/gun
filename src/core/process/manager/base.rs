use std::sync::OnceLock;
use {os_info::Type, which::which};

use super::arch::{Manager, AppError, AppResult};

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

        Err(AppError::message("no supported package manager found"))

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

}
