use std::path::{Path, PathBuf};
use std::fs::File;

use crate::core::error::{AppResult, AppError};
use super::base::Manager;

impl Manager {

    pub fn new_dir ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        let path = path.as_ref();
        std::fs::create_dir_all(path)?;
        Ok(path.to_path_buf())

    }

    pub fn new_file ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        let path = path.as_ref();

        if let Some(parent) = path.parent().filter(|parent| !parent.as_os_str().is_empty()) {
            std::fs::create_dir_all(parent)?;
        }

        File::create_new(path)?;
        Ok(path.to_path_buf())

    }

    pub fn remove_dir ( path: impl AsRef<Path> ) -> AppResult<()> {

        match std::fs::remove_dir_all(path.as_ref()) {
            Ok(()) => Ok(()),
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(()),
            Err(err) => Err(err.into()),
        }

    }

    pub fn remove_file ( path: impl AsRef<Path> ) -> AppResult<()> {

        let path = path.as_ref();

        let meta = match std::fs::symlink_metadata(path) {
            Ok(meta) => meta,
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => return Ok(()),
            Err(err) => return Err(err.into()),
        };

        if meta.file_type().is_symlink() {
            match std::fs::remove_file(path) {
                Ok(()) => return Ok(()),
                Err(_) => {
                    std::fs::remove_dir(path)?;
                    return Ok(());
                }
            }
        }

        std::fs::remove_file(path)?;
        Ok(())

    }


    pub fn is_dir ( path: impl AsRef<Path> ) -> bool {

        path.as_ref().is_dir()

    }

    pub fn is_file ( path: impl AsRef<Path> ) -> bool {

        path.as_ref().is_file()

    }

    pub fn is_path ( path: impl AsRef<Path> ) -> bool {

        path.as_ref().exists()

    }

    pub fn is_link ( path: impl AsRef<Path> ) -> bool {

        std::fs::symlink_metadata(path).map(|meta| meta.file_type().is_symlink()).unwrap_or(false)

    }


    pub fn link ( from: impl AsRef<Path>, to: impl AsRef<Path> ) -> AppResult<()> {

        let from = from.as_ref();
        let to   = to.as_ref();

        if let Some(parent) = to.parent().filter(|parent| !parent.as_os_str().is_empty()) {
            std::fs::create_dir_all(parent)?;
        }

        #[cfg(unix)]
        {
            std::os::unix::fs::symlink(from, to)?;
            return Ok(());
        }

        #[cfg(windows)]
        {
            let meta = std::fs::symlink_metadata(from)?;

            if meta.file_type().is_dir() { std::os::windows::fs::symlink_dir(from, to)?; }
            else { std::os::windows::fs::symlink_file(from, to)?; }

            return Ok(());
        }

        Err(AppError::unsupported_operation("symlink"))

    }

    pub fn copy ( from: impl AsRef<Path>, to: impl AsRef<Path> ) -> AppResult<u64> {

        let from = from.as_ref();
        let to   = to.as_ref();

        if let Some(parent) = to.parent().filter(|parent| !parent.as_os_str().is_empty()) {
            std::fs::create_dir_all(parent)?;
        }

        Ok(std::fs::copy(from, to)?)

    }

    pub fn r#move ( from: impl AsRef<Path>, to: impl AsRef<Path> ) -> AppResult<()> {

        let from = from.as_ref();
        let to   = to.as_ref();

        if let Some(parent) = to.parent().filter(|parent| !parent.as_os_str().is_empty()) {
            std::fs::create_dir_all(parent)?;
        }

        match std::fs::rename(from, to) {
            Ok(()) => Ok(()),
            Err(_) => {
                if from.is_dir() { return Err(AppError::unsupported_operation("moving directories")); }

                std::fs::copy(from, to)?;
                std::fs::remove_file(from)?;

                Ok(())
            }
        }

    }

    pub fn join ( base: impl AsRef<Path>, parts: &[&str] ) -> PathBuf {

        let mut path = base.as_ref().to_path_buf();
        for part in parts { path.push(part); }
        path

    }

    pub fn env_path ( key: &str ) -> Option<PathBuf> {

        std::env::var_os(key).filter(|value| !value.is_empty()).map(PathBuf::from)

    }

    pub fn path_var () -> Vec<PathBuf> {

        std::env::var_os("PATH").map(|value| std::env::split_paths(&value).collect()).unwrap_or_default()

    }


    pub fn ensure_dir ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        let path = path.as_ref();

        if path.exists() {
            if path.is_dir() { return Ok(path.to_path_buf()); }
            return Err(AppError::path_type_mismatch(path, "dir", "file"));
        }

        Self::new_dir(path)

    }

    pub fn ensure_file ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        let path = path.as_ref();

        if path.exists() {
            if path.is_file() { return Ok(path.to_path_buf()); }
            return Err(AppError::path_type_mismatch(path, "file", "dir"));
        }

        Self::new_file(path)

    }

    pub fn need_dir ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        let path = path.as_ref();

        if path.is_dir() { return Ok(path.to_path_buf()); }
        if path.is_file() { return Err(AppError::path_type_mismatch(path, "dir", "file")); }

        Err(AppError::path_not_found(path))

    }

    pub fn need_file ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        let path = path.as_ref();

        if path.is_file() { return Ok(path.to_path_buf()); }
        if path.is_dir() { return Err(AppError::path_type_mismatch(path, "file", "dir")); }

        Err(AppError::path_not_found(path))

    }


    pub fn current_dir () -> AppResult<PathBuf> {

        Ok(std::env::current_dir()?)

    }

    pub fn home_dir () -> AppResult<PathBuf> {

        #[cfg(windows)]
        {
            return std::env::var_os("USERPROFILE")
                .filter(|value| !value.is_empty())
                .map(PathBuf::from)
                .or_else(|| {
                    let drive = std::env::var_os("HOMEDRIVE")?;
                    let path  = std::env::var_os("HOMEPATH")?;

                    let mut full = PathBuf::from(drive);
                    full.push(path);

                    Some(full)
                })
                .ok_or_else(|| AppError::missing_env_var("USERPROFILE or HOMEDRIVE/HOMEPATH"));

        }

        #[cfg(not(windows))]
        {
            std::env::var_os("HOME")
                .filter(|value| !value.is_empty())
                .map(PathBuf::from)
                .ok_or_else(|| AppError::missing_env_var("HOME"))
        }

    }

    pub fn config_dir () -> AppResult<PathBuf> {

        #[cfg(windows)]
        {
            return Self::env_path("APPDATA").ok_or_else(|| AppError::missing_env_var("APPDATA"));
        }

        #[cfg(target_os = "macos")]
        {
            return Ok(Self::home_dir()?.join("Library").join("Application Support"));
        }

        #[cfg(all(unix, not(target_os = "macos")))]
        {
            Ok(Self::env_path("XDG_CONFIG_HOME").unwrap_or(Self::home_dir()?.join(".config")))
        }

    }

    pub fn cache_dir () -> AppResult<PathBuf> {

        #[cfg(windows)]
        {
            return Self::env_path("LOCALAPPDATA")
                .or_else(|| Self::env_path("TEMP"))
                .or_else(|| Self::env_path("TMP"))
                .ok_or_else(|| AppError::missing_env_var("LOCALAPPDATA or TEMP or TMP"));
        }

        #[cfg(target_os = "macos")]
        {
            return Ok(Self::home_dir()?.join("Library").join("Caches"));
        }

        #[cfg(all(unix, not(target_os = "macos")))]
        {
            Ok(Self::env_path("XDG_CACHE_HOME").unwrap_or(Self::home_dir()?.join(".cache")))
        }

    }

    pub fn temp_dir () -> AppResult<PathBuf>  {

        Ok(std::env::temp_dir())

    }

    pub fn temp_name ( prefix: &str ) -> String {

        let pid = std::process::id();

        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|time| time.as_nanos())
            .unwrap_or(0);

        format!("{prefix}-{pid}-{now}")

    }

    pub fn new_temp_dir () -> AppResult<PathBuf> {

        let base = std::env::temp_dir();

        for _ in 0..256 {

            let path = base.join(Self::temp_name("dir"));

            match std::fs::create_dir(&path) {
                Ok(()) => return Ok(path),
                Err(err) if err.kind() == std::io::ErrorKind::AlreadyExists => continue,
                Err(err) => return Err(err.into()),
            }

        }

        Err(AppError::operation_failed("create", "cannot create temp dir"))

    }

    pub fn new_temp_file () -> AppResult<PathBuf> {

        let base = std::env::temp_dir();

        for _ in 0..256 {

            let path = base.join(Self::temp_name("file"));

            match File::create_new(&path) {
                Ok(_) => return Ok(path),
                Err(err) if err.kind() == std::io::ErrorKind::AlreadyExists => continue,
                Err(err) => return Err(err.into()),
            }
        }

        Err(AppError::operation_failed("create", "cannot create temp file"))

    }


    pub fn parent_dir ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        path.as_ref()
            .parent()
            .map(Path::to_path_buf)
            .ok_or_else(|| AppError::message(format!("path has no parent: {}", path.as_ref().display())))

    }

    pub fn dir_name ( path: impl AsRef<Path> ) -> AppResult<String> {

        path.as_ref()
            .file_name()
            .map(|value| value.to_string_lossy().into_owned())
            .filter(|value| !value.is_empty())
            .ok_or_else(|| AppError::message(format!("path has no name: {}", path.as_ref().display())))

    }

    pub fn parent_name ( path: impl AsRef<Path> ) -> AppResult<String> {

        Self::parent_dir(path)?
            .file_name()
            .map(|value| value.to_string_lossy().into_owned())
            .filter(|value| !value.is_empty())
            .ok_or_else(|| AppError::message("path parent has no name"))

    }

    pub fn expand_home ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        let path = path.as_ref();

        if path == Path::new("~") { return Self::home_dir(); }

        let mut parts = path.components();

        match parts.next() {
            Some(std::path::Component::Normal(part)) if part == "~" => {
                let mut full = Self::home_dir()?;

                for part in parts {
                    full.push(part.as_os_str());
                }

                Ok(full)
            }
            _ => Ok(path.to_path_buf()),
        }

    }

    pub fn abs_path ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        let path = Self::expand_home(path)?;

        if path.is_absolute() { return Ok(path); }

        Ok(Self::current_dir()?.join(path))

    }

    pub fn can_path ( path: impl AsRef<Path> ) -> AppResult<PathBuf> {

        Ok(std::fs::canonicalize(Self::expand_home(path)?)?)

    }


    pub fn list ( dir: impl AsRef<Path> ) -> AppResult<Vec<PathBuf>> {

        let dir = Self::need_dir(dir)?;
        let mut items = Vec::new();

        for entry in std::fs::read_dir(dir)? {
            items.push(entry?.path());
        }

        items.sort();
        Ok(items)

    }

    pub fn dir_list ( dir: impl AsRef<Path> ) -> AppResult<Vec<PathBuf>> {

        Ok(Self::list(dir)?
            .into_iter()
            .filter(|path| path.is_dir())
            .collect())

    }

    pub fn file_list ( dir: impl AsRef<Path> ) -> AppResult<Vec<PathBuf>> {

        Ok(Self::list(dir)?
            .into_iter()
            .filter(|path| path.is_file())
            .collect())

    }

    pub fn list_names ( dir: impl AsRef<Path> ) -> AppResult<Vec<String>> {

        Ok(Self::list(dir)?
            .into_iter()
            .filter_map(|path| {
                path.file_name()
                    .map(|name| name.to_string_lossy().into_owned())
                    .filter(|name| !name.is_empty())
            })
            .collect())

    }

    pub fn count ( dir: impl AsRef<Path> ) -> AppResult<usize> {

        Ok(Self::list(dir)?.len())

    }

    pub fn count_dirs ( dir: impl AsRef<Path> ) -> AppResult<usize> {

        Ok(Self::dir_list(dir)?.len())

    }

    pub fn count_files ( dir: impl AsRef<Path> ) -> AppResult<usize> {

        Ok(Self::file_list(dir)?.len())

    }

}
