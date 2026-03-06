pub mod error;
pub mod manager;

pub use error::{AppResult, AppError, AppExitCode};
pub use manager::Manager;
