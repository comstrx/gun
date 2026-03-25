use std::{fs, env};
use which::which;

use super::arch::{Manager, AppResult, AppError};

impl Manager {

    pub fn native_install ( id: &str ) -> AppResult<()> {

        match Self::detect()? {
            Self::Apt    => Self::try_run("apt-get", &["install", "-y", id]),
            Self::Apk    => Self::try_run("apk", &["add", id]),
            Self::Dnf    => Self::try_run("dnf", &["install", "-y", id]),
            Self::Yum    => Self::try_run("yum", &["install", "-y", id]),
            Self::Zypper => Self::try_run("zypper", &["install", "-y", id]),
            Self::Pacman => Self::try_run("pacman", &["-S", "--needed", "--noconfirm", "--noprogressbar", id]),
            Self::Brew   => Self::run("brew", &["install", id]),
            Self::Scoop  => Self::run("scoop", &["install", id]),
            Self::Choco  => Self::run("choco", &["install", "-y", id]),
            Self::Winget => Self::run("winget", &[
                "install", "-e", "--id", id,
                "--source", "winget", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity",
            ]),
        }

    }

    pub fn native_remove ( id: &str ) -> AppResult<()> {

        match Self::detect()? {
            Self::Apt    => Self::try_run("apt-get", &["remove", "-y", id]),
            Self::Dnf    => Self::try_run("dnf", &["remove", "-y", id]),
            Self::Yum    => Self::try_run("yum", &["remove", "-y", id]),
            Self::Pacman => Self::try_run("pacman", &["-R", "--noconfirm", id]),
            Self::Zypper => Self::try_run("zypper", &["remove", "-y", id]),
            Self::Apk    => Self::try_run("apk", &["del", id]),
            Self::Brew   => Self::run("brew", &["uninstall", id]),
            Self::Scoop  => Self::run("scoop", &["uninstall", id]),
            Self::Choco  => Self::run("choco", &["uninstall", "-y", id]),
            Self::Winget => Self::run("winget", &["uninstall", "-e", "--id", id, "--source", "winget", "--disable-interactivity"]),
        }

    }


    pub fn nix_install ( id: &str ) -> AppResult<()> {

        Self::run("nix", &["profile", "install", id])

    }

    pub fn nix_remove ( id: &str ) -> AppResult<()> {

        Self::run("nix", &["profile", "remove", id])

    }


    pub fn mise_install ( id: &str ) -> AppResult<()> {

        Self::run("mise", &["use", "--global", id])

    }

    pub fn mise_remove ( id: &str ) -> AppResult<()> {

        Self::run("mise", &["unuse", "--global", id])

    }


    pub fn script_install ( id: &str, url: &str, args: &[&str], bash: bool ) -> AppResult<()> {

        if url.is_empty() {  return Err(AppError::invalid_argument("url", "required installer url")); }

        if which("curl").is_err() { return Err(AppError::missing_binary("curl")); }
        if bash && which("bash").is_err() { return Err(AppError::missing_binary("bash")); }

        let path = env::temp_dir().join(format!("{}-installer", id));
        let path_str = path.to_string_lossy().into_owned();

        let result = (|| -> AppResult<()> {

            Self::run("curl", &["-fsSL", url, "-o", &path_str])?;

            let mut cmd_args = Vec::with_capacity(args.len() + 1);
            cmd_args.push(path_str.as_str());
            cmd_args.extend_from_slice(args);

            let cmd = if bash { "bash" } else { "sh" };
            Self::run(cmd, &cmd_args)

        })();

        let _ = fs::remove_file(path);
        result

    }

}
