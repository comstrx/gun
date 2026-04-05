
pub use crate::core::app::{AppResult, AppError, AppContext, ContextValue};
pub use crate::core::manager::Manager;

pub struct Systemd;
pub struct Launchd;
pub struct Winsc;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Context {
    Name,
    Path,
    Source,
    Version,
}

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
    pub kind             : Kind,
    pub restart          : Restart,
    pub name             : &'static str,
    pub description      : &'static str,
    pub cwd              : &'static str,
    pub user             : &'static str,
    pub group            : &'static str,
    pub account          : &'static str,
    pub password         : &'static str,

    pub stdout_path      : &'static str,
    pub stderr_path      : &'static str,
    pub pid_file         : &'static str,
    pub runtime_directory: &'static str,
    pub logs_directory   : &'static str,

    pub start_timeout    : u64,
    pub stop_timeout     : u64,
    pub restart_delay    : u64,
    pub file_limit       : u64,
    pub process_limit    : u64,
    pub task_limit       : u64,
    pub memory_limit     : &'static str,
    pub umask            : &'static str,

    pub auto_start       : bool,
    pub kill_signal      : &'static str,
    pub start_type       : &'static str,
    pub error_control    : &'static str,

    pub command          : &'static str,
    pub args             : &'static [&'static str],
    pub dependencies     : &'static [&'static str],
    pub wanted_by        : &'static [&'static str],
    pub env              : &'static [(&'static str, &'static str)],
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Provider {
    Systemd,
    Launchd,
    Winsc,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Service {
    pub systemd : Spec,
    pub launchd : Spec,
    pub winsc   : Spec,
}
