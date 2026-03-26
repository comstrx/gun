
use super::arch::{Service, Spec, Kind, Restart, Manager, AppResult};

impl Service {

    fn kind ( kind: Kind ) -> &'static str {

        match kind {
            Kind::Simple  => "simple",
            Kind::Forking => "forking",
            Kind::Oneshot => "oneshot",
            Kind::Notify  => "notify",
            Kind::Shared  => "share",
            Kind::Owned   => "own",
        }

    }

    fn event ( restart: Restart ) -> &'static str {

        match restart {
            Restart::OnAbort   => "on-abort",
            Restart::OnFailure => "on-failure",
            Restart::OnSuccess => "on-success",
            Restart::Always    => "always",
            Restart::Never     => "no",
        }

    }

    fn clean ( value: &str ) -> String {

        value.replace('\r', "").replace('\n', " ").trim().to_string()

    }

    fn quote ( value: &str ) -> String {

        let value = Self::clean(value);

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

    fn exec ( command: &str, args: &[&str] ) -> String {

        let mut line = Self::quote(command);

        for arg in args {

            let arg = Self::clean(arg);
            if arg.is_empty() { continue; }

            line.push(' ');
            line.push_str(&Self::quote(&arg));

        }

        line

    }

    pub fn windows_install ( spec: Spec ) -> AppResult<()> {

        let name = Self::clean(spec.name);
        let path = Self::exec(spec.command, spec.args);
        let kind   = Self::kind(spec.kind);

        Manager::try_run("sc", &["create", &name, &format!("type= {}", kind), &format!("binPath= {}", path)])?;
        Manager::try_run("sc", &["description", &name, &Self::clean(spec.description)])?;

        match spec.restart {
            Restart::Always | Restart::OnFailure => {
                Manager::try_run("sc", &["failure", &name, "reset= 86400", "actions= restart/5000/restart/5000/restart/5000"])?;
                let _ = Manager::try_run("sc", &["failureflag", &name, "1"]);
            }
            _ => {
                let _ = Manager::try_run("sc", &["failure", &name, "reset= 0", "actions= "]);
                let _ = Manager::try_run("sc", &["failureflag", &name, "0"]);
            }
        }

        Ok(())

    }

    pub fn windows_remove ( name: &str ) -> AppResult<()> {

        let _ = Manager::try_run("sc", &["stop", &name]);
        let _ = Manager::try_run("sc", &["delete", &name]);

        Ok(())

    }


    fn launchd_xml ( value: &str ) -> String {

        let mut out = String::with_capacity(value.len() + 16);

        for ch in Self::clean(value).chars() {

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
        text.push_str(format!("{}\n", value).as_str());

    }

    fn launchd_tag ( text: &mut String, value: &str, tabs: usize ) {

        Self::launchd_line(text, &format!("<string>{}</string>", Self::launchd_xml(value)), tabs);

    }

    pub fn launchd_install ( spec: Spec ) -> AppResult<()> {

        let mut text = String::with_capacity(512);
        let path = format!("/Library/LaunchDaemons/{}.plist", spec.name);

        let name    = Self::clean(spec.name);
        let cwd     = Self::clean(spec.cwd);
        let command = Self::clean(spec.command);

        text.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        text.push_str("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
        text.push_str("<plist version=\"1.0\">\n");

        Self::launchd_line(&mut text, "<dict>", 0);

        Self::launchd_line(&mut text, "<key>RunAtLoad</key>", 1);
        Self::launchd_line(&mut text, "<true/>", 1);

        Self::launchd_line(&mut text, "<key>Label</key>", 1);
        Self::launchd_tag(&mut text, &name, 1);

        if !cwd.is_empty() {

            Self::launchd_line(&mut text, "<key>WorkingDirectory</key>", 1);
            Self::launchd_tag(&mut text, &cwd, 1);

        }

        if !command.is_empty() {

            Self::launchd_line(&mut text, "<key>ProgramArguments</key>", 1);
            Self::launchd_line(&mut text, "<array>", 1);
            Self::launchd_tag(&mut text, &command, 2);

            for arg in spec.args { Self::launchd_tag(&mut text, &Self::clean(arg), 2); }

            Self::launchd_line(&mut text, "</array>", 1);

        }

        if spec.restart == Restart::Always {
            Self::launchd_line(&mut text, "<key>KeepAlive</key>", 1);
            Self::launchd_line(&mut text, "<true/>", 1);
        }

        Self::launchd_line(&mut text, "</dict>", 0);
        Self::launchd_line(&mut text, "</plist>", 0);

        std::fs::write(&path, &text)?;
        Manager::try_run("launchctl", &["bootstrap", "system", &path])

    }

    pub fn launchd_remove ( name: &str ) -> AppResult<()> {

        let path = format!("/Library/LaunchDaemons/{}.plist", name);

        let _ = Manager::try_run("launchctl", &["bootout", "system", &path]);
        let _ = Manager::try_run("rm", &["-f", &path]);

        Ok(())

    }


    fn systemd_env ( text: &mut String, env: &'static [(&'static str, &'static str)] ) {

        for ( key, value ) in env {

            let value = Self::quote(&format!("{}={}", Self::clean(key), Self::clean(value)));
            text.push_str(format!("Environment={}\n", value).as_str());

        }

    }

    fn systemd_line ( text: &mut String, key: &str, value: &str ) {

        let value = Self::clean(value);
        if !value.is_empty() { text.push_str(format!("{}={}\n", key, value).as_str()); }

    }

    fn systemd_tag ( text: &mut String, value: &str ) {

        let value = Self::clean(value);
        if !value.is_empty() { text.push_str(format!("\n[{}]\n", value).as_str()); }

    }

    pub fn systemd_install ( spec: Spec ) -> AppResult<()> {

        let mut text = String::with_capacity(512);
        let path = format!("/etc/systemd/system/{}.service", spec.name);

        Self::systemd_tag(&mut text, "Unit");
        Self::systemd_line(&mut text, "Description", spec.description);

        Self::systemd_tag(&mut text, "Service");
        Self::systemd_line(&mut text, "Type", Self::kind(spec.kind));
        Self::systemd_line(&mut text, "Restart", Self::event(spec.restart));
        Self::systemd_line(&mut text, "ExecStart", &Self::exec(spec.command, spec.args));
        Self::systemd_line(&mut text, "WorkingDirectory", &Self::quote(spec.cwd));
        Self::systemd_line(&mut text, "User", spec.user);
        Self::systemd_line(&mut text, "Group", spec.group);
        Self::systemd_env(&mut text, spec.env);

        Self::systemd_tag(&mut text, "Install");
        Self::systemd_line(&mut text, "WantedBy", spec.wanted_by);

        std::fs::write(&path, &text)?;

        Manager::try_run("systemctl", &["daemon-reload"])?;
        Manager::try_run("systemctl", &["enable", spec.name])

    }

    pub fn systemd_remove ( name: &str ) -> AppResult<()> {

        let path = format!("/etc/systemd/system/{}.service", name);

        let _ = Manager::try_run("systemctl", &["disable", name]);
        let _ = Manager::try_run("systemctl", &["stop", name]);
        let _ = Manager::try_run("rm", &["-f", &path]);
        let _ = Manager::try_run("systemctl", &["daemon-reload"]);

        Ok(())

    }

}
