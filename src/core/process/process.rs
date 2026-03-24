use std::{fs, env, path::PathBuf};
use os_info::Type;

use crate::core::app::{AppResult, AppError};
use super::manager::Manager;
use super::tool::{Tool, Spec, Info, Method};

pub struct Process;

impl Process {

    pub fn manager () -> AppResult<Manager> {

        Manager::detect()

    }

    pub fn manager_name () -> &'static str {

        Manager::detect().map(|manager| manager.as_str()).unwrap_or("unknown")

    }

    pub fn os_name () -> &'static str {

        match os_info::get().os_type() {
            Type::Windows => "windows",
            Type::Macos => "macos",
            _ => "linux",
        }

    }

    pub fn os_arch () -> String {

        os_info::get().architecture().unwrap_or("unknown").to_string()

    }

    pub fn os_version () -> String {

        os_info::get().version().to_string()

    }

    pub fn is_windows () -> bool {

        matches!(os_info::get().os_type(), Type::Windows)

    }

    pub fn is_macos () -> bool {

        matches!(os_info::get().os_type(), Type::Macos)

    }

    pub fn is_linux () -> bool {

        !Self::is_windows() && !Self::is_macos()

    }

    pub fn is_unix () -> bool {

        !Self::is_windows()

    }

    pub fn is_wsl () -> bool {

        if !Self::is_linux() { return false; }

        if env::var_os("WSL_DISTRO_NAME").is_some() { return true; }
        if env::var_os("WSL_INTEROP").is_some() { return true; }

        let has_microsoft = |path: &str| {
            fs::read_to_string(path)
                .map(|text| text.to_ascii_lowercase().contains("microsoft"))
                .unwrap_or(false)
        };

        has_microsoft("/proc/sys/kernel/osrelease") || has_microsoft("/proc/version")

    }


    pub fn owned ( bin: &str ) -> bool {

        Tool::get(bin).is_ok()

    }

    pub fn get ( bin: &str ) -> AppResult<Tool> {

        Tool::get(bin)

    }

    pub fn spec ( bin: &str ) -> AppResult<Spec> {

        Tool::spec(bin)

    }

    pub fn info ( bin: &str ) -> AppResult<Info> {

        Tool::info(bin)

    }

    pub fn show ( bin: &str ) -> AppResult<()> {

        Tool::show(bin)

    }

    pub fn version ( bin: &str ) -> AppResult<String> {

        Tool::version(bin)

    }

    pub fn path ( bin: &str ) -> AppResult<PathBuf> {

        Tool::path(bin)

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

    pub fn install ( bin: &str ) -> AppResult<()> {

        if Self::get(bin).is_err() { return Manager::native_install(bin); }

        let spec = Self::spec(bin)?;
        let id = if spec.name.is_empty() { spec.bin } else { spec.name };
        let url = if spec.url.is_empty() { id } else { spec.url };

        match spec.method {
            Method::Native => Manager::native_install(id),
            Method::Nix    => Manager::nix_install(url),
            Method::Mise   => Manager::mise_install(url),
            Method::Bash   => Manager::script_install(id, url, spec.args, true),
            Method::Shell  => Manager::script_install(id, url, spec.args, false),
        }

    }

    pub fn remove ( bin: &str ) -> AppResult<()> {

        let id = match Self::spec(bin) {
            Ok(spec) => {
                if !spec.url.is_empty() {
                    if Self::has("nix") { let _ = Manager::nix_remove(spec.url); }
                    if Self::has("mise") { let _ = Manager::mise_remove(spec.url); }
                }

                let name = if spec.name.is_empty() { spec.bin } else { spec.name };
                if name.is_empty() { bin } else { name }
            }
            Err(_) => bin,
        };

        if Self::has("nix") { let _ = Manager::nix_remove(id); }
        if Self::has("mise") { let _ = Manager::mise_remove(id); }

        let _ = Manager::native_remove(id);
        if let Ok(path) = Self::path(bin) { let _ = std::fs::remove_file(path); }

        Ok(())

    }

    pub fn ensure ( bin: &str ) -> AppResult<()> {

        if !Self::has(bin) { Self::install(bin)?; }

        match Self::version(bin) {
            Ok(_) => Ok(()),
            Err(_) => {
                let spec = Self::spec(bin)?;

                if spec.path.is_empty() {
                    let _ = Self::version(spec.bin)?;
                    return Ok(());
                }

                match Self::version(spec.path) {
                    Ok(_) => Ok(()),
                    Err(_) => {
                        let _ = Self::version(spec.bin)?;
                        Ok(())
                    }
                }
            }
        }

    }


    pub fn has_all ( bins: &[&str] ) -> bool {

        bins.iter().all(|bin| Self::has(bin))

    }

    pub fn need_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::need(bin)?; }
        Ok(())

    }

    pub fn install_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::install(bin)?; }
        Ok(())

    }

    pub fn remove_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::remove(bin)?; }
        Ok(())

    }

    pub fn ensure_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::ensure(bin)?; }
        Ok(())

    }

    pub fn show_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::show(bin)?; }
        Ok(())

    }

}
