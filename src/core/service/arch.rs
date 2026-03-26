
pub use crate::core::app::{AppResult, AppError};
pub use crate::core::manager::Manager;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Restart {
    Never,
    Always,
    OnAbort,
    OnFailure,
    OnSuccess,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    Simple,
    Forking,
    Oneshot,
    Notify,
    Shared,
    Owned,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Spec {
    pub restart     : Restart,
    pub kind        : Kind,
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

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Launcher {
    Windows,
    Launchd,
    Systemd,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Service {
    pub windows : Spec,
    pub launchd : Spec,
    pub systemd : Spec,
}
