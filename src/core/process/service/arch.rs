
pub use crate::core::app::{AppResult, AppError};
pub use crate::core::process::manager::Manager;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    Simple,
    Forking,
    Oneshot,
    Notify,
    Daemon,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Launcher {
    Systemd,
    Launchd,
    OpenRc,
    SysV,
    Windows,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Restart {
    Never,
    Always,
    OnFailure,
    OnSuccess,
    OnAbort,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Service {
    pub kind        : Kind,
    pub launcher    : Launcher,
    pub restart     : Restart,
    pub name        : &'static str,
    pub description : &'static str,
    pub command     : &'static str,
    pub args        : &'static [&'static str],
    pub cwd         : &'static str,
    pub user        : &'static str,
    pub group       : &'static str,
    pub env         : &'static [(&'static str, &'static str)],
    pub wanted_by   : &'static str,
}
