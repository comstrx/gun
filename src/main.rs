#![allow(unused)]
pub mod core;
use crate::core::{Manager, AppResult, AppError};

fn main () -> std::process::ExitCode {

    match run() {
        Ok(()) => std::process::ExitCode::SUCCESS,
        Err(error) => error.report(),
    }

}

fn run () -> AppResult<()> {

    Manager::run_output("git", &["add", "."])?;
    Manager::run_output("git", &["commit", "-m", "Done from Gun"])?;
    Manager::run_live("git", &["push"])?;

    Ok(())

}
