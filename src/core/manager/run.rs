use std::process::Command;
use std::io::IsTerminal;
use which::which;

use crate::core::error::{AppResult, AppError};
use super::base::Manager;

impl Manager {

    pub fn run ( command: &str, args: &[&str] ) -> AppResult<()> {

        let status = Command::new(command).args(args).status()?;

        if !status.success() { return Err(AppError::command_failed(command, status)); }

        Ok(())

    }

    pub fn run_output ( command: &str, args: &[&str] ) -> AppResult<std::process::Output> {

        let output = Command::new(command).args(args).output()?;

        if !output.status.success() { return Err(AppError::command_failed(command, output.status)); }

        Ok(output)

    }

    pub fn sudo_run ( command: &str, args: &[&str] ) -> AppResult<()> {

        #[cfg(unix)]
        {

            if rustix::process::geteuid().is_root() { return Self::run(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_binary("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).status() {
                Ok(status) if status.success() => return Ok(()),
                Ok(_) | Err(_) => {}
            }

            if std::io::stdin().is_terminal() && std::io::stderr().is_terminal() {

                let mut sudo_args = Vec::with_capacity(args.len() + 1);
                sudo_args.push(command);
                sudo_args.extend_from_slice(args);

                return Self::run("sudo", &sudo_args);

            }

            Self::run(command, args)

        }

        #[cfg(not(unix))]
        {

            Self::run_live(command, args)

        }

    }

    pub fn sudo_run_output ( command: &str, args: &[&str] ) -> AppResult<std::process::Output> {

        #[cfg(unix)]
        {

            if rustix::process::geteuid().is_root() { return Self::run_output(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_binary("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).output() {
                Ok(output) if output.status.success() => return Ok(output),
                Ok(_) | Err(_) => {}
            }

            if std::io::stdin().is_terminal() && std::io::stderr().is_terminal() {

                let mut sudo_args = Vec::with_capacity(args.len() + 1);
                sudo_args.push(command);
                sudo_args.extend_from_slice(args);

                return Self::run_output("sudo", &sudo_args);

            }

            Self::run_output(command, args)

        }

        #[cfg(not(unix))]
        {

            Self::run_output(command, args)

        }

    }

}
