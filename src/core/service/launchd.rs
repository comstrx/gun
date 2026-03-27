
use super::arch::{Launchd, Spec, Kind, Restart, Manager, AppResult};

impl Launchd {

    fn kind_str ( kind: Kind ) -> &'static str {

        match kind {
            Kind::Simple  => "simple",
            Kind::Forking => "forking",
            Kind::Oneshot => "oneshot",
            Kind::Notify  => "notify",
            Kind::Shared  => "share",
            Kind::Owned   => "own",
        }

    }

    fn restart_str ( restart: Restart ) -> &'static str {

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

        let value = Self::clean(value);
        if value.is_empty() { return; }

        Self::launchd_line(text, &format!("<string>{}</string>", Self::launchd_xml(&value)), tabs);

    }

    fn launchd_string ( text: &mut String, key: &str, value: &str, tabs: usize ) {

        let value = Self::clean(value);
        if value.is_empty() { return; }

        Self::launchd_line(text, &format!("<key>{}</key>", Self::launchd_xml(key)), tabs);
        Self::launchd_line(text, &format!("<string>{}</string>", Self::launchd_xml(&value)), tabs);

    }

    fn launchd_bool ( text: &mut String, key: &str, value: bool, tabs: usize ) {

        if value {
            Self::launchd_line(text, &format!("<key>{}</key>", Self::launchd_xml(key)), tabs);
            Self::launchd_line(text, "<true/>", tabs);
        }

    }

    fn launchd_num ( text: &mut String, key: &str, value: u64, tabs: usize ) {

        if value > 0 {
            Self::launchd_line(text, &format!("<key>{}</key>", Self::launchd_xml(key)), tabs);
            Self::launchd_line(text, &format!("<integer>{}</integer>", value), tabs);
        }

    }

    fn launchd_env ( text: &mut String, value: &'static [(&'static str, &'static str)], tabs: usize ) {

        let mut has_env = false;

        for ( left, right ) in value {

            let left  = Self::clean(left);
            let right = Self::clean(right);

            if left.is_empty() || right.is_empty() { continue; }

            if !has_env {

                Self::launchd_line(text, "<key>EnvironmentVariables</key>", tabs);
                Self::launchd_line(text, "<dict>", tabs);

                has_env = true;

            }

            Self::launchd_line(text, &format!("<key>{}</key>", Self::launchd_xml(&left)), tabs + 1);
            Self::launchd_line(text, &format!("<string>{}</string>", Self::launchd_xml(&right)), tabs + 1);

        }

        if has_env { Self::launchd_line(text, "</dict>", tabs); }

    }

    fn launchd_limits ( text: &mut String, files: u64, processes: u64, tabs: usize ) {

        if files <= 0 && processes <= 0 { return; }

        Self::launchd_line(text, "<key>SoftResourceLimits</key>", tabs);
        Self::launchd_line(text, "<dict>", tabs);

        if files > 0 {
            Self::launchd_line(text, "<key>NumberOfFiles</key>", tabs + 1);
            Self::launchd_line(text, &format!("<integer>{}</integer>", files), tabs + 1);
        }

        if processes > 0 {
            Self::launchd_line(text, "<key>NumberOfProcesses</key>", tabs + 1);
            Self::launchd_line(text, &format!("<integer>{}</integer>", processes), tabs + 1);
        }

        Self::launchd_line(text, "</dict>", tabs);

        Self::launchd_line(text, "<key>HardResourceLimits</key>", tabs);
        Self::launchd_line(text, "<dict>", tabs);

        if files > 0 {
            Self::launchd_line(text, "<key>NumberOfFiles</key>", tabs + 1);
            Self::launchd_line(text, &format!("<integer>{}</integer>", files), tabs + 1);
        }

        if processes > 0 {
            Self::launchd_line(text, "<key>NumberOfProcesses</key>", tabs + 1);
            Self::launchd_line(text, &format!("<integer>{}</integer>", processes), tabs + 1);
        }

        Self::launchd_line(text, "</dict>", tabs);


    }

    pub fn install ( spec: Spec ) -> AppResult<()> {

        let mut text = String::with_capacity(2048);
        let path = format!("/Library/LaunchDaemons/{}.plist", spec.name);

        let umask = u64::from_str_radix(spec.umask, 8).unwrap_or(0);
        let keep_alive = matches!(spec.restart, Restart::Always);

        Self::launchd_line(&mut text, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>", 0);
        Self::launchd_line(&mut text, "<plist version=\"1.0\">", 0);
        Self::launchd_line(&mut text, "<dict>", 0);

        Self::launchd_bool(&mut text, "RunAtLoad", spec.auto_start, 1);
        Self::launchd_bool(&mut text, "KeepAlive", keep_alive, 1);

        Self::launchd_string(&mut text, "Label", spec.name, 1);
        Self::launchd_string(&mut text, "WorkingDirectory", spec.cwd, 1);
        Self::launchd_string(&mut text, "UserName", spec.user, 1);
        Self::launchd_string(&mut text, "GroupName", spec.group, 1);
        Self::launchd_string(&mut text, "StandardOutPath", spec.stdout_path, 1);
        Self::launchd_string(&mut text, "StandardErrorPath", spec.stderr_path, 1);

        Self::launchd_env(&mut text, spec.env, 1);
        Self::launchd_limits(&mut text, spec.file_limit, spec.process_limit, 1);

        Self::launchd_num(&mut text, "Umask", umask, 1);
        Self::launchd_num(&mut text, "TimeOut", spec.start_timeout, 1);
        Self::launchd_num(&mut text, "ThrottleInterval", spec.restart_delay, 1);

        if !spec.command.is_empty() {

            Self::launchd_line(&mut text, "<key>ProgramArguments</key>", 1);
            Self::launchd_line(&mut text, "<array>", 1);
            Self::launchd_tag(&mut text, spec.command, 2);

            for arg in spec.args { Self::launchd_tag(&mut text, arg, 2); }
            Self::launchd_line(&mut text, "</array>", 1);

        }

        Self::launchd_line(&mut text, "</dict>", 0);
        Self::launchd_line(&mut text, "</plist>", 0);

        let _ = Manager::try_run("launchctl", &["bootout", "system", &path]);

        std::fs::write(&path, text)?;
        Manager::try_run("launchctl", &["bootstrap", "system", &path])?;

        Ok(())

    }

    pub fn remove ( name: &str ) -> AppResult<()> {

        let path = format!("/Library/LaunchDaemons/{}.plist", name);

        let _ = Manager::try_run("launchctl", &["bootout", "system", &path]);
        let _ = std::fs::remove_file(&path);

        Ok(())

    }

}
