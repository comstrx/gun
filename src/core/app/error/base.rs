use std::{path::PathBuf, process::{ExitCode, ExitStatus}};
use owo_colors::OwoColorize;

use super::arch::AppError;

impl AppError {

    pub fn message ( message: impl Into<String> ) -> Self {

        Self::Message(message.into())

    }

    pub fn invalid_path ( path: impl Into<PathBuf> ) -> Self {

        Self::InvalidPath(path.into())

    }

    pub fn path_not_found ( path: impl Into<PathBuf> ) -> Self {

        Self::PathNotFound(path.into())

    }

    pub fn path_exists ( path: impl Into<PathBuf> ) -> Self {

        Self::PathExists(path.into())

    }

    pub fn path_type_mismatch ( path: impl Into<PathBuf>, expected: impl Into<String>, found: impl Into<String> ) -> Self {

        Self::PathTypeMismatch { path: path.into(), expected: expected.into(), found: found.into() }

    }

    pub fn permission_denied ( path: impl Into<PathBuf>, action: impl Into<String> ) -> Self {

        Self::PermissionDenied { path: path.into(), action: action.into() }

    }


    pub fn cannot_detect ( name: impl Into<String> ) -> Self {

        Self::CannotDetect(name.into())

    }

    pub fn missing_env_var ( name: impl Into<String> ) -> Self {

        Self::MissingEnvVar(name.into())

    }

    pub fn missing_key ( name: impl Into<String> ) -> Self {

        Self::MissingKey(name.into())

    }

    pub fn missing_service ( name: impl Into<String> ) -> Self {

        Self::MissingService(name.into())

    }

    pub fn missing_tool ( name: impl Into<String> ) -> Self {

        Self::MissingTool(name.into())

    }

    pub fn unsupported_platform ( name: impl Into<String> ) -> Self {

        Self::UnsupportedPlatform(name.into())

    }

    pub fn unsupported_manager ( name: impl Into<String> ) -> Self {

        Self::UnsupportedManager(name.into())

    }

    pub fn unsupported_service ( name: impl Into<String> ) -> Self {

        Self::UnsupportedService(name.into())

    }

    pub fn unsupported_tool ( name: impl Into<String> ) -> Self {

        Self::UnsupportedTool(name.into())

    }

    pub fn unsupported_operation ( name: impl Into<String> ) -> Self {

        Self::UnsupportedOperation(name.into())

    }


    pub fn invalid_argument ( name: impl Into<String>, message: impl Into<String> ) -> Self {

        Self::InvalidArgument { name: name.into(), message: message.into() }

    }

    pub fn operation_failed ( name: impl Into<String>, message: impl Into<String> ) -> Self {

        Self::OperationFailed { name: name.into(), message: message.into() }

    }

    pub fn command_not_found ( name: impl Into<String> ) -> Self {

        Self::CommandNotFound { name: name.into() }

    }

    pub fn command_failed ( name: impl Into<String>, status: ExitStatus ) -> Self {

        Self::CommandFailed { name: name.into(), status, stdout: None, stderr: None }

    }

    pub fn command_failed_output ( name: impl Into<String>, status: ExitStatus, stdout: Option<String>, stderr: Option<String> ) -> Self {

        let stdout = stdout.map(|stdout| stdout.trim().to_string()).filter(|stdout| !stdout.is_empty());
        let stderr = stderr.map(|stderr| stderr.trim().to_string()).filter(|stderr| !stderr.is_empty());

        Self::CommandFailed { name: name.into(), status, stdout, stderr }

    }


    pub fn exit_code ( &self ) -> ExitCode {

        ExitCode::from(match self {
            Self::CannotDetect(_)          => 2,
            Self::MissingEnvVar(_)         => 3,
            Self::MissingKey(_)            => 4,
            Self::MissingService(_)        => 5,
            Self::MissingTool(_)           => 6,
            Self::InvalidArgument { .. }   => 7,
            Self::UnsupportedPlatform(_)   => 8,
            Self::UnsupportedManager(_)    => 9,
            Self::UnsupportedService(_)    => 10,
            Self::UnsupportedTool(_)       => 11,
            Self::UnsupportedOperation(_)  => 12,
            Self::PathNotFound(_)          => 13,
            Self::PathExists(_)            => 14,
            Self::PathTypeMismatch { .. }  => 15,
            Self::PermissionDenied { .. }  => 16,
            Self::CommandNotFound { .. }   => 17,
            Self::CommandFailed { .. }     => 18,
            Self::OperationFailed { .. }   => 19,
            _                              => 1,
        })

    }

    pub fn print_block ( label: &str, value: &str, is_stderr: bool ) {

        eprintln!("{}", format!("{label}:").bold().bright_black());

        for line in value.lines().filter(|line| !line.trim().is_empty()) {

            if is_stderr { eprintln!("  {}", line.bright_red()); }
            else { eprintln!("  {}", line.bright_cyan()); }

        }

    }

    pub fn report ( &self ) -> ExitCode {

        eprintln!("{}: {}", "error".bold().bright_red(), self.to_string().bold());

        if let Self::CommandFailed { stdout, stderr, .. } = self {

            if let Some(stderr) = stderr.as_deref().filter(|value| !value.trim().is_empty()) {
                Self::print_block("stderr", stderr, true);
            }

            if let Some(stdout) = stdout.as_deref().filter(|value| !value.trim().is_empty()) {
                Self::print_block("stdout", stdout, false);
            }

        }

        let mut source = std::error::Error::source(self);

        while let Some(cause) = source {
            eprintln!("{} {}", "cause:".bold().bright_black(), cause.to_string().bright_black());
            source = cause.source();
        }

        self.exit_code()

    }

}
