use crate::core::{AppResult, AppError};
use super::arch::{Service, Manager, Launcher};

impl Service {

    pub const fn new ( name: &'static str ) -> Self {

        Self {
            name        : name,
            kind        : "simple",
            description : "",
            command     : "",
            args        : &[],
            cwd         : "",
            user        : "",
            group       : "",
            env         : &[],
            restart     : "always",
            wanted_by   : "multi-user.target",
        }

    }

    pub const fn set_name ( mut self, value: &'static str ) -> Self {

        self.name = value;
        self

    }

    pub const fn set_type ( mut self, value: &'static str ) -> Self {

        self.kind = value;
        self

    }

    pub const fn set_description ( mut self, value: &'static str ) -> Self {

        self.description = value;
        self

    }

    pub const fn set_command ( mut self, value: &'static str ) -> Self {

        self.command = value;
        self

    }

    pub const fn set_args ( mut self, value: &'static [&'static str] ) -> Self {

        self.args = value;
        self

    }

    pub const fn set_cwd ( mut self, value: &'static str ) -> Self {

        self.cwd = value;
        self

    }

    pub const fn set_user ( mut self, value: &'static str ) -> Self {

        self.user = value;
        self

    }

    pub const fn set_group ( mut self, value: &'static str ) -> Self {

        self.group = value;
        self

    }

    pub const fn set_env ( mut self, value: &'static [(&'static str, &'static str)] ) -> Self {

        self.env = value;
        self

    }

    pub const fn set_restart ( mut self, value: &'static str ) -> Self {

        self.restart = value;
        self

    }

    pub const fn set_wanted_by ( mut self, value: &'static str ) -> Self {

        self.wanted_by = value;
        self

    }


    pub fn detect () -> Launcher {

        if Manager::is_windows() { return Launcher::Windows; }
        if Manager::is_macos() { if Manager::has("launchctl") { return Launcher::Launchd; } }

        if Manager::has("systemctl") { return Launcher::Systemd; }
        if Manager::has("rc-service") { return Launcher::OpenRc; }
        if Manager::has("service") { return Launcher::SysV; }

        Launcher::Unknown

    }

    pub fn file_name ( &self ) -> String {

        match Self::detect() {
            Launcher::Systemd => format!("{}.service", self.name),
            Launcher::Launchd => format!("{}.plist", self.name),
            _                 => self.name.to_string(),
        }

    }

    pub fn file_path ( &self ) -> String {

        match Self::detect() {
            Launcher::Systemd => format!("/etc/systemd/system/{}.service", self.name),
            Launcher::Launchd => format!("/Library/LaunchDaemons/{}.plist", self.name),
            Launcher::OpenRc  => format!("/etc/init.d/{}", self.name),
            Launcher::SysV    => format!("/etc/init.d/{}", self.name),
            Launcher::Windows => self.name.to_string(),
            Launcher::Unknown => self.name.to_string(),
        }

    }

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


    fn write_file ( path: &str, text: &str ) -> AppResult<()> {

        let temp_name = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map_err(|_| AppError::message("failed to build temp name"))?
            .as_nanos();

        let temp_file = std::env::temp_dir().join(format!("gun-{}-{}.tmp", std::process::id(), temp_name));
        let temp = temp_file.to_str().ok_or_else(|| AppError::message("invalid temp path"))?;

        std::fs::write(&temp_file, text)?;
        Manager::sudo_run("mv", &[temp, path])?;

        Ok(())

    }

    fn clean_text ( value: &str ) -> String {

        value
            .replace('\r', "")
            .replace('\n', " ")
            .trim()
            .to_string()

    }

    fn systemd_line ( text: &mut String, key: &str, value: &str ) {

        text.push_str(key);
        text.push_str(value);
        text.push('\n');

    }

    fn systemd_quote ( value: &str ) -> String {

        let value = Self::clean_text(value);

        if value.is_empty() { return String::new(); }
        if !value.contains([' ', '\t', '"', '\\']) { return value; }

        let mut out = String::with_capacity(value.len() + 8);

        out.push('"');

        for ch in value.chars() {

            match ch {
                '\\' => out.push_str("\\\\"),
                '"'  => out.push_str("\\\""),
                _    => out.push(ch),
            }

        }

        out.push('"');
        out

    }

    fn systemd_envs ( env: &[(&str, &str)] ) -> String {

        let mut text = String::new();

        for ( key, value ) in env {

            let key   = Self::clean_text(key);
            let value = Self::clean_text(value);

            if key.is_empty() { continue; }
            Self::systemd_line(&mut text, "Environment=", &Self::systemd_quote(&format!("{}={}", key, value)));

        }

        text

    }

    fn systemd_exec ( command: &str, args: &[&str] ) -> String {

        let mut line = Self::systemd_quote(command);

        for arg in args {

            line.push(' ');
            line.push_str(&Self::systemd_quote(arg));

        }

        line

    }

    fn install_systemd ( &self ) -> AppResult<()> {

        let mut text  = String::with_capacity(512);
        let file      = self.file_path();

        let envs      = Self::systemd_envs(self.env);
        let exec      = Self::systemd_exec(self.command, self.args);
        let cwd       = Self::systemd_quote(self.cwd);
        let user      = Self::clean_text(self.user);
        let group     = Self::clean_text(self.group);
        let kind      = Self::clean_text(self.kind);
        let desc      = Self::clean_text(if self.description.trim().is_empty() { self.name } else { self.description });
        let restart   = Self::clean_text(if self.restart.trim().is_empty() { "always" } else { self.restart });
        let wanted_by = Self::clean_text(if self.wanted_by.trim().is_empty() { "multi-user.target" } else { self.wanted_by });

        text.push_str("[Unit]\n");

        if !desc.is_empty() { Self::systemd_line(&mut text, "Description=", &desc); }

        text.push_str("\n[Service]\n");

        if !kind.is_empty() { Self::systemd_line(&mut text, "Type=", &kind); }
        if !exec.is_empty()     { Self::systemd_line(&mut text, "ExecStart=", &exec); }
        if !restart.is_empty()  { Self::systemd_line(&mut text, "Restart=", &restart); }
        if !cwd.is_empty()      { Self::systemd_line(&mut text, "WorkingDirectory=", &cwd); }
        if !user.is_empty()     { Self::systemd_line(&mut text, "User=", &user); }
        if !group.is_empty()    { Self::systemd_line(&mut text, "Group=", &group); }

        text.push_str(&envs);

        text.push_str("\n[Install]\n");

        if !wanted_by.is_empty() { Self::systemd_line(&mut text, "WantedBy=", &wanted_by); }

        Self::write_file(&file, &text)?;
        Manager::sudo_run("systemctl", &["daemon-reload"])?;
        Manager::sudo_run("systemctl", &["enable", self.name])?;

        Ok(())

    }

    fn uninstall_systemd ( &self ) -> AppResult<()> {

        let file = self.file_path();

        let _ = Manager::sudo_run("systemctl", &["disable", self.name]);
        let _ = Manager::sudo_run("systemctl", &["stop", self.name]);

        Manager::sudo_run("rm", &["-f", &file])?;
        Manager::sudo_run("systemctl", &["daemon-reload"])?;

        Ok(())

    }


    fn launchd_xml ( value: &str ) -> String {

        let mut out = String::with_capacity(value.len() + 16);

        for ch in Self::clean_text(value).chars() {

            match ch {
                '&'  => out.push_str("&amp;"),
                '<'  => out.push_str("&lt;"),
                '>'  => out.push_str("&gt;"),
                '"'  => out.push_str("&quot;"),
                '\'' => out.push_str("&apos;"),
                _    => out.push(ch),
            }

        }

        out

    }

    fn launchd_line ( text: &mut String, value: &str, tabs: usize ) {

        for _ in 0..tabs { text.push_str("    "); }

        text.push_str(value);
        text.push('\n');

    }

    fn launchd_string ( text: &mut String, value: &str, tabs: usize ) {

        Self::launchd_line(text, &format!("<string>{}</string>", Self::launchd_xml(value)), tabs);

    }

    fn install_launchd ( &self ) -> AppResult<()> {

        let mut text = String::with_capacity(512);
        let file     = self.file_path();

        let label    = Self::clean_text(self.name);
        let command  = Self::clean_text(self.command);
        let cwd      = Self::clean_text(self.cwd);
        let restart  = Self::clean_text(self.restart);

        text.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        text.push_str("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
        text.push_str("<plist version=\"1.0\">\n");

        Self::launchd_line(&mut text, "<dict>", 0);

        if !label.is_empty() {
            Self::launchd_line(&mut text, "<key>Label</key>", 1);
            Self::launchd_string(&mut text, &label, 1);
        }

        if !cwd.is_empty() {
            Self::launchd_line(&mut text, "<key>WorkingDirectory</key>", 1);
            Self::launchd_string(&mut text, &cwd, 1);
        }

        if !command.is_empty() {
            Self::launchd_line(&mut text, "<key>ProgramArguments</key>", 1);
            Self::launchd_line(&mut text, "<array>", 1);
            Self::launchd_string(&mut text, &command, 2);

            for arg in self.args {
                let arg = Self::clean_text(arg);
                if arg.is_empty() { continue; }
                Self::launchd_string(&mut text, &arg, 2);
            }

            Self::launchd_line(&mut text, "</array>", 1);
        }

        Self::launchd_line(&mut text, "<key>RunAtLoad</key>", 1);
        Self::launchd_line(&mut text, "<true/>", 1);

        if restart == "always" {
            Self::launchd_line(&mut text, "<key>KeepAlive</key>", 1);
            Self::launchd_line(&mut text, "<true/>", 1);
        }

        Self::launchd_line(&mut text, "</dict>", 0);
        Self::launchd_line(&mut text, "</plist>", 0);

        Self::write_file(&file, &text)?;
        Manager::sudo_run("launchctl", &["bootstrap", "system", &file])?;

        Ok(())

    }

    fn uninstall_launchd ( &self ) -> AppResult<()> {

        let file = self.file_path();

        let _ = Manager::sudo_run("launchctl", &["bootout", "system", &file]);
        Manager::sudo_run("rm", &["-f", &file])?;

        Ok(())

    }

}
