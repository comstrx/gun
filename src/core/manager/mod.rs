pub mod arch;
pub mod error;
pub mod install;

pub use crate::core::manager::arch::Manager;
pub use crate::core::manager::error::{ManagerError, ManagerResult};
