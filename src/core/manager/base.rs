use std::process::Command;
use std::sync::OnceLock;
use std::time::{Instant, Duration};
use semver::Version;
use regex::Regex;
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

        match os_info::get().os_type() {
            Type::Macos => Self::resolve(&["brew"]),
            Type::Ubuntu | Type::Debian | Type::Mint | Type::Pop | Type::Kali | Type::Elementary | Type::Raspbian => Self::resolve(&["apt-get", "apt"]),
            Type::Fedora | Type::Redhat | Type::RedHatEnterprise | Type::CentOS | Type::RockyLinux | Type::AlmaLinux | Type::Nobara | Type::Ultramarine => Self::resolve(&["dnf", "yum"]),
            Type::Arch | Type::Artix | Type::Manjaro | Type::Garuda | Type::EndeavourOS | Type::CachyOS => Self::resolve(&["pacman"]),
            Type::Alpine => Self::resolve(&["apk"]),
            Type::openSUSE | Type::SUSE => Self::resolve(&["zypper"]),
            Type::Windows => Self::resolve(&["winget", "scoop", "choco"]),
            _ => Self::resolve(&["brew", "apt-get", "apt", "dnf", "yum", "pacman", "zypper", "apk", "winget", "scoop", "choco"]),
        }

    }

    pub fn refresh () -> AppResult<()> {

        match Self::detect()? {
            Self::Apt    => Self::sudo_run("apt-get", &["update"]),
            Self::Dnf    => Self::sudo_run("dnf", &["makecache"]),
            Self::Yum    => Self::sudo_run("yum", &["makecache"]),
            Self::Zypper => Self::sudo_run("zypper", &["refresh"]),
            Self::Apk    => Self::sudo_run("apk", &["update"]),
            _            => Ok(()),
        }

    }

    pub fn has ( binary: &str ) -> bool {

        which(binary).is_ok()

    }

    pub fn need ( binary: &str ) -> AppResult<()> {

        if which(binary).is_err() { return Err(AppError::missing_binary(binary)); }
        Ok(())

    }

    pub fn run ( command: &str, args: &[&str] ) -> AppResult<()> {

        let output = Command::new(command).args(args).output()?;

        if !output.status.success() {
            return Err(AppError::command_failed(command, output.status));
        }

        Ok(())

    }

    pub fn run_live ( command: &str, args: &[&str] ) -> AppResult<()> {

        let status = Command::new(command).args(args).status()?;

        if !status.success() { return Err(AppError::command_failed(command, status)); }

        Ok(())

    }

    pub fn run_output ( command: &str, args: &[&str] ) -> AppResult<std::process::Output> {

        let output = Command::new(command).args(args).output()?;

        if !output.status.success() {
            return Err(AppError::command_failed(command, output.status));
        }

        Ok(output)

    }

    pub fn sudo_run ( command: &str, args: &[&str] ) -> AppResult<()> {

        #[cfg(unix)]
        {

            if rustix::process::geteuid().is_root() {

                return Self::run(command, args);

            }

            if which("sudo").is_err() {

                return Err(AppError::missing_binary("sudo"));

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

                    let pre = if tail.is_empty() {
                        String::new()
                    } else {
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
        Err(AppError::message(format!("failed to detect semver for {binary}")))

    }

}
