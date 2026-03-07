
use crate::core::app::{AppResult, AppError};
use super::{arch::{Tool, Strategy}, tree::TOOLS};

impl Tool {

    pub fn find ( key: &str ) -> AppResult<Self> {

        let key = key.trim().to_ascii_lowercase();

        TOOLS
            .iter()
            .find(|(name, tool)| {
                *name == key || tool.aliases.iter().any(|alias| *alias == key)
            })
            .map(|(_, tool)| *tool)
            .ok_or_else(|| AppError::command_not_found(key))

    }

    pub fn has ( key: &str ) -> bool {

        Self::find(key).is_ok()

    }

    pub fn get ( key: &str ) -> AppResult<Strategy> {

        let tool = Self::find(key)?;

        if cfg!(windows) { return Ok(tool.win); }
        if cfg!(target_os = "macos") { return Ok(tool.mac); }

        Ok(tool.linux)

    }

}
