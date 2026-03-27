use std::{fs, env, process, path::PathBuf, time::{SystemTime, UNIX_EPOCH}};
use super::arch::{Manager, AppResult};

impl Manager {

    pub fn native_install ( id: &str, version: &str ) -> AppResult<()> {

        if version.is_empty() {

            return match Self::detect()? {
                Self::Apt    => Self::try_run("apt-get", &["install", "-y", id]),
                Self::Apk    => Self::try_run("apk", &["add", id]),
                Self::Dnf    => Self::try_run("dnf", &["install", "-y", id]),
                Self::Yum    => Self::try_run("yum", &["install", "-y", id]),
                Self::Nix    => Self::try_run("nix", &["profile", "install", &format!("nixpkgs#{id}")]),
                Self::Zypper => Self::try_run("zypper", &["--non-interactive", "install", id]),
                Self::Pacman => Self::try_run("pacman", &["-S", "--needed", "--noconfirm", "--noprogressbar", id]),
                Self::Brew   => Self::run("brew", &["install", id]),
                Self::Scoop  => Self::run("scoop", &["install", id]),
                Self::Choco  => Self::run("choco", &["install", "-y", id]),
                Self::Winget => Self::run("winget", &[
                    "install", "-e", "--id", id,
                    "--source", "winget",
                    "--accept-package-agreements",
                    "--accept-source-agreements",
                    "--disable-interactivity",
                ]),
            };

        }

        match Self::detect()? {
            Self::Apt    => Self::try_run("apt-get", &["install", "-y", &format!("{id}={version}")]),
            Self::Apk    => Self::try_run("apk", &["add", &format!("{id}={version}")]),
            Self::Dnf    => Self::try_run("dnf", &["install", "-y", &format!("{id}-{version}")]),
            Self::Yum    => Self::try_run("yum", &["install", "-y", &format!("{id}-{version}")]),
            Self::Nix    => Self::try_run("nix", &["profile", "install", &format!("nixpkgs/{version}#{id}")]),
            Self::Zypper => Self::try_run("zypper", &["--non-interactive", "install", &format!("{id}={version}")]),
            Self::Pacman => Self::try_run("pacman", &["-U", "--noconfirm", version]),
            Self::Brew   => Self::run("brew", &["install", &format!("{id}@{version}")]),
            Self::Scoop  => Self::run("scoop", &["install", &format!("{id}@{version}")]),
            Self::Choco  => Self::run("choco", &["install", "-y", id, &format!("--version={version}")]),
            Self::Winget => Self::run("winget", &[
                "install", "-e", "--id", id,
                "--version", version,
                "--source", "winget",
                "--accept-package-agreements",
                "--accept-source-agreements",
                "--disable-interactivity",
            ]),
        }

    }

    pub fn native_remove ( id: &str ) -> AppResult<()> {

        match Self::detect()? {
            Self::Apt    => Self::try_run("apt-get", &["remove", "-y", id]),
            Self::Dnf    => Self::try_run("dnf", &["remove", "-y", id]),
            Self::Yum    => Self::try_run("yum", &["remove", "-y", id]),
            Self::Nix    => Self::try_run("nix", &["profile", "remove", id]),
            Self::Pacman => Self::try_run("pacman", &["-R", "--noconfirm", id]),
            Self::Zypper => Self::try_run("zypper", &["--non-interactive", "remove", id]),
            Self::Apk    => Self::try_run("apk", &["del", id]),
            Self::Brew   => Self::run("brew", &["uninstall", id]),
            Self::Scoop  => Self::run("scoop", &["uninstall", id]),
            Self::Choco  => Self::run("choco", &["uninstall", "-y", id]),
            Self::Winget => Self::run("winget", &["uninstall", "-e", "--id", id, "--source", "winget", "--disable-interactivity"]),
        }

    }


    pub fn nix_install ( id: &str, version: &str ) -> AppResult<()> {

        if version.is_empty() { Self::run("nix", &["profile", "install", &format!("nixpkgs#{id}")]) }
        else { Self::run("nix", &["profile", "install", &format!("nixpkgs/{version}#{id}")]) }

    }

    pub fn nix_remove ( id: &str ) -> AppResult<()> {

        Self::run("nix", &["profile", "remove", id])

    }


    pub fn snap_install ( id: &str, version: &str ) -> AppResult<()> {

        if version.is_empty() { Self::try_run("snap", &["install", id]) }
        else { Self::try_run("snap", &["install", id, &format!("--channel={version}")]) }

    }

    pub fn snap_remove ( id: &str ) -> AppResult<()> {

        Self::try_run("snap", &["remove", id])

    }


    pub fn mise_install ( id: &str, version: &str ) -> AppResult<()> {

        if version.is_empty() || id.contains("@") { Self::run("mise", &["use", "--global", id]) }
        else { Self::run("mise", &["use", "--global", &format!("{id}@{version}")]) }

    }

    pub fn mise_remove ( id: &str ) -> AppResult<()> {

        let _ = Self::run("mise", &["unuse", "--global", id]);
        Self::run("mise", &["uninstall", "--all", id])

    }


    pub fn build_path ( id: &str ) -> PathBuf {

        let pid = process::id();
        let time = SystemTime::now().duration_since(UNIX_EPOCH).map(|v| v.as_micros()).unwrap_or(0);

        let name = id.trim().chars()
            .map(|c| if c.is_ascii_alphanumeric() || c == '-' || c == '_' { c } else { '-' })
            .collect::<String>();

        env::temp_dir().join(format!("{}-installer-{}-{}", name, pid, time))

    }

    pub fn script_install ( id: &str, source: &str, version: &str, args: &[&str], bash: bool ) -> AppResult<()> {

        let mut argsv: Vec<&str> = Vec::with_capacity(args.len() + 1);

        let path = Self::build_path(id);
        let dest  = path.to_string_lossy().into_owned();
        let url   = source.replace("{version}", version).replace("{v}", version);

        let result = (|| -> AppResult<()> {

            Self::run("curl", &["-fsSL", &url, "-o", &dest])?;

            argsv.push(dest.as_str());
            argsv.extend_from_slice(args);

            Self::run(if bash { "bash" } else { "sh" }, &argsv)

        })();

        let _ = fs::remove_file(path);
        result

    }

}
