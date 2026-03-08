
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Source {
    Native,
    Shell,
    Bash,
    Nix,
    Mise,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Spec {
    pub source : Source,
    pub bin    : &'static str,
    pub id     : &'static str,
    pub path   : &'static str,
    pub url    : &'static str,
    pub args   : &'static [&'static str],
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Tool {
    pub aliases : &'static [&'static str],
    pub linux   : Spec,
    pub macos   : Spec,
    pub windo   : Spec,
}
