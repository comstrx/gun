use crate::core::app::{AppResult, AppError};
use super::arch::{Tool, Spec, Source};
use super::map::TOOLS;

impl Source {

    pub fn as_str ( &self ) -> &'static str {

        match self {
            Self::Native => "native",
            Self::Shell  => "shell",
            Self::Bash   => "bash",
            Self::Nix    => "nix",
            Self::Mise   => "mise",
        }

    }

}

impl Spec {

    pub const fn new (
        source: Source,
        bin: &'static str,
        id: &'static str,
        path: &'static str,
        url: &'static str,
        args: &'static [&'static str],
    ) -> Self {

        Self { source, url, id, bin, path, args }

    }

}

impl Tool {

    pub const fn new ( aliases : &'static [&'static str], linux: Spec, macos: Spec, windo: Spec ) -> Self {

        Self { aliases, linux, macos, windo }

    }

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

    pub fn get ( key: &str ) -> AppResult<Spec> {

        let tool = Self::find(key)?;

        if cfg!(windows) { return Ok(tool.windo); }
        if cfg!(target_os = "macos") { return Ok(tool.macos); }

        Ok(tool.linux)

    }

}
