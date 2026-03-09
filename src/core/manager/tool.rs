
use crate::core::app::{AppResult, AppError};
use super::arch::{Manager, Tool, Spec};
use super::map::TOOLS;

impl Tool {

    pub const fn new ( key : &'static str ) -> Self {

        Self {
            apt    : Spec::new(key),
            apk    : Spec::new(key),
            dnf    : Spec::new(key),
            yum    : Spec::new(key),
            pacman : Spec::new(key),
            zypper : Spec::new(key),
            brew   : Spec::new(key),
            winget : Spec::new(key),
            scoop  : Spec::new(key),
            choco  : Spec::new(key),
        }
    }

    pub const fn set ( mut self, manager: Manager, spec: Spec ) -> Self {

        match manager {
            Manager::Apt    => self.apt = spec,
            Manager::Apk    => self.apk = spec,
            Manager::Dnf    => self.dnf = spec,
            Manager::Yum    => self.yum = spec,
            Manager::Pacman => self.pacman = spec,
            Manager::Zypper => self.zypper = spec,
            Manager::Brew   => self.brew = spec,
            Manager::Winget => self.winget = spec,
            Manager::Scoop  => self.scoop = spec,
            Manager::Choco  => self.choco = spec,
        }

        self

    }

    pub fn get ( key: &str ) -> AppResult<Self> {

        let key = key.trim();

        let has = |spec: &Spec| {
            spec.bin.eq_ignore_ascii_case(key)
                || spec.id.eq_ignore_ascii_case(key)
                || spec.path.eq_ignore_ascii_case(key)
                || spec.source.eq_ignore_ascii_case(key)
                || spec.aliases.iter().any(|alias| alias.eq_ignore_ascii_case(key))
        };

        TOOLS
            .iter()
            .find(|(name, tool)| {
                name.eq_ignore_ascii_case(key)
                    || has(&tool.apt)
                    || has(&tool.apk)
                    || has(&tool.dnf)
                    || has(&tool.yum)
                    || has(&tool.pacman)
                    || has(&tool.zypper)
                    || has(&tool.brew)
                    || has(&tool.winget)
                    || has(&tool.scoop)
                    || has(&tool.choco)
            })
            .map(|(_, tool)| *tool)
            .ok_or_else(|| AppError::command_not_found(key))

    }

}
