
pub use crate::core::app::{AppResult, AppError};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Manager {
    Apt,
    Apk,
    Dnf,
    Yum,
    Pacman,
    Zypper,
    Brew,
    Winget,
    Scoop,
    Choco,
}
