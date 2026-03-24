
use super::arch::{Service, Launcher, Manager, AppResult, AppError};
use {which::which, os_info::Type};

impl Service {

    pub fn launcher () -> AppResult<Launcher> {

        match os_info::get().os_type() {
            Type::Windows => {
                Ok(Launcher::Windows)
            },
            Type::Macos   => {
                if which("launchctl").is_ok() { return Ok(Launcher::Launchd); }
                Err(AppError::command_not_found("service"))
            },
            _ => {
                if which("systemctl").is_ok() { return Ok(Launcher::Systemd); }
                if which("rc-service").is_ok() { return Ok(Launcher::OpenRc); }
                if which("service").is_ok() { return Ok(Launcher::SysV); }

                Err(AppError::command_not_found("service"))
            }
        }

    }

    pub fn path ( &self ) -> AppResult<String> {

        let path = match Self::launcher()? {
            Launcher::Systemd => format!("/etc/systemd/system/{}.service", self.name),
            Launcher::Launchd => format!("/Library/LaunchDaemons/{}.plist", self.name),
            Launcher::OpenRc  => format!("/etc/init.d/{}", self.name),
            Launcher::SysV    => format!("/etc/init.d/{}", self.name),
            Launcher::Windows => self.name.to_string(),
            Launcher::Unknown => self.name.to_string(),
        };

        Ok(path)

    }

    pub fn write ( path: &str, text: &str ) -> AppResult<()> {

        let temp_name = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map_err(|_| AppError::message("failed to build temp name"))?
            .as_nanos();

        let temp_file = std::env::temp_dir().join(format!("gun-{}-{}.tmp", std::process::id(), temp_name));
        let temp = temp_file.to_str().ok_or_else(|| AppError::message("invalid temp path"))?;

        std::fs::write(&temp_file, text)?;
        Manager::try_run("mv", &[temp, path])?;

        Ok(())

    }

}
