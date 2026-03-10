use crate::core::app::{AppResult, AppError};
use super::arch::{Manager, Tool, Method};

impl Manager {

    pub fn native_install ( id: &str ) -> AppResult<()> {

        match Self::detect()? {
            Self::Apt    => Self::sudo_run("apt-get", &["install", "-y", id]),
            Self::Dnf    => Self::sudo_run("dnf", &["install", "-y", id]),
            Self::Yum    => Self::sudo_run("yum", &["install", "-y", id]),
            Self::Apk    => Self::sudo_run("apk", &["add", id]),
            Self::Zypper => Self::sudo_run("zypper", &["install", "-y", id]),
            Self::Pacman => Self::sudo_run("pacman", &["-S", "--needed", "--noconfirm", "--noprogressbar", id]),
            Self::Brew   => Self::run("brew", &["install", id]),
            Self::Scoop  => Self::run("scoop", &["install", id]),
            Self::Choco  => Self::run("choco", &["install", "-y", id]),
            Self::Winget => Self::run("winget", &[
                "install", "-e", "--id", id,
                "--source", "winget", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity",
            ]),
        }

    }

    pub fn shell_install ( id: &str, url: &str, args: &[&str], bash: bool ) -> AppResult<()> {

        if url.is_empty() {  return Err(AppError::invalid_argument("url", "required installer url")); }

        let path = std::env::temp_dir().join(format!("{}-installer", id));
        let path_str = path.to_string_lossy().into_owned();

        let result = (|| -> AppResult<()> {

            Self::run("curl", &["-fsSL", url, "-o", &path_str])?;

            let mut arg = Vec::with_capacity(args.len() + 1);
            arg.push(path_str.as_str());
            arg.extend_from_slice(args);

            let cmd = if bash { "bash" } else { "sh" };
            Self::run(cmd, &arg)

        })();

        let _ = std::fs::remove_file(path);
        result

    }

    pub fn mise_install ( url: &str ) -> AppResult<()> {

        Self::run("mise", &["use", "--global", url])

    }

    pub fn nix_install ( id: &str ) -> AppResult<()> {

        Self::run("nix", &["profile", "install", id])

    }

    pub fn force_remove ( bin: &str ) -> AppResult<()> {

        let id = match Tool::spec(bin) {
            Ok(info) => {
                if !info.source.is_empty() {
                    if Self::has("mise") { let _ = Self::run("mise", &["unuse", "--global", info.source]); }
                    if Self::has("nix") { let _ = Self::run("nix", &["profile", "remove", info.source]); }
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

        if let Ok(path) = Self::path(bin) { let _ = std::fs::remove_file(path); }
        Ok(())

    }


    pub fn install ( bin: &str ) -> AppResult<()> {

        if Tool::get(bin).is_err() { return Self::native_install(bin); }

        let spec = Tool::spec(bin)?;

        match spec.method {
            Method::Native => Self::native_install(spec.id),
            Method::Shell  => Self::shell_install(spec.id, spec.source, spec.args, false),
            Method::Bash   => Self::shell_install(spec.id, spec.source, spec.args, true),
            Method::Mise   => Self::mise_install(spec.source),
            Method::Nix    => Self::nix_install(spec.id),
        }

    }

    pub fn remove ( bin: &str ) -> AppResult<()> {

        Self::force_remove(bin)

    }

    pub fn ensure ( bin: &str ) -> AppResult<()> {

        if !Self::has(bin) { Self::install(bin)?; }

        match Tool::version(bin) {
            Ok(_) => Ok(()),
            Err(_) => {
                let spec = Tool::spec(bin)?;

                if spec.path.is_empty() {
                    let _ = Tool::version(spec.bin)?;
                    return Ok(());
                }

                match Tool::version(spec.path) {
                    Ok(_) => Ok(()),
                    Err(_) => {
                        let _ = Tool::version(spec.bin)?;
                        Ok(())
                    }
                }
            }
        }

    }

}
