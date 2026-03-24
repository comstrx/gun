
use super::arch::{Spec, Method};

impl Spec {

    pub const fn new () -> Self {

        Self {
            method  : Method::Native,
            bin     : "",
            name    : "",
            version : "",
            url     : "",
            path    : "",
            args    : &[],
            aliases : &[]
        }

    }

    pub const fn merge ( self, spec: Self ) -> Self {

        Self {
            method  : if matches!(spec.method, Method::Native) && !matches!(self.method, Method::Native) { self.method } else { spec.method },
            bin     : if spec.bin.is_empty()     { self.bin }     else { spec.bin },
            name    : if spec.name.is_empty()    { self.name }    else { spec.name },
            version : if spec.version.is_empty() { self.version } else { spec.version },
            url     : if spec.url.is_empty()     { self.url }     else { spec.url },
            path    : if spec.path.is_empty()    { self.path }    else { spec.path },
            args    : if spec.args.is_empty()    { self.args }    else { spec.args },
            aliases : if spec.aliases.is_empty() { self.aliases } else { spec.aliases },
        }

    }

    pub const fn set_method ( mut self, value: Method ) -> Self {

        self.method = value;
        self

    }

    pub const fn set_name ( mut self, value: &'static str ) -> Self {

        self.name = value;
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

    pub const fn set_url ( mut self, value: &'static str ) -> Self {

        self.url = value;
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

}
