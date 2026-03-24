
use super::arch::{Service, Launcher, Manager, AppResult, AppError};

impl Service {

    fn clean_text ( value: &str ) -> String {

        value
            .replace('\r', "")
            .replace('\n', " ")
            .trim()
            .to_string()

    }

    fn line ( text: &mut String, value: &str, tabs: usize ) {

        for _ in 0..tabs { text.push_str("    "); }

        text.push_str(value);
        text.push('\n');

    }

    fn xml ( value: &str ) -> String {

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

    fn tag ( text: &mut String, value: &str, tabs: usize ) {

        Self::line(text, &format!("<string>{}</string>", Self::xml(value)), tabs);

    }

    pub fn install_launchd ( &self ) -> AppResult<()> {

        let mut text = String::with_capacity(512);

        let label    = Self::clean_text(self.name);
        let command  = Self::clean_text(self.command);
        let cwd      = Self::clean_text(self.cwd);
        let restart  = Self::clean_text(self.restart);

        text.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        text.push_str("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
        text.push_str("<plist version=\"1.0\">\n");

        Self::line(&mut text, "<dict>", 0);

        if !label.is_empty() {
            Self::line(&mut text, "<key>Label</key>", 1);
            Self::tag(&mut text, &label, 1);
        }

        if !cwd.is_empty() {
            Self::line(&mut text, "<key>WorkingDirectory</key>", 1);
            Self::tag(&mut text, &cwd, 1);
        }

        if !command.is_empty() {
            Self::line(&mut text, "<key>ProgramArguments</key>", 1);
            Self::line(&mut text, "<array>", 1);
            Self::tag(&mut text, &command, 2);

            for arg in self.args {
                let arg = Self::clean_text(arg);
                if arg.is_empty() { continue; }
                Self::tag(&mut text, &arg, 2);
            }

            Self::line(&mut text, "</array>", 1);
        }

        Self::line(&mut text, "<key>RunAtLoad</key>", 1);
        Self::line(&mut text, "<true/>", 1);

        if restart == "always" {
            Self::line(&mut text, "<key>KeepAlive</key>", 1);
            Self::line(&mut text, "<true/>", 1);
        }

        Self::line(&mut text, "</dict>", 0);
        Self::line(&mut text, "</plist>", 0);

        Self::write(&self.path(), &text)?;
        Manager::sudo_run("launchctl", &["bootstrap", "system", &self.path()])?;

        Ok(())

    }

    pub fn uninstall_launchd ( &self ) -> AppResult<()> {

        let _ = Manager::try_run("launchctl", &["bootout", "system", &self.path()]);
        Manager::try_run("rm", &["-f", &self.path()])?;

        Ok(())

    }

}
