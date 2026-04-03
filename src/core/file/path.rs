use std::{env, path::PathBuf, collections::HashSet};
use {nix::unistd::{Uid, User}, normpath::PathExt, rustix::process, which::which};

use super::arch::Path;

impl Path {

    pub fn normalize <P> ( path: P ) -> Option<PathBuf> where P: AsRef<std::path::Path> {

        path.as_ref().normalize().ok().map(|value| value.into_path_buf())

    }

    pub fn env_path ( key: &str ) -> Option<PathBuf> {

        env::var_os(key).filter(|value| !value.is_empty()).map(PathBuf::from)

    }

    pub fn find_paths ( bin: &str ) -> Vec<PathBuf> {

        let bin = bin.trim();
        let mut paths = Vec::new();

        if bin.is_empty() { return paths; }
        if let Ok(path) = which(bin) { paths.push(path); }

        #[cfg(unix)]
        {

            paths.push(PathBuf::from("/bin").join(bin));
            paths.push(PathBuf::from("/sbin").join(bin));

            paths.push(PathBuf::from("/usr/bin").join(bin));
            paths.push(PathBuf::from("/usr/sbin").join(bin));

            paths.push(PathBuf::from("/usr/local/bin").join(bin));
            paths.push(PathBuf::from("/usr/local/sbin").join(bin));

            paths.push(PathBuf::from("/snap/bin").join(bin));
            paths.push(PathBuf::from("/home/linuxbrew/.linuxbrew/bin").join(bin));

            #[cfg(target_os = "macos")]
            {
                paths.push(PathBuf::from("/opt/homebrew/bin").join(bin));
                paths.push(PathBuf::from("/opt/homebrew/opt").join(bin).join("bin").join(bin));
                paths.push(PathBuf::from("/usr/local/opt").join(bin).join("bin").join(bin));
            }

            if let Some(home) = Self::env_path("HOME") {
                paths.push(home.join(".local").join("bin").join(bin));
                paths.push(home.join(".config").join("mise").join("shims").join(bin));
                paths.push(home.join(".local").join("share").join("mise").join("shims").join(bin));
                paths.push(home.join(".local").join("share").join("aquaproj-aqua").join("bin").join(bin));
                paths.push(home.join(".nix-profile").join("bin").join(bin));
                paths.push(home.join(".linuxbrew").join("bin").join(bin));
                paths.push(home.join("snap").join("bin").join(bin));
            }

        }

        #[cfg(windows)]
        {

            let mut exts: Vec<String> = env::var("PATHEXT")
                .unwrap_or(".COM;.EXE;.BAT;.CMD".into())
                .split(';').map(|ext| ext.trim().to_ascii_lowercase())
                .filter(|ext| !ext.is_empty())
                .collect();

            if PathBuf::from(bin).extension().is_some() {
                exts.clear();
                exts.push(String::new());
            }

            if let Some(local) = Self::env_path("LOCALAPPDATA") {
                for ext in &exts {
                    let file = format!("{bin}{ext}");
                    paths.push(local.join("Microsoft").join("WinGet").join("Links").join(&file));
                    paths.push(local.join("mise").join("shims").join(&file));
                    paths.push(local.join("Programs").join(bin).join(&file));
                }
            }

            if let Some(user) = Self::env_path("USERPROFILE") {
                for ext in &exts {
                    let file = format!("{bin}{ext}");
                    paths.push(user.join("scoop").join("shims").join(&file));
                    paths.push(user.join(".local").join("bin").join(&file));
                }
            }

            if let Some(program_data) = Self::env_path("ProgramData") {
                for ext in &exts {
                    let file = format!("{bin}{ext}");
                    paths.push(program_data.join("chocolatey").join("bin").join(&file));
                }
            }

            if let Some(program_files) = Self::env_path("ProgramFiles") {
                for ext in &exts {
                    let file = format!("{bin}{ext}");
                    paths.push(program_files.join(bin).join(&file));
                }
            }

            if let Some(program_files_x86) = Self::env_path("ProgramFiles(x86)") {
                for ext in &exts {
                    let file = format!("{bin}{ext}");
                    paths.push(program_files_x86.join(bin).join(&file));
                }
            }

        }

        let mut seen = HashSet::new();
        paths.into_iter().filter(|path| seen.insert(path.clone())).collect()
        

    }

    pub fn find_path ( bin: &str ) -> Option<PathBuf> {

        for path in Self::find_paths(bin) {

            if path.is_file() { return Some(path); }

        }

        None

    }

    pub fn temp_dir () -> PathBuf {

        env::temp_dir()

    }

    pub fn current_dir () -> Option<PathBuf> {

        env::current_dir().ok().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn exe_dir () -> Option<PathBuf> {

        env::current_exe()
            .ok()
            .and_then(|value| value.parent().map(|value| value.to_path_buf()))
            .filter(|value| !value.as_os_str().is_empty())

    }

    pub fn home_dir () -> Option<PathBuf> {

        dirs::home_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn config_dir () -> Option<PathBuf> {

        dirs::config_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn cache_dir () -> Option<PathBuf> {

        dirs::cache_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn data_dir () -> Option<PathBuf> {

        dirs::data_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn audio_dir () -> Option<PathBuf> {

        dirs::audio_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn video_dir () -> Option<PathBuf> {

        dirs::video_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn picture_dir () -> Option<PathBuf> {

        dirs::picture_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn font_dir () -> Option<PathBuf> {

        dirs::font_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn state_dir () -> Option<PathBuf> {

        dirs::state_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn desktop_dir () -> Option<PathBuf> {

        dirs::desktop_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn download_dir () -> Option<PathBuf> {

        dirs::download_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn document_dir () -> Option<PathBuf> {

        dirs::document_dir().filter(|value| !value.as_os_str().is_empty())

    }

    pub fn shell_dir () -> Option<PathBuf> {

        #[cfg(unix)]
        {

            return User::from_uid(Uid::from_raw(process::geteuid().as_raw()))
                .ok()
                .flatten()
                .map(|value| value.shell)
                .filter(|value| !value.as_os_str().is_empty());

        }

        #[cfg(windows)]
        {

            return env::var_os("COMSPEC")
                .filter(|value| !value.is_empty())
                .map(PathBuf::from)
                .or_else(|| {
                    env::var_os("SystemRoot")
                        .filter(|value| !value.is_empty())
                        .map(|root| PathBuf::from(root).join("System32").join("cmd.exe"))
                })
                .or_else(|| Some(PathBuf::from(r"C:\Windows\System32\cmd.exe")));

        }

    }

}
