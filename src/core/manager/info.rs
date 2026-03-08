use std::{path::PathBuf, sync::OnceLock};
use semver::Version;
use regex::Regex;

use crate::core::app::{AppResult, AppError};
use crate::core::tool::{Tool};
use super::arch::{Manager, Info};

impl Manager {

    fn env_path ( key: &str ) -> Option<PathBuf> {

        std::env::var_os(key).filter(|value| !value.is_empty()).map(PathBuf::from)

    }

    fn find_paths ( bin: &str ) -> Vec<PathBuf> {

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

    fn find_path ( bin: &str ) -> Option<PathBuf> {

        for path in Self::find_paths(bin) {
            if path.is_file() {
                return Some(path);
            }
        }

        None

    }


    pub fn clean ( bin: &str ) -> AppResult<()> {

        Self::find_paths(bin).into_iter().for_each(|path| { let _ = std::fs::remove_file(path); });
        Ok(())

    }

    pub fn path ( bin: &str ) -> AppResult<PathBuf> {

        if let Some(path) = Self::find_path(bin) {
            return Ok(path);
        }

        if let Ok(info) = Tool::get(bin) {
            if !info.path.is_empty() && PathBuf::from(info.path).is_file() { return Ok(info.path.into()); }
            if let Some(path) = Self::find_path(info.bin) { return Ok(path); }
        }

        Err(AppError::missing_binary(bin))

    }

    pub fn has ( bin: &str ) -> bool {

        if Self::find_path(bin).is_some() { return true; }

        match Tool::get(bin) {
            Ok(info) => {
                if !info.path.is_empty() && PathBuf::from(info.path).is_file() { return true; }
                Self::find_path(info.bin).is_some()
            }
            Err(_) => false,
        }

    }

    pub fn need ( bin: &str ) -> AppResult<()> {

        if Self::has(bin) { return Ok(()); }
        Err(AppError::missing_binary(bin))

    }

    pub fn version ( bin: &str ) -> AppResult<String> {

        Self::need(bin)?;

        static RE: OnceLock<Regex> = OnceLock::new();
        let mut first_error = None;

        let re = RE.get_or_init(|| {
            Regex::new(r"(?i)(?:^|[^0-9])(?:[a-z]+)?(\d+)\.(\d+)(?:\.(\d+))?([0-9a-z.+-]*)")
                .expect("invalid version regex")
        });

        for args in [&["--version"][..], &["-v"][..], &["-V"][..], &["version"][..]] {
            
            let output = match Self::run_output(bin, args) {
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
        Err(AppError::message(format!("failed to detect version for {bin}")))

    }

    pub fn info ( bin: &str ) -> AppResult<Info> {

        Self::need(bin)?;

        let path = Self::path(bin).ok();
        let exists = path.is_some();

        if let Ok(info) = Tool::get(bin) {

            return Ok(Info {
                path,
                exists,
                version : if info.path.is_empty() { Self::version(info.bin).ok() } else { Self::version(info.path).ok() },
                id      : (!info.id.is_empty()).then(|| info.id.to_string()),
                bin     : (!info.bin.is_empty()).then(|| info.bin.to_string()),
                url     : (!info.url.is_empty()).then(|| info.url.to_string()),
                source  : Some(info.source.as_str().to_string()),
            });

        }

        Ok(Info {
            path,
            exists,
            version : Self::version(bin).ok(),
            bin     : Some(bin.to_string()),
            id      : None,
            url     : None,
            source  : None,
        })

    }

    pub fn show ( bin: &str ) -> AppResult<()> {

        let spec = Self::info(bin)?;

        println!("id       : {}", spec.id.as_deref().unwrap_or("-"));
        println!("bin      : {}", spec.bin.as_deref().unwrap_or("-"));
        println!("path     : {}", spec.path.as_deref().map(|path| path.to_string_lossy().into_owned()).unwrap_or_else(|| "-".into()));
        println!("version  : {}", spec.version.as_deref().unwrap_or("-"));
        println!("url      : {}", spec.url.as_deref().unwrap_or("-"));
        println!("source   : {}", spec.source.as_deref().unwrap_or("-"));
        println!("exists   : {}", spec.exists);

        Ok(())

    }


    pub fn has_all ( bins: &[&str] ) -> bool {

        bins.iter().all(|bin| Self::has(bin))

    }

    pub fn need_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::need(bin)?; }

        Ok(())

    }

    pub fn show_all ( bins: &[&str] ) -> AppResult<()> {

        for bin in bins { Self::show(bin)?; }
        Ok(())

    }

}
