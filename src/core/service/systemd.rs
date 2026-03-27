
use super::arch::{Systemd, Spec, Kind, Restart, Manager, AppResult};

impl Systemd {

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

    fn systemd_tag ( text: &mut String, value: &str ) {

        let value = Self::clean(value);
        if value.is_empty() { return; }

        if !text.is_empty() { text.push('\n'); }
        text.push_str(format!("[{}]\n", value).as_str());

    }

    fn systemd_line ( text: &mut String, key: &str, value: &str ) {

        let value = Self::clean(value);
        if value.is_empty() { return; }

        text.push_str(format!("{}={}\n", key, value).as_str());

    }

    fn systemd_uline ( text: &mut String, key: &str, value: u64 ) {

        if value > 0 { Self::systemd_line(text, key, &value.to_string()); }

    }

    fn systemd_out ( text: &mut String, key: &str, path: &str ) {

        let value = Self::clean(path);
        if value.is_empty() { return; }

        text.push_str(format!("{}=append:{}\n", key, value).as_str());

    }

    fn systemd_list ( text: &mut String, key: &str, values: &[&str] ) {

        let values: Vec<&str> = values.iter().copied().filter(|v| !v.trim().is_empty()).collect();
        if values.is_empty() { return; }

        text.push_str(format!("{}={}\n", key, values.join(" ")).as_str());

    }

    fn systemd_env ( text: &mut String, value: &'static [(&'static str, &'static str)] ) {

        for ( left, right ) in value {

            let left  = Self::clean(left);
            let right = Self::clean(right);

            if left.is_empty() || right.is_empty() { continue; }
            text.push_str(format!("Environment={}\n", Self::quote(&format!("{}={}", left, right))).as_str());

        }

    }

    pub fn install ( spec: Spec ) -> AppResult<()> {

        let mut text = String::with_capacity(1024);
        let path = format!("/etc/systemd/system/{}.service", spec.name);

        let after  = if spec.dependencies.is_empty() { &["network.target"] } else { spec.dependencies };
        let wanted = if spec.wanted_by.is_empty() { &["multi-user.target"] } else { spec.wanted_by };

        Self::systemd_tag(&mut text, "Unit");
        Self::systemd_line(&mut text, "Description", spec.description);
        Self::systemd_list(&mut text, "Wants", spec.dependencies);
        Self::systemd_list(&mut text, "After", after);

        Self::systemd_tag(&mut text, "Service");
        Self::systemd_line(&mut text, "SyslogIdentifier", spec.name);
        Self::systemd_line(&mut text, "Type", Self::kind_str(spec.kind));
        Self::systemd_line(&mut text, "Restart", Self::restart_str(spec.restart));
        Self::systemd_line(&mut text, "ExecStart", &Self::exec(spec.command, spec.args));
        Self::systemd_line(&mut text, "WorkingDirectory", &Self::quote(spec.cwd));
        Self::systemd_line(&mut text, "RuntimeDirectory", spec.runtime_directory);
        Self::systemd_line(&mut text, "LogsDirectory", spec.logs_directory);
        Self::systemd_out(&mut text, "StandardOutput", spec.stdout_path);
        Self::systemd_out(&mut text, "StandardError", spec.stderr_path);

        Self::systemd_env(&mut text, spec.env);
        Self::systemd_line(&mut text, "PIDFile", spec.pid_file);
        Self::systemd_line(&mut text, "User", spec.user);
        Self::systemd_line(&mut text, "Group", spec.group);
        Self::systemd_line(&mut text, "UMask", spec.umask);

        Self::systemd_line(&mut text, "MemoryMax", spec.memory_limit);
        Self::systemd_line(&mut text, "KillSignal", spec.kill_signal);
        Self::systemd_uline(&mut text, "RestartSec", spec.restart_delay);
        Self::systemd_uline(&mut text, "TimeoutStartSec", spec.start_timeout);
        Self::systemd_uline(&mut text, "TimeoutStopSec", spec.stop_timeout);
        Self::systemd_uline(&mut text, "LimitNOFILE", spec.file_limit);
        Self::systemd_uline(&mut text, "LimitNPROC", spec.process_limit);
        Self::systemd_uline(&mut text, "TasksMax", spec.task_limit);

        Self::systemd_line(&mut text, "NoNewPrivileges", "true");
        Self::systemd_line(&mut text, "PrivateTmp", "true");
        Self::systemd_line(&mut text, "ProtectHome", "true");
        Self::systemd_line(&mut text, "ProtectSystem", "full");
        Self::systemd_line(&mut text, "ProtectKernelTunables", "true");
        Self::systemd_line(&mut text, "ProtectKernelModules", "true");
        Self::systemd_line(&mut text, "ProtectControlGroups", "true");
        Self::systemd_line(&mut text, "ProtectKernelLogs", "true");
        Self::systemd_line(&mut text, "ProtectHostname", "true");
        Self::systemd_line(&mut text, "RestrictSUIDSGID", "true");
        Self::systemd_line(&mut text, "LockPersonality", "true");
        Self::systemd_line(&mut text, "SystemCallFilter", "@system-service");
        Self::systemd_line(&mut text, "LimitCORE", "0");

        Self::systemd_tag(&mut text, "Install");
        Self::systemd_list(&mut text, "WantedBy", wanted);

        std::fs::write(&path, &text)?;
        Manager::try_run("systemctl", &["daemon-reload"])?;

        if spec.auto_start {
            Manager::try_run("systemctl", &["enable", spec.name])?;
            Manager::try_run("systemctl", &["restart", spec.name])?;
        }

        Ok(())

    }

    pub fn remove ( name: &str ) -> AppResult<()> {

        let path = format!("/etc/systemd/system/{}.service", name);

        let _ = Manager::try_run("systemctl", &["disable", name]);
        let _ = Manager::try_run("systemctl", &["stop", name]);

        let _ = std::fs::remove_file(&path);
        let _ = Manager::try_run("systemctl", &["daemon-reload"]);

        Ok(())

    }

}
