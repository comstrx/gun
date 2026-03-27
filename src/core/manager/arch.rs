
pub use crate::core::app::{AppResult, AppError};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Method {
    Native,
    Nix,
    Snap,
    Mise,
    Bash,
    Shell,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Info {
    pub method  : Method,
    pub bin     : String,
    pub name    : String,
    pub path    : Option<std::path::PathBuf>,
    pub source  : Option<String>,
    pub version : Option<String>,
    pub args    : Vec<String>,
    pub aliases : Vec<String>,
    pub exists  : bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Spec {
    pub method  : Method,
    pub bin     : &'static str,
    pub name    : &'static str,
    pub path    : &'static str,
    pub source  : &'static str,
    pub version : &'static str,
    pub args    : &'static [&'static str],
    pub aliases : &'static [&'static str],
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Tool {
    pub apt    : Spec,
    pub apk    : Spec,
    pub dnf    : Spec,
    pub yum    : Spec,
    pub nix    : Spec,
    pub pacman : Spec,
    pub zypper : Spec,
    pub brew   : Spec,
    pub winget : Spec,
    pub scoop  : Spec,
    pub choco  : Spec,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Manager {
    Apt,
    Apk,
    Dnf,
    Yum,
    Nix,
    Pacman,
    Zypper,
    Brew,
    Winget,
    Scoop,
    Choco,
}
