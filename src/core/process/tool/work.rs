use std::{path::PathBuf, sync::OnceLock};
use {semver::Version, regex::Regex};

use super::arch::{Tool, Spec, Info, Method, Manager, AppError, AppResult};
use super::map::TOOLS;

impl Tool {

    pub fn env_path ( key: &str ) -> Option<PathBuf> {

        std::env::var_os(key).filter(|value| !value.is_empty()).map(PathBuf::from)

    }

    pub fn find_paths ( bin: &str ) -> Vec<PathBuf> {

        let mut paths = Vec::new();

        if bin.trim().is_empty() { return paths; }
        if let Ok(path) = which::which(bin) { paths.push(path); }

        #[cfg(unix)]
        {
            paths.push(PathBuf::from("/usr/local/bin").join(bin));
            paths.push(PathBuf::from("/usr/bin").join(bin));
            paths.push(PathBuf::from("/bin").join(bin));

            #[cfg(target_os = "macos")]
            {
                paths.push(PathBuf::from("/opt/homebrew/bin").join(bin));
                paths.push(PathBuf::from("/usr/local/opt").join(bin).join("bin").join(bin));
            }

            if let Some(home) = Self::env_path("HOME") {
                paths.push(home.join(".local").join("bin").join(bin));
                paths.push(home.join(".cargo").join("bin").join(bin));
                paths.push(home.join(".local").join("share").join("mise").join("shims").join(bin));
                paths.push(home.join(".config").join("mise").join("shims").join(bin));
                paths.push(home.join(".local").join("share").join("aquaproj-aqua").join("bin").join(bin));
                paths.push(home.join(".nix-profile").join("bin").join(bin));
                paths.push(home.join(".linuxbrew").join("bin").join(bin));
            }
        }

        #[cfg(windows)]
        {
            let exe = format!("{bin}.exe");
            let cmd = format!("{bin}.cmd");
            let bat = format!("{bin}.bat");

            if let Some(local) = Self::env_path("LOCALAPPDATA") {
                paths.push(local.join("Microsoft").join("WinGet").join("Links").join(&exe));
                paths.push(local.join("mise").join("shims").join(&exe));
                paths.push(local.join("Programs").join(bin).join(&exe));
            }

            if let Some(user) = Self::env_path("USERPROFILE") {
                paths.push(user.join(".cargo").join("bin").join(&exe));
                paths.push(user.join("scoop").join("shims").join(&exe));
                paths.push(user.join("scoop").join("shims").join(&cmd));
                paths.push(user.join("scoop").join("shims").join(&bat));
                paths.push(user.join(".local").join("bin").join(&exe));
            }

            if let Some(program_data) = Self::env_path("ProgramData") {
                paths.push(program_data.join("chocolatey").join("bin").join(&exe));
                paths.push(program_data.join("chocolatey").join("bin").join(&cmd));
                paths.push(program_data.join("chocolatey").join("bin").join(&bat));
            }

            if let Some(program_files) = Self::env_path("ProgramFiles") {
                paths.push(program_files.join(bin).join(&exe));
            }

            if let Some(program_files_x86) = Self::env_path("ProgramFiles(x86)") {
                paths.push(program_files_x86.join(bin).join(&exe));
            }
        }

        let mut seen = std::collections::HashSet::new();
        paths.into_iter().filter(|path| seen.insert(path.clone())).collect()

    }

    pub fn find_path ( bin: &str ) -> Option<PathBuf> {

        for path in Self::find_paths(bin) {
            if path.is_file() {
                return Some(path);
            }
        }

        None

    }

    pub fn path ( bin: &str ) -> AppResult<PathBuf> {

        if let Some(path) = Self::find_path(bin) { return Ok(path); }

        if let Ok(spec) = Tool::spec(bin) {
            if !spec.path.is_empty() && PathBuf::from(spec.path).is_file() { return Ok(spec.path.into()); }
            if let Some(path) = Self::find_path(spec.bin) { return Ok(path); }
        }

        Err(AppError::missing_binary(bin))

    }

