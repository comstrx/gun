use std::{path::PathBuf};

use crate::core::app::{AppError, AppResult};
use super::arch::{Manager, Tool};

impl Manager {

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

    pub fn path_str ( bin: &str ) -> AppResult<String> {

        Ok(Self::path(bin)?.to_string_lossy().into_owned())

    }

    pub fn has ( bin: &str ) -> bool {

        Self::path(bin).is_ok()

    }

    pub fn need ( bin: &str ) -> AppResult<()> {

        if Self::has(bin) { return Ok(()); }
        Err(AppError::missing_binary(bin))

    }

}
