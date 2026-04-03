pub mod error;
pub use error::{AppResult, AppError, AppExitCode};

pub mod context;
pub use context::{AppContext, ContextValue};