    pub fn get ( bin: &str ) -> AppResult<Self> {

        let key = bin.trim();

        let has = |spec: &Spec| {
            spec.name.eq_ignore_ascii_case(key)
                || spec.bin.eq_ignore_ascii_case(key)
                || spec.path.eq_ignore_ascii_case(key)
                || spec.url.eq_ignore_ascii_case(key)
                || spec.aliases.iter().any(|alias| alias.eq_ignore_ascii_case(key))
        };

        TOOLS
            .iter()
            .find(|(name, tool)| {
                name.eq_ignore_ascii_case(key)
                    || has(&tool.apt)
                    || has(&tool.apk)
                    || has(&tool.dnf)
                    || has(&tool.yum)
                    || has(&tool.pacman)
                    || has(&tool.zypper)
                    || has(&tool.brew)
                    || has(&tool.winget)
                    || has(&tool.scoop)
                    || has(&tool.choco)
            })
            .map(|(_, tool)| *tool)
            .ok_or_else(|| AppError::missing_binary(key))

    }

    pub fn spec ( bin: &str ) -> AppResult<Spec> {

        let tool = Self::get(bin)?;

        Ok(match Manager::detect()? {
            Manager::Apt    => tool.apt,
            Manager::Apk    => tool.apk,
            Manager::Dnf    => tool.dnf,
            Manager::Yum    => tool.yum,
            Manager::Pacman => tool.pacman,
            Manager::Zypper => tool.zypper,
            Manager::Brew   => tool.brew,
            Manager::Winget => tool.winget,
            Manager::Scoop  => tool.scoop,
            Manager::Choco  => tool.choco,
        })

    }

    pub fn info ( bin: &str ) -> AppResult<Info> {

        let mut data = Info {
            method  : Method::Native,
            bin     : bin.to_string(),
            name    : bin.to_string(),
            path    : Self::path(bin).ok(),
            version : Self::version(bin).ok().filter(|value| !value.is_empty()),
            url     : None,
            exists  : false,
            args    : Vec::new(),
            aliases : Vec::new(),
        };

        if let Ok(spec) = Self::spec(bin) {

            data = Info {
                method  : spec.method,
                bin     : if spec.bin.is_empty() { bin.to_string() } else { spec.bin.to_string() },
                name    : if spec.name.is_empty() { bin.to_string() } else { spec.name.to_string() },
                path    : data.path.clone().or_else(|| (!spec.path.is_empty()).then(|| std::path::PathBuf::from(spec.path))),
                version : data.version.clone().or_else(|| (!spec.version.is_empty()).then(|| spec.version.to_string())),
                url     : (!spec.url.is_empty()).then(|| spec.url.to_string()),
                exists  : false,
                args    : spec.args.iter().map(|value| (*value).to_string()).collect(),
                aliases : spec.aliases.iter().map(|value| (*value).to_string()).collect(),
            };

        }

        Ok(Info { exists: data.path.is_some(), ..data })

    }

    pub fn show ( bin: &str ) -> AppResult<()> {

        let info = Self::info(bin)?;

        println!("bin      : {}", info.bin);
        println!("name     : {}", info.name);
        println!("path     : {}", info.path.as_deref().map(|path| path.to_string_lossy().into_owned()).unwrap_or_else(|| "unknown".into()));
        println!("version  : {}", info.version.as_deref().unwrap_or("unknown"));
        println!("url      : {}", info.url.as_deref().unwrap_or("unknown"));
        println!("exists   : {}", info.exists);

        Ok(())

    }

    pub fn version ( bin: &str ) -> AppResult<String> {

        let bin = if Self::path(bin).is_ok() { bin.to_string() } else { Self::path(bin)?.to_string_lossy().into_owned() };
        let key = bin.as_str();

        static RE: OnceLock<Regex> = OnceLock::new();
        let mut first_error = None;

        let re = RE.get_or_init(|| {
            Regex::new(r"(?i)(?:^|[^0-9])(?:[a-z]+)?(\d+)\.(\d+)(?:\.(\d+))?([0-9a-z.+-]*)")
                .expect("invalid version regex")
        });

        for args in [&["--version"][..], &["-v"][..], &["-V"][..], &["version"][..]] {

            let output = match Manager::run_capture(key, args) {
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

                    let pre = if tail.is_empty() { String::new() } else {
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
        Err(AppError::message(format!("failed to detect version for {key}")))

    }

}
