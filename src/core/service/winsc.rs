
use super::arch::{Winsc, Spec, Kind, Restart, Manager, AppResult};

impl Winsc {

    fn kind ( kind: Kind ) -> &'static str {

        match kind {
            Kind::Shared => "share",
            _            => "own",
        }

    }

    fn clean ( value: &str ) -> String {

        value.replace('\r', "").replace('\n', " ").replace('\0', " ").trim().to_string()

    }

    fn quote ( value: &str ) -> String {

        let value = Self::clean(value);
        if value.is_empty() { return String::new(); }

        let mut out = String::with_capacity(value.len() + 2);
        out.push('"');

        for ch in value.chars() {

            match ch {
                '"' => out.push_str("\\\""),
                _   => out.push(ch),
            }

        }

        out.push('"');
        out

    }

    fn exec ( command: &str, args: &[&str] ) -> String {

        let command = Self::clean(command);
        if command.is_empty() { return String::new(); }

        let mut parts = vec![Self::quote(&command)];

        for arg in args {

            let arg = Self::clean(arg);
            if arg.is_empty() { continue; }

            parts.push(Self::quote(&arg));

        }

        parts.join(" ")

    }

    fn push_pair ( args: &mut Vec<String>, key: &str, value: &str ) {

        let value = Self::clean(value);
        if value.is_empty() { return; }

        args.push(format!("{}= {}", key, value));

    }

    fn push_list ( args: &mut Vec<String>, key: &str, values: &[&str] ) {

        let values: Vec<String> = values.iter().map(|v| Self::clean(v)).filter(|v| !v.is_empty()).collect();
        if values.is_empty() { return; }

        Self::push_pair(args, key, &values.join("/"));

    }

    pub fn install ( spec: Spec ) -> AppResult<()> {

        let name = Self::clean(spec.name);
        let desc = Self::clean(spec.description);

        let mut args = vec!["create".to_string(), name.clone()];

        Self::push_pair(&mut args, "displayname", &name);
        Self::push_pair(&mut args, "binPath", &Self::exec(spec.command, spec.args));
        Self::push_pair(&mut args, "type", Self::kind(spec.kind));
        Self::push_pair(&mut args, "start", spec.start_type);
        Self::push_pair(&mut args, "error", spec.error_control);
        Self::push_pair(&mut args, "obj", &spec.account);
        Self::push_pair(&mut args, "password", &spec.password);
        Self::push_list(&mut args, "depend", spec.dependencies);

        let argv: Vec<&str> = args.iter().map(|v| v.as_str()).collect();

        Manager::try_run("sc", &argv)?;
        Manager::try_run("sc", &["description", &name, if desc.is_empty() { &name } else { &desc }])?;

        match spec.restart {
            Restart::Always | Restart::OnFailure => {
                let reset = format!("reset= {}", spec.start_timeout.to_string());
                let actions = format!("actions= restart/{0}/restart/{0}/restart/{0}", spec.restart_delay);

                let args = vec!["failure".to_string(), name.clone(), reset, actions];
                let argv: Vec<&str> = args.iter().map(|v| v.as_str()).collect();

                Manager::try_run("sc", &argv)?;
                Manager::try_run("sc", &["failureflag", &name, "flag= 1"])?;
            }
            _ => {
                let _ = Manager::try_run("sc", &["failure", &name, "reset= 0", "actions= "]);
                let _ = Manager::try_run("sc", &["failureflag", &name, "flag= 0"]);
            }
        }

        Ok(())

    }

    pub fn remove ( name: &str ) -> AppResult<()> {

        let _ = Manager::try_run("sc", &["stop", &name]);
        let _ = Manager::try_run("sc", &["delete", &name]);

        Ok(())

    }

}
