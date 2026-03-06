
use super::arch::{Tool, Strategy, Method};

pub const TOOLS: &[(&'static str, Tool)] = &[
    (
        "rust", Tool::new(&["rustc"],
            Strategy::new(Method::Native, "rustup", "rustc", "", "", &[]),
            Strategy::new(Method::Native, "rustup", "rustc", "", "", &[]),
            Strategy::new(Method::Native, "rustup", "rustc", "", "", &[]),
        ),
    ),
];
