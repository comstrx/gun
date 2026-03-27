
use super::arch::{Manager, Tool, Spec, Method};

pub const TOOLS: &[(&'static str, Tool)] = &[
    ("curl",
        Tool::new().set_bin("curl").set_version("8.5.0").set_aliases(&["curl"])
            .register(Manager::Winget, Spec::new().set_name("cURL.cURL"))
    ),
    ("bun",
        Tool::new().set_bin("bun").set_version("1.3.9")
            .register_linux(Spec::new().set_method(Method::Shell).set_source("https://bun.sh/install"))
            .register(Manager::Winget, Spec::new().set_name("Oven-sh.Bun"))
    ),
];
