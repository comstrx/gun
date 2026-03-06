use std::sync::OnceLock;
use os_info::Type;
use which::which;

use crate::core::error::{AppResult, AppError};

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

}
