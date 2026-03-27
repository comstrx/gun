
use super::arch::{Service, Provider, Spec, Kind, Restart};

impl Service {

    pub const fn new () -> Self {

        Self {
            launchd : Spec::new(),
            systemd : Spec::new(),
            winsc   : Spec::new(),
        }

    }

    pub const fn set_kind ( mut self, value: Kind ) -> Self {

        self.systemd = self.systemd.set_kind(value);
        self.launchd = self.launchd.set_kind(value);
        self.winsc   = self.winsc.set_kind(value);

        self

    }

    pub const fn set_restart ( mut self, value: Restart ) -> Self {

        self.systemd = self.systemd.set_restart(value);
        self.launchd = self.launchd.set_restart(value);
        self.winsc   = self.winsc.set_restart(value);

        self

    }

    pub const fn set_name ( mut self, value: &'static str ) -> Self {

        self.systemd = self.systemd.set_name(value);
        self.launchd = self.launchd.set_name(value);
        self.winsc   = self.winsc.set_name(value);

        self

    }

    pub const fn set_description ( mut self, value: &'static str ) -> Self {

        self.systemd = self.systemd.set_description(value);
        self.launchd = self.launchd.set_description(value);
        self.winsc   = self.winsc.set_description(value);

        self

    }

    pub const fn register ( mut self, provider: Provider, spec: Spec ) -> Self {

        match provider {
            Provider::Systemd => self.systemd = self.systemd.merge(spec),
            Provider::Launchd => self.launchd = self.launchd.merge(spec),
            Provider::Winsc   => self.winsc   = self.winsc.merge(spec),
        };

        self

    }

    pub const fn register_windows ( self, spec: Spec ) -> Self {

        self.register(Provider::Winsc, spec)

    }

    pub const fn register_macos ( self, spec: Spec ) -> Self {

        self.register(Provider::Launchd, spec)

    }

    pub const fn register_linux ( self, spec: Spec ) -> Self {

        self.register(Provider::Systemd, spec)

    }

    pub const fn register_unix ( self, spec: Spec ) -> Self {

        self.register_linux(spec).register_macos(spec)

    }

}
