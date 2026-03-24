
pub use crate::core::app::{AppResult, AppError};
pub use crate::core::process::manager::Manager;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Method {
    Native,
    Nix,
    Mise,
    Bash,
    Shell,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Spec {
    pub method  : Method,
    pub bin     : &'static str,
    pub name    : &'static str,
    pub path    : &'static str,
    pub url     : &'static str,
    pub version : &'static str,
    pub args    : &'static [&'static str],
    pub aliases : &'static [&'static str],
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Info {
    pub method  : Method,
    pub bin     : String,
    pub name    : String,
    pub path    : Option<std::path::PathBuf>,
    pub url     : Option<String>,
    pub version : Option<String>,
    pub args    : Vec<String>,
    pub aliases : Vec<String>,
    pub exists  : bool,
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
