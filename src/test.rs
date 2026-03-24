#![allow(unused)]
use crate::core::{Process, Tool, AppResult};

pub fn main () -> AppResult<()> {

    println!("{:#?}", Tool::get("curl")?);
    println!("{:#?}", Tool::get("bun")?);

    Ok(())

}
