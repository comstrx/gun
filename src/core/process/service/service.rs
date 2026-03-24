use super::arch::{Service, Launcher, Manager, AppResult, AppError};

impl Service {

    pub const fn new ( name: &'static str ) -> Self {

        Self {
            name        : name,
            kind        : "simple",
            description : "",
            command     : "",
            args        : &[],
            cwd         : "",
            user        : "",
            group       : "",
            env         : &[],
            restart     : "always",
            wanted_by   : "multi-user.target",
        }

    }

    pub const fn set_name ( mut self, value: &'static str ) -> Self {

        self.name = value;
        self

    }

    pub const fn set_kind ( mut self, value: &'static str ) -> Self {

        self.kind = value;
        self

    }

    pub const fn set_description ( mut self, value: &'static str ) -> Self {

        self.description = value;
        self

    }

    pub const fn set_command ( mut self, value: &'static str ) -> Self {

        self.command = value;
        self

    }

    pub const fn set_args ( mut self, value: &'static [&'static str] ) -> Self {

        self.args = value;
        self

    }

    pub const fn set_cwd ( mut self, value: &'static str ) -> Self {

        self.cwd = value;
        self

    }

    pub const fn set_user ( mut self, value: &'static str ) -> Self {

        self.user = value;
        self

    }

    pub const fn set_group ( mut self, value: &'static str ) -> Self {

        self.group = value;
        self

    }

    pub const fn set_env ( mut self, value: &'static [(&'static str, &'static str)] ) -> Self {

        self.env = value;
        self

    }

    pub const fn set_restart ( mut self, value: &'static str ) -> Self {

        self.restart = value;
        self

    }

    pub const fn set_wanted_by ( mut self, value: &'static str ) -> Self {

        self.wanted_by = value;
        self

    }

}
