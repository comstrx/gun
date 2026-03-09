
use crate::core::app::{AppResult};
use super::arch::{Manager, Tool, Spec, Method};

impl Spec {

    pub const fn new ( key: &'static str ) -> Self {

        Self {
            method  : Method::Native,
            id      : key,
            bin     : key,
            path    : "",
            source  : "",
            version : "",
            args    : &[],
            aliases : &[]
        }

    }

    pub const fn set_method ( mut self, value: Method ) -> Self {

        self.method = value;
        self

    }

    pub const fn set_id ( mut self, value: &'static str ) -> Self {

        self.id = value;
        self

    }

    pub const fn set_bin ( mut self, value: &'static str ) -> Self {

        self.bin = value;
        self

    }

    pub const fn set_path ( mut self, value: &'static str ) -> Self {

        self.path = value;
        self

    }

    pub const fn set_source ( mut self, value: &'static str ) -> Self {

        self.source = value;
        self

    }

    pub const fn set_version ( mut self, value: &'static str ) -> Self {

        self.version = value;
        self

    }

    pub const fn set_args ( mut self, value: &'static [&'static str] ) -> Self {

        self.args = value;
        self

    }

    pub const fn set_aliases ( mut self, value: &'static [&'static str] ) -> Self {

        self.aliases = value;
        self

    }

    pub fn get ( key: &str ) -> AppResult<Spec> {

        let tool = Tool::get(key)?;

        Ok(match Manager::detect()? {
            Manager::Apt    => tool.apt,
            Manager::Apk    => tool.apk,
            Manager::Dnf    => tool.dnf,
            Manager::Yum    => tool.yum,
            Manager::Pacman => tool.pacman,
            Manager::Zypper => tool.zypper,
            Manager::Brew   => tool.brew,
            Manager::Winget => tool.winget,
            Manager::Scoop  => tool.scoop,
            Manager::Choco  => tool.choco,
        })

    }

}
