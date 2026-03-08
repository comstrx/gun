use crate::core::app::{AppResult, AppError};
use crate::core::tool::{Tool, Spec, Source};

use super::arch::Manager;

impl Manager {

    fn native_install ( info: Spec ) -> AppResult<()> {

        match Self::detect()? {
            Self::Apt    => Self::sudo_run("apt-get", &["install", "-y", info.id]),
            Self::Dnf    => Self::sudo_run("dnf", &["install", "-y", info.id]),
            Self::Yum    => Self::sudo_run("yum", &["install", "-y", info.id]),
            Self::Apk    => Self::sudo_run("apk", &["add", info.id]),
            Self::Zypper => Self::sudo_run("zypper", &["install", "-y", info.id]),
            Self::Pacman => Self::sudo_run("pacman", &["-S", "--needed", "--noconfirm", "--noprogressbar", info.id]),
            Self::Brew   => Self::run("brew", &["install", info.id]),
            Self::Scoop  => Self::run("scoop", &["install", info.id]),
            Self::Choco  => Self::run("choco", &["install", "-y", info.id]),
            Self::Winget => Self::run("winget", &[
                "install", "-e", "--id", info.id,
                "--source", "winget", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity",
            ]),
        }

    }

    fn shell_install ( info: Spec, bash: bool ) -> AppResult<()> {

        if info.url.is_empty() {
            return Err(AppError::invalid_argument("url", "required installer url"));
        }

        let path = std::env::temp_dir().join(format!("{}-installer", info.id));
        let path_str = path.to_string_lossy().into_owned();

        let cmd = if bash { "bash" } else { "sh" };

        let result = (|| -> AppResult<()> {

            Self::run("curl", &["-fsSL", info.url, "-o", &path_str])?;

            let mut args = Vec::with_capacity(info.args.len() + 1);
            args.push(path_str.as_str());
            args.extend_from_slice(info.args);

            Self::run(cmd, &args)

        })();

        let _ = std::fs::remove_file(path);
        result

    }

    fn mise_install ( info: Spec ) -> AppResult<()> {

        Self::run("mise", &["use", "--global", info.url])

    }

    fn nix_install ( info: Spec ) -> AppResult<()> {

        Self::run("nix", &["profile", "install", info.id])

    }

    fn full_remove ( bin: &str ) -> AppResult<()> {

        let id = match Tool::get(bin) {
            Ok(info) => {
                if !info.url.is_empty() {
                    if Self::has("mise") { let _ = Self::run("mise", &["unuse", "--global", info.url]); }
                    if Self::has("nix") { let _ = Self::run("nix", &["profile", "remove", info.url]); }
                }

                let id = if info.id.is_empty() { info.bin } else { info.id };
                if id.is_empty() { bin } else { id }
            }
            Err(_) => bin,
        };

        if Self::has("mise") { let _ = Self::run("mise", &["unuse", "--global", id]); }
        if Self::has("nix") { let _ = Self::run("nix", &["profile", "remove", id]); }

        match Self::detect()? {
            Self::Apt    => { let _ = Self::sudo_run("apt-get", &["remove", "-y", id]); },
            Self::Dnf    => { let _ = Self::sudo_run("dnf", &["remove", "-y", id]); },
            Self::Yum    => { let _ = Self::sudo_run("yum", &["remove", "-y", id]); },
            Self::Pacman => { let _ = Self::sudo_run("pacman", &["-R", "--noconfirm", id]); },
            Self::Zypper => { let _ = Self::sudo_run("zypper", &["remove", "-y", id]); },
            Self::Apk    => { let _ = Self::sudo_run("apk", &["del", id]); },
            Self::Brew   => { let _ = Self::run("brew", &["uninstall", id]); },
            Self::Scoop  => { let _ = Self::run("scoop", &["uninstall", id]); },
            Self::Choco  => { let _ = Self::run("choco", &["uninstall", "-y", id]); },
            Self::Winget => { let _ = Self::run("winget", &["uninstall", "-e", "--id", id, "--source", "winget", "--disable-interactivity"]); },
        };

        Self::clean(bin)

    }


    pub fn install ( bin: &str ) -> AppResult<()> {

        let info = Tool::get(bin)?;

        match info.source {
            Source::Native => Self::native_install(info),
            Source::Shell  => Self::shell_install(info, false),
            Source::Bash   => Self::shell_install(info, true),
            Source::Mise   => Self::mise_install(info),
            Source::Nix    => Self::nix_install(info),
        }

    }

    pub fn remove ( bin: &str ) -> AppResult<()> {

        Self::full_remove(bin)

    }

    pub fn upgrade ( bin: &str ) -> AppResult<()> {

        Self::full_remove(bin)?;
        Self::install(bin)

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


    pub fn install_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::install(bin)?; }

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

    pub fn ensure_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::ensure(bin)?; }

        Ok(())

    }

}
