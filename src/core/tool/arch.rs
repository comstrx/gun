
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Method {
    Native,
    Shell,
    Bash,
    Nix,
    Mise,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Spec {
    pub method  : Method,
    pub id      : &'static str,
    pub bin     : &'static str,
    pub path    : &'static str,
    pub source  : &'static str,
    pub version : &'static str,
    pub args    : &'static [&'static str],
    pub aliases : &'static [&'static str],
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Info {
    pub method  : Method,
    pub id      : String,
    pub bin     : String,
    pub path    : Option<std::path::PathBuf>,
    pub source  : Option<String>,
    pub version : Option<String>,
    pub exists  : bool,
    pub args    : Vec<String>,
    pub aliases : Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Tool {
    pub apt    : Spec,
    pub apk    : Spec,
    pub dnf    : Spec,
    pub yum    : Spec,
    pub pacman : Spec,
    pub zypper : Spec,
    pub brew   : Spec,
    pub winget : Spec,
    pub scoop  : Spec,
    pub choco  : Spec,
}
