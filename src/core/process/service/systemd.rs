
use super::arch::{Service, Launcher, Manager, AppResult, AppError};

impl Service {

    fn clean_text ( value: &str ) -> String {

        value
            .replace('\r', "")
            .replace('\n', " ")
            .trim()
            .to_string()

    }

    fn line ( text: &mut String, key: &str, value: &str ) {

        text.push_str(key);
        text.push_str(value);
        text.push('\n');

    }

    fn quote ( value: &str ) -> String {

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

    fn envs ( env: &[(&str, &str)] ) -> String {

        let mut text = String::new();

        for ( key, value ) in env {

            let key   = Self::clean_text(key);
            let value = Self::clean_text(value);

            if key.is_empty() { continue; }
            Self::line(&mut text, "Environment=", &Self::quote(&format!("{}={}", key, value)));

        }

        text

    }

    fn exec ( command: &str, args: &[&str] ) -> String {

        let mut line = Self::quote(command);

        for arg in args {

            line.push(' ');
            line.push_str(&Self::quote(arg));

        }

        line

    }

    pub fn install_systemd ( &self ) -> AppResult<()> {

        let mut text  = String::with_capacity(512);

        let envs      = Self::envs(self.env);
        let exec      = Self::exec(self.command, self.args);
        let cwd       = Self::quote(self.cwd);
        let user      = Self::clean_text(self.user);
        let group     = Self::clean_text(self.group);
        let kind      = Self::clean_text(self.kind);
        let desc      = Self::clean_text(if self.description.trim().is_empty() { self.name } else { self.description });
        let restart   = Self::clean_text(if self.restart.trim().is_empty() { "always" } else { self.restart });
        let wanted_by = Self::clean_text(if self.wanted_by.trim().is_empty() { "multi-user.target" } else { self.wanted_by });

        text.push_str("[Unit]\n");

        if !desc.is_empty() { Self::line(&mut text, "Description=", &desc); }

        text.push_str("\n[Service]\n");

        if !kind.is_empty() { Self::line(&mut text, "Type=", &kind); }
        if !exec.is_empty()     { Self::line(&mut text, "ExecStart=", &exec); }
        if !restart.is_empty()  { Self::line(&mut text, "Restart=", &restart); }
        if !cwd.is_empty()      { Self::line(&mut text, "WorkingDirectory=", &cwd); }
        if !user.is_empty()     { Self::line(&mut text, "User=", &user); }
        if !group.is_empty()    { Self::line(&mut text, "Group=", &group); }

        text.push_str(&envs);

        text.push_str("\n[Install]\n");

        if !wanted_by.is_empty() { Self::line(&mut text, "WantedBy=", &wanted_by); }

        Self::write(&self.path(), &text)?;
        Manager::try_run("systemctl", &["daemon-reload"])?;
        Manager::try_run("systemctl", &["enable", self.name])?;

        Ok(())

    }

    pub fn uninstall_systemd ( &self ) -> AppResult<()> {

        let _ = Manager::try_run("systemctl", &["disable", self.name]);
        let _ = Manager::try_run("systemctl", &["stop", self.name]);

        Manager::try_run("rm", &["-f", &self.path()])?;
        Manager::try_run("systemctl", &["daemon-reload"])?;

        Ok(())

    }

}
