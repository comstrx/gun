use super::arch::{Tool};

pub const TOOLS: &[(&'static str, Tool)] = &[
    ("curl", Tool::new("curl")),
    // ("perl", Tool::new(&[],
    //     Spec::new(Method::Native, "perl", "perl", "", "", &[]),
    //     Spec::new(Method::Native, "perl", "perl", "", "", &[]),
    //     Spec::new(Method::Native, "perl", "StrawberryPerl.StrawberryPerl", "", "", &[]),
    // )),
    // ("wrk", Tool::new(&[],
    //     Spec::new(Method::Native, "wrk", "wrk", "", "", &[]),
    //     Spec::new(Method::Native, "wrk", "wrk", "", "", &[]),
    //     Spec::new(Method::Native, "", "", "", "", &[]),
    // )),
];
