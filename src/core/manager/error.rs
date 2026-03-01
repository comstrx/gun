use std::path::PathBuf;
use std::process::ExitStatus;
use thiserror::Error;

pub type ManagerResult<T> = Result<T, ManagerError>;

#[derive(Debug, Error)]
pub enum ManagerError {
    #[error("{0}")]
    Message(String),

    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    #[error("environment error: {0}")]
    EnvVar(#[from] std::env::VarError),

    #[error("utf-8 error: {0}")]
    Utf8(#[from] std::string::FromUtf8Error),

    #[error("path is not valid utf-8: {0}")]
    InvalidPath(PathBuf),

    #[error("missing required binary: {0}")]
    MissingBinary(String),

    #[error("command failed: {program} ({status})")]
    CommandFailed {
        program: String,
        status: ExitStatus,
    },

    #[error("command failed: {program} ({status})\n{stderr}")]
    CommandFailedWithStderr {
        program: String,
        status: ExitStatus,
        stderr: String,
    },
}

impl ManagerError {

    pub fn message ( message: impl Into<String> ) -> Self {

        Self::Message(message.into())

    }

    pub fn invalid_path ( path: impl Into<PathBuf> ) -> Self {

        Self::InvalidPath(path.into())

    }

    pub fn missing_binary ( name: impl Into<String> ) -> Self {

        Self::MissingBinary(name.into())

    }

    pub fn command_failed ( program: impl Into<String>, status: ExitStatus ) -> Self {

        Self::CommandFailed { program: program.into(), status }

    }

    pub fn command_failed_with_stderr ( program: impl Into<String>, status: ExitStatus, stderr: impl Into<String> ) -> Self {

        let program = program.into();
        let stderr = stderr.into();

        if stderr.trim().is_empty() {
            return Self::CommandFailed { program, status };
        }

        Self::CommandFailedWithStderr { program, status, stderr }

    }

}
