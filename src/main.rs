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

    let start = std::time::Instant::now();

    // business logic

    println!("\nElapsed => {:?}\n", start.elapsed());
    Ok(())

}
