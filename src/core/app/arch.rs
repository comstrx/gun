use std::{path::PathBuf, process::ExitStatus};
use thiserror::Error;

pub type AppResult<T> = Result<T, AppError>;
pub type AppExitCode = std::process::ExitCode;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("{0}")]
    Message(String),

    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    #[error("utf-8 error: {0}")]
    Utf8(#[from] std::string::FromUtf8Error),

    #[error("environment error: {0}")]
    EnvVar(#[from] std::env::VarError),

    #[error("path is not valid utf-8: {}", .0.display())]
    InvalidPath(PathBuf),

    #[error("path not found: {}", .0.display())]
    PathNotFound(PathBuf),

    #[error("path already exists: {}", .0.display())]
    PathExists(PathBuf),

    #[error("path type mismatch: expected {expected}, found {found}: {}", path.display())]
    PathTypeMismatch { path: PathBuf, expected: String, found: String },

    #[error("permission denied: {action}: {}", path.display())]
    PermissionDenied { path: PathBuf, action: String },

    #[error("missing required binary: {0}")]
    MissingBinary(String),

    #[error("missing environment variable: {0}")]
    MissingEnvVar(String),

    #[error("unsupported platform: {0}")]
    UnsupportedPlatform(String),

    #[error("unsupported manager: {0}")]
    UnsupportedManager(String),

    #[error("unsupported operation: {0}")]
    UnsupportedOperation(String),

    #[error("invalid argument `{name}`: {message}")]
    InvalidArgument { name: String, message: String },

    #[error("operation ( {name} ) failed: {message}")]
    OperationFailed { name: String, message: String },

    #[error("command not found: {name}")]
    CommandNotFound { name: String },

    #[error("command failed: {name} ({status})")]
    CommandFailed { name: String, status: ExitStatus, stdout: Option<String>, stderr: Option<String> },
}
