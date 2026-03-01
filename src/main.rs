#![allow(unused)]

pub mod core;

use crate::core::manager::{Manager, ManagerResult, ManagerError};

fn main () -> ManagerResult<()> {

    println!("Done sir");
    Ok(())

}
