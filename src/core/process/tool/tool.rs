
use super::arch::{Tool, Spec, Manager};

impl Tool {

    pub const fn new () -> Self {

        Self {
            apt    : Spec::new(),
            apk    : Spec::new(),
            dnf    : Spec::new(),
            yum    : Spec::new(),
            pacman : Spec::new(),
            zypper : Spec::new(),
            brew   : Spec::new(),
            winget : Spec::new(),
            scoop  : Spec::new(),
            choco  : Spec::new(),
        }

    }

    pub const fn set_bin ( mut self, bin: &'static str ) -> Self {

        self.apt    = self.apt.set_bin(bin);
        self.apk    = self.apk.set_bin(bin);
        self.dnf    = self.dnf.set_bin(bin);
        self.yum    = self.yum.set_bin(bin);
        self.pacman = self.pacman.set_bin(bin);
        self.zypper = self.zypper.set_bin(bin);
        self.brew   = self.brew.set_bin(bin);
        self.winget = self.winget.set_bin(bin);
        self.scoop  = self.scoop.set_bin(bin);
        self.choco  = self.choco.set_bin(bin);

        self

    }

    pub const fn set_name ( mut self, name : &'static str ) -> Self {

        self.apt    = self.apt.set_name(name);
        self.apk    = self.apk.set_name(name);
        self.dnf    = self.dnf.set_name(name);
        self.yum    = self.yum.set_name(name);
        self.pacman = self.pacman.set_name(name);
        self.zypper = self.zypper.set_name(name);
        self.brew   = self.brew.set_name(name);
        self.winget = self.winget.set_name(name);
        self.scoop  = self.scoop.set_name(name);
        self.choco  = self.choco.set_name(name);

        self

    }

    pub const fn set_version ( mut self, version : &'static str ) -> Self {

        self.apt    = self.apt.set_version(version);
        self.apk    = self.apk.set_version(version);
        self.dnf    = self.dnf.set_version(version);
        self.yum    = self.yum.set_version(version);
        self.pacman = self.pacman.set_version(version);
        self.zypper = self.zypper.set_version(version);
        self.brew   = self.brew.set_version(version);
        self.winget = self.winget.set_version(version);
        self.scoop  = self.scoop.set_version(version);
        self.choco  = self.choco.set_version(version);

        self

    }

    pub const fn set_aliases ( mut self, aliases : &'static [&'static str] ) -> Self {

        self.apt    = self.apt.set_aliases(aliases);
        self.apk    = self.apk.set_aliases(aliases);
        self.dnf    = self.dnf.set_aliases(aliases);
        self.yum    = self.yum.set_aliases(aliases);
        self.pacman = self.pacman.set_aliases(aliases);
        self.zypper = self.zypper.set_aliases(aliases);
        self.brew   = self.brew.set_aliases(aliases);
        self.winget = self.winget.set_aliases(aliases);
        self.scoop  = self.scoop.set_aliases(aliases);
        self.choco  = self.choco.set_aliases(aliases);

        self

    }

    pub const fn register ( mut self, manager: Manager, spec: Spec ) -> Self {

        match manager {
            Manager::Apt    => self.apt    = self.apt.merge(spec),
            Manager::Apk    => self.apk    = self.apk.merge(spec),
            Manager::Dnf    => self.dnf    = self.dnf.merge(spec),
            Manager::Yum    => self.yum    = self.yum.merge(spec),
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
