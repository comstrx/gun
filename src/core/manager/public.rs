
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
            os_info::Type::Linux
                | os_info::Type::Ubuntu
                | os_info::Type::Debian
                | os_info::Type::Arch
                | os_info::Type::Fedora
                | os_info::Type::Redhat
                | os_info::Type::CentOS
                | os_info::Type::Alpine
                | os_info::Type::OracleLinux
                | os_info::Type::SUSE
                | os_info::Type::openSUSE
                | os_info::Type::Amazon
                | os_info::Type::Android => "linux",
            _  => "unknown",
        }

    }

    pub fn is_windows () -> bool {

        Self::os_name() == "windows"

    }

    pub fn is_macos () -> bool {

        Self::os_name() == "macos"

    }

    pub fn is_linux () -> bool {

        Self::os_name() == "linux"

    }

    pub fn is_unix () -> bool {

        !Self::is_windows()

    }

    pub fn is_wsl () -> bool {

        if !cfg!(target_os = "linux") { return false; }

        if std::env::var_os("WSL_DISTRO_NAME").is_some() { return true; }
        if std::env::var_os("WSL_INTEROP").is_some() { return true; }

        if std::fs::read_to_string("/proc/sys/kernel/osrelease")
            .map(|text| text.to_ascii_lowercase().contains("microsoft"))
            .unwrap_or(false) { return true; }

        std::fs::read_to_string("/proc/version")
            .map(|text| text.to_ascii_lowercase().contains("microsoft"))
            .unwrap_or(false)

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
