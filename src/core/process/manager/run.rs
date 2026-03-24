use std::{io, io::IsTerminal, process::{Command, Output}};
use {rustix::process::geteuid, which::which};

use super::arch::{Manager, AppResult, AppError};

impl Manager {

    pub fn run ( command: &str, args: &[&str] ) -> AppResult<()> {

        let status = Command::new(command).args(args).status()?;

        if !status.success() { return Err(AppError::command_failed(command, status)); }

        Ok(())

    }

    pub fn run_output ( command: &str, args: &[&str] ) -> AppResult<Output> {

        let output = Command::new(command).args(args).output()?;

        if !output.status.success() {

            let stdout = (!output.stdout.is_empty()).then(|| String::from_utf8_lossy(&output.stdout).into_owned());
            let stderr = (!output.stderr.is_empty()).then(|| String::from_utf8_lossy(&output.stderr).into_owned());

            return Err(AppError::command_failed_output(command, output.status, stdout, stderr));

        }

        Ok(output)

    }

    pub fn run_capture ( command: &str, args: &[&str] ) -> AppResult<Output> {

        Ok(Command::new(command).args(args).output()?)

    }


    pub fn try_run ( command: &str, args: &[&str] ) -> AppResult<()> {

        #[cfg(unix)]
        {

            if geteuid().is_root() { return Self::run(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_binary("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).status() {
                Ok(status) if status.success() => return Ok(()),
                Ok(_) | Err(_) => {}
            }

            if io::stdin().is_terminal() && io::stderr().is_terminal() {

                let mut sudo_args = Vec::with_capacity(args.len() + 1);
                sudo_args.push(command);
                sudo_args.extend_from_slice(args);

                return Self::run("sudo", &sudo_args);

            }

            Self::run(command, args)

        }

        #[cfg(not(unix))]
        {

            Self::run(command, args)

        }

    }

    pub fn try_run_output ( command: &str, args: &[&str] ) -> AppResult<Output> {

        #[cfg(unix)]
        {

            if geteuid().is_root() { return Self::run_output(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_binary("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).output() {
                Ok(output) if output.status.success() => return Ok(output),
                Ok(_) | Err(_) => {}
            }

            if io::stdin().is_terminal() && io::stderr().is_terminal() {

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

    pub fn try_run_capture ( command: &str, args: &[&str] ) -> AppResult<Output> {

        #[cfg(unix)]
        {

            if geteuid().is_root() { return Self::run_capture(command, args); }
            if which("sudo").is_err() { return Err(AppError::missing_binary("sudo")); }

            let mut sudo_args = Vec::with_capacity(args.len() + 2);
            sudo_args.extend(["-n", command]);
            sudo_args.extend_from_slice(args);

            match Command::new("sudo").args(&sudo_args).output() {
                Ok(output) if output.status.success() => return Ok(output),
                Ok(_) | Err(_) => {}
            }

            if io::stdin().is_terminal() && io::stderr().is_terminal() {

                let mut sudo_args = Vec::with_capacity(args.len() + 1);
                sudo_args.push(command);
                sudo_args.extend_from_slice(args);

                return Self::run_capture("sudo", &sudo_args);

            }

            Self::run_capture(command, args)

        }

        #[cfg(not(unix))]
        {

            Self::run_capture(command, args)

        }

    }

}
