
use crate::core::app::{AppResult};
use super::arch::{Manager, Tool, Spec, Info};

impl Manager {

    pub fn name () -> &'static str {

        Self::detect().map(|m| m.as_str()).unwrap_or("unknown")

    }

    pub fn os_name () -> &'static str {

        match os_info::get().os_type() {
            os_info::Type::Windows => "windows",
            os_info::Type::Macos   => "macos",
            os_info::Type::Linux   => "linux",
            _             => "unknown",
        }

    }


    pub fn is_windows () -> bool {

        matches!(os_info::get().os_type(), os_info::Type::Windows)

    }

    pub fn is_macos () -> bool {

        matches!(os_info::get().os_type(), os_info::Type::Macos)

    }

    pub fn is_linux () -> bool {

        matches!(os_info::get().os_type(), os_info::Type::Linux)

    }

    pub fn is_unix () -> bool {

        !Self::is_windows()

    }

    pub fn is_wsl () -> bool {

        if !cfg!(target_os = "linux") { return false; }

        if std::env::var_os("WSL_DISTRO_NAME").is_some() { return true; }
        if std::env::var_os("WSL_INTEROP").is_some() { return true; }

        std::fs::read_to_string("/proc/version")
            .map(|text| text.to_ascii_lowercase().contains("microsoft"))
            .unwrap_or(false)

    }


    pub fn tool ( bin: &str ) -> AppResult<Tool> {

        Tool::get(bin)

    }

    pub fn spec ( bin: &str ) -> AppResult<Spec> {

        Spec::get(bin)

    }

    pub fn info ( key: &str ) -> AppResult<Info> {

        Info::get(key)

    }

    pub fn show ( key: &str ) -> AppResult<()> {

        Info::show(key)

    }

}
