
use super::arch::{Service, Launcher, Manager, AppResult, AppError};

impl Service {

    pub fn install ( &self ) -> AppResult<()> {

        match Self::detect() {
            Launcher::Systemd => self.install_systemd(),
            Launcher::Launchd => self.install_launchd(),
            Launcher::OpenRc  => Err(AppError::message("openrc service install is not implemented yet")),
            Launcher::SysV    => Err(AppError::message("sysv service install is not implemented yet")),
            Launcher::Windows => Err(AppError::message("windows service install is not implemented yet")),
            Launcher::Unknown => Err(AppError::message("failed to detect service manager")),
        }

    }

    pub fn uninstall ( &self ) -> AppResult<()> {

        match Self::detect() {
            Launcher::Systemd => self.uninstall_systemd(),
            Launcher::Launchd => self.uninstall_launchd(),
            Launcher::OpenRc  => Err(AppError::message("openrc service uninstall is not implemented yet")),
            Launcher::SysV    => Err(AppError::message("sysv service uninstall is not implemented yet")),
            Launcher::Windows => Err(AppError::message("windows service uninstall is not implemented yet")),
            Launcher::Unknown => Err(AppError::message("failed to detect service manager")),
        }

    }

    pub fn start ( &self ) -> AppResult<()> {

        match Self::detect() {
            Launcher::Systemd => Manager::sudo_run("systemctl", &["start", self.name]),
            Launcher::Launchd => Manager::run("launchctl", &["start", self.name]),
            Launcher::OpenRc  => Manager::sudo_run("rc-service", &[self.name, "start"]),
            Launcher::SysV    => Manager::sudo_run("service", &[self.name, "start"]),
            Launcher::Windows => Err(AppError::message("windows service start is not implemented yet")),
            Launcher::Unknown => Err(AppError::message("failed to detect service manager")),
        }

    }

    pub fn stop ( &self ) -> AppResult<()> {

        match Self::detect() {
            Launcher::Systemd => Manager::sudo_run("systemctl", &["stop", self.name]),
            Launcher::Launchd => Manager::run("launchctl", &["stop", self.name]),
            Launcher::OpenRc  => Manager::sudo_run("rc-service", &[self.name, "stop"]),
            Launcher::SysV    => Manager::sudo_run("service", &[self.name, "stop"]),
            Launcher::Windows => Err(AppError::message("windows service stop is not implemented yet")),
            Launcher::Unknown => Err(AppError::message("failed to detect service manager")),
        }

    }

    pub fn restart ( &self ) -> AppResult<()> {

        match Self::detect() {
            Launcher::Systemd => Manager::sudo_run("systemctl", &["restart", self.name]),
            Launcher::Launchd => {
                let _ = Manager::run("launchctl", &["stop", self.name]);
                Manager::run("launchctl", &["start", self.name])
            }
            Launcher::OpenRc  => Manager::sudo_run("rc-service", &[self.name, "restart"]),
            Launcher::SysV    => Manager::sudo_run("service", &[self.name, "restart"]),
            Launcher::Windows => Err(AppError::message("windows service restart is not implemented yet")),
            Launcher::Unknown => Err(AppError::message("failed to detect service manager")),
        }

    }

    pub fn enable ( &self ) -> AppResult<()> {

        match Self::detect() {
            Launcher::Systemd => Manager::sudo_run("systemctl", &["enable", self.name]),
            Launcher::Launchd => Manager::run("launchctl", &["enable", &format!("system/{}", self.name)]),
            Launcher::OpenRc  => Manager::sudo_run("rc-update", &["add", self.name, "default"]),
            Launcher::SysV    => Err(AppError::message("sysv service enable is not implemented yet")),
            Launcher::Windows => Err(AppError::message("windows service enable is not implemented yet")),
            Launcher::Unknown => Err(AppError::message("failed to detect service manager")),
        }

    }

    pub fn disable ( &self ) -> AppResult<()> {

        match Self::detect() {
            Launcher::Systemd => Manager::sudo_run("systemctl", &["disable", self.name]),
            Launcher::Launchd => Manager::run("launchctl", &["disable", &format!("system/{}", self.name)]),
            Launcher::OpenRc  => Manager::sudo_run("rc-update", &["del", self.name, "default"]),
            Launcher::SysV    => Err(AppError::message("sysv service disable is not implemented yet")),
            Launcher::Windows => Err(AppError::message("windows service disable is not implemented yet")),
            Launcher::Unknown => Err(AppError::message("failed to detect service manager")),
        }

    }

    pub fn status ( &self ) -> AppResult<()> {

        match Self::detect() {
            Launcher::Systemd => Manager::sudo_run("systemctl", &["status", self.name, "--no-pager"]),
            Launcher::Launchd => Manager::run("launchctl", &["print", &format!("system/{}", self.name)]),
            Launcher::OpenRc  => Manager::sudo_run("rc-service", &[self.name, "status"]),
            Launcher::SysV    => Manager::sudo_run("service", &[self.name, "status"]),
            Launcher::Windows => Err(AppError::message("windows service status is not implemented yet")),
            Launcher::Unknown => Err(AppError::message("failed to detect service manager")),
        }

    }

    pub fn logs ( &self, lines: usize ) -> AppResult<()> {

        let lines = lines.max(1).to_string();

        match Self::detect() {
            Launcher::Systemd => Manager::sudo_run("journalctl", &["-u", self.name, "-n", &lines, "--no-pager"]),
            Launcher::Launchd => Err(AppError::message("launchd logs are not implemented yet")),
            Launcher::OpenRc  => Err(AppError::message("openrc logs are not implemented yet")),
            Launcher::SysV    => Err(AppError::message("sysv logs are not implemented yet")),
            Launcher::Windows => Err(AppError::message("windows logs are not implemented yet")),
            Launcher::Unknown => Err(AppError::message("failed to detect service manager")),
        }

    }

}
