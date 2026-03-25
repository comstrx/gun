
use super::arch::{Service, Spec, Kind, Restart};

pub const SERVICES: &[(&'static str, Service)] = &[
    ("redis",
        Service::new().set_name("redis").set_description("redis service")
            .register_linux(Spec::new().set_kind(Kind::Simple).set_restart(Restart::Always))
            .register_macos(Spec::new().set_restart(Restart::Never))
            .register_windows(Spec::new().set_kind(Kind::Shared).set_restart(Restart::Always))
    ),
];
