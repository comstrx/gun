use super::arch::{Tool, Spec, Source};

pub const TOOLS: &[(&'static str, Tool)] = &[
    (
        "perl", Tool::new(&["perlo"],
            Spec::new(Source::Native, "perl", "perl", "", "", &[]),
            Spec::new(Source::Native, "perl", "perl", "", "", &[]),
            Spec::new(Source::Native, "perl", "StrawberryPerl.StrawberryPerl", "", "", &[]),
        ),
    ),
];
