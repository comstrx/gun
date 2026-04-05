pub mod arch;
pub mod base;

pub mod context;
pub mod index;
pub mod spec;
pub mod tool;

pub mod install;
pub mod info;
pub mod work;

pub use arch::{Manager, Tool, Spec, Info, Method, Context};


// refresh func
// parallel install/remove/ensure
