use crate::core::{Manager, AppResult};

fn run ( cmd: &str, args: &[&str] ) -> AppResult<()> {

    Manager::run(cmd, args)

}

fn version ( tool: &str, handle: bool ) -> AppResult<()> {

    if handle { println!("{}", Manager::version(tool).unwrap_or_else(|_| "--".to_string())); }
    else { println!("{}", Manager::version(tool)?); }

    Ok(())

}

fn install ( tool: &str ) -> AppResult<()> {

    if !Manager::has(tool) { Manager::install(tool)?; }
    version(tool, false)

}


pub fn main () -> AppResult<()> {

    let tools = ["llvm-config"];

    for tool in tools { install(tool)?; }

    Ok(())

}
