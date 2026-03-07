

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Method {
    Native,
    Shell,
    Bash,
    Nix,
    Mise,
}

impl Method {

    pub fn as_str ( &self ) -> &'static str {

        match self {
            Self::Native   => "native",
            Self::Shell    => "shell",
            Self::Bash     => "bash",
            Self::Nix      => "nix",
            Self::Mise     => "mise",
        }

    }

}


#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Strategy {
    pub method : Method,
    pub name   : &'static str,
    pub bin    : &'static str,
    pub path   : &'static str,
    pub source : &'static str,
    pub args   : &'static [&'static str],
}

impl Strategy {

    pub const fn new (
        method: Method,
        name: &'static str,
        bin: &'static str,
        path: &'static str,
        source: &'static str,
        args: &'static [&'static str],
    ) -> Self {

        Self { method, name, bin, path, source, args }

    }

}


#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Tool {
    pub aliases : &'static [&'static str],
    pub linux  : Strategy,
    pub mac    : Strategy,
    pub win    : Strategy,
}

impl Tool {

    pub const fn new (
        aliases : &'static [&'static str],
        linux: Strategy,
        mac: Strategy,
        win: Strategy
    ) -> Self {

        Self { aliases, linux, mac, win }

    }

}
