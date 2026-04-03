
use super::arch::{Manager, Tool, Spec};

impl Tool {

    pub const fn new () -> Self {

        Self {
            apt    : Spec::new(),
            apk    : Spec::new(),
            dnf    : Spec::new(),
            yum    : Spec::new(),
            nix    : Spec::new(),
            pacman : Spec::new(),
            zypper : Spec::new(),
            brew   : Spec::new(),
            winget : Spec::new(),
            scoop  : Spec::new(),
            choco  : Spec::new(),
        }

    }

    pub const fn set_bin ( mut self, value: &'static str ) -> Self {

        self.apt    = self.apt.set_bin(value);
        self.apk    = self.apk.set_bin(value);
        self.dnf    = self.dnf.set_bin(value);
        self.yum    = self.yum.set_bin(value);
        self.nix    = self.nix.set_bin(value);
        self.pacman = self.pacman.set_bin(value);
        self.zypper = self.zypper.set_bin(value);
        self.brew   = self.brew.set_bin(value);
        self.winget = self.winget.set_bin(value);
        self.scoop  = self.scoop.set_bin(value);
        self.choco  = self.choco.set_bin(value);

        self

    }

    pub const fn set_version ( mut self, value : &'static str ) -> Self {

        self.apt    = self.apt.set_version(value);
        self.apk    = self.apk.set_version(value);
        self.dnf    = self.dnf.set_version(value);
        self.yum    = self.yum.set_version(value);
        self.nix    = self.nix.set_version(value);
        self.pacman = self.pacman.set_version(value);
        self.zypper = self.zypper.set_version(value);
        self.brew   = self.brew.set_version(value);
        self.winget = self.winget.set_version(value);
        self.scoop  = self.scoop.set_version(value);
        self.choco  = self.choco.set_version(value);

        self

    }

    pub const fn set_aliases ( mut self, value : &'static [&'static str] ) -> Self {

        self.apt    = self.apt.set_aliases(value);
        self.apk    = self.apk.set_aliases(value);
        self.dnf    = self.dnf.set_aliases(value);
        self.yum    = self.yum.set_aliases(value);
        self.nix    = self.nix.set_aliases(value);
        self.pacman = self.pacman.set_aliases(value);
        self.zypper = self.zypper.set_aliases(value);
        self.brew   = self.brew.set_aliases(value);
        self.winget = self.winget.set_aliases(value);
        self.scoop  = self.scoop.set_aliases(value);
        self.choco  = self.choco.set_aliases(value);

        self

    }

    pub const fn register ( mut self, manager: Manager, spec: Spec ) -> Self {

        match manager {
            Manager::Apt    => self.apt    = self.apt.merge(spec),
            Manager::Apk    => self.apk    = self.apk.merge(spec),
            Manager::Dnf    => self.dnf    = self.dnf.merge(spec),
            Manager::Yum    => self.yum    = self.yum.merge(spec),
            Manager::Nix    => self.nix    = self.nix.merge(spec),
            Manager::Pacman => self.pacman = self.pacman.merge(spec),
            Manager::Zypper => self.zypper = self.zypper.merge(spec),
            Manager::Brew   => self.brew   = self.brew.merge(spec),
            Manager::Winget => self.winget = self.winget.merge(spec),
            Manager::Scoop  => self.scoop  = self.scoop.merge(spec),
            Manager::Choco  => self.choco  = self.choco.merge(spec),
        };

        self

    }

    pub const fn register_windows ( self, spec: Spec ) -> Self {

        self.register(Manager::Winget, spec)
            .register(Manager::Scoop, spec)
            .register(Manager::Choco, spec)

    }

    pub const fn register_linux ( self, spec: Spec ) -> Self {

        self.register(Manager::Apt, spec)
            .register(Manager::Apk, spec)
            .register(Manager::Dnf, spec)
            .register(Manager::Yum, spec)
            .register(Manager::Nix, spec)
            .register(Manager::Pacman, spec)
            .register(Manager::Zypper, spec)

    }

    pub const fn register_macos ( self, spec: Spec ) -> Self {

        self.register(Manager::Brew, spec)

    }

    pub const fn register_unix ( self, spec: Spec ) -> Self {

        self.register_linux(spec).register_macos(spec)

    }

}
