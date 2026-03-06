

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Method {
    Native,
    Binary,
    Aqua,
    Mise,
    Nix,
    Cargo,
    Go,
    Xmake,
    Pixi,
    Pnpm,
    Bun,
    Uv,
    Composer,
}


#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Strategy {
    pub method : Method,
    pub name   : &'static str,
    pub bin    : &'static str,
    pub path   : &'static str,
    pub url    : &'static str,
    pub args   : &'static [&'static str],
}

impl Strategy {

    pub const fn new (
        method: Method,
        name: &'static str,
        bin: &'static str,
        path: &'static str,
        url: &'static str,
        args: &'static [&'static str],
    ) -> Self {

        Self { method, name, bin, path, url, args }

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

    pub const fn new ( aliases : &'static [&'static str], linux: Strategy, mac: Strategy, win: Strategy ) -> Self {

        Self { aliases, linux, mac, win }

    }

}
