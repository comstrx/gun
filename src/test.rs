#![allow(unused)]
use crate::core::{Manager, Service, AppResult};

pub fn main () -> AppResult<()> {

    println!("{:#?}", Service::get("redis")?);
    println!("{:#?}", Manager::get("bun")?);

    Ok(())

}
