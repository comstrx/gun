
use super::arch::{Spec, Kind, Restart};

impl Spec {

    pub const fn new () -> Self {

        Self {
            kind        : Kind::Simple,
            restart     : Restart::Always,
            name        : "",
            description : "",
            command     : "",
            args        : &[],
            cwd         : "",
            user        : "",
            group       : "",
            env         : &[],
            wanted_by   : "multi-user.target",
        }

    }

    pub const fn merge ( self, spec: Self ) -> Self {

        Self {
            kind        : if matches!(spec.kind, Kind::Simple) && !matches!(self.kind, Kind::Simple) { self.kind } else { spec.kind },
            restart     : if matches!(spec.restart, Restart::Always) && !matches!(self.restart, Restart::Always) { self.restart } else { spec.restart },
            name        : if spec.name.is_empty()        { self.name }    else { spec.name },
            description : if spec.description.is_empty() { self.description }    else { spec.description },
            command     : if spec.command.is_empty()     { self.command }    else { spec.command },
            args        : if spec.args.is_empty()        { self.args }    else { spec.args },
            cwd         : if spec.cwd.is_empty()         { self.cwd }    else { spec.cwd },
            user        : if spec.user.is_empty()        { self.user }    else { spec.user },
            group       : if spec.group.is_empty()       { self.group }    else { spec.group },
            env         : if spec.env.is_empty()         { self.env }    else { spec.env },
            wanted_by   : if spec.wanted_by.is_empty()   { self.wanted_by }    else { spec.wanted_by },
        }

    }

    pub const fn set_kind ( mut self, value: Kind ) -> Self {

        self.kind = value;
        self

    }

    pub const fn set_restart ( mut self, value: Restart ) -> Self {

        self.restart = value;
        self

    }

    pub const fn set_name ( mut self, value: &'static str ) -> Self {

        self.name = value;
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

    pub const fn set_wanted_by ( mut self, value: &'static str ) -> Self {

        self.wanted_by = value;
        self

    }

}
