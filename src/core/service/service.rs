
use super::arch::{Service, Launcher, Spec, Kind, Restart};

impl Service {

    pub const fn new () -> Self {

        Self {
            windows : Spec::new(),
            launchd : Spec::new(),
            systemd : Spec::new(),
        }

    }

    pub const fn set_kind ( mut self, value: Kind ) -> Self {

        self.windows = self.windows.set_kind(value);
        self.launchd = self.launchd.set_kind(value);
        self.systemd = self.systemd.set_kind(value);

        self

    }

    pub const fn set_restart ( mut self, value: Restart ) -> Self {

        self.windows = self.windows.set_restart(value);
        self.launchd = self.launchd.set_restart(value);
        self.systemd = self.systemd.set_restart(value);

        self

    }

    pub const fn set_name ( mut self, value: &'static str ) -> Self {

        self.windows = self.windows.set_name(value);
        self.launchd = self.launchd.set_name(value);
        self.systemd = self.systemd.set_name(value);

        self

    }

    pub const fn set_description ( mut self, value: &'static str ) -> Self {

        self.windows = self.windows.set_description(value);
        self.launchd = self.launchd.set_description(value);
        self.systemd = self.systemd.set_description(value);

        self

    }

    pub const fn register ( mut self, launcher: Launcher, spec: Spec ) -> Self {

        match launcher {
            Launcher::Windows => self.windows = self.windows.merge(spec),
            Launcher::Launchd => self.launchd = self.launchd.merge(spec),
            Launcher::Systemd => self.systemd = self.systemd.merge(spec),
        };

        self

    }

    pub const fn register_windows ( self, spec: Spec ) -> Self {

        self.register(Launcher::Windows, spec)

    }

    pub const fn register_macos ( self, spec: Spec ) -> Self {

        self.register(Launcher::Launchd, spec)

    }

    pub const fn register_linux ( self, spec: Spec ) -> Self {

        self.register(Launcher::Systemd, spec)

    }

    pub const fn register_unix ( self, spec: Spec ) -> Self {

        self.register_linux(spec).register_macos(spec)

    }

}
