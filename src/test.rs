#![allow(unused)]

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

    let tools = [
        "git", "gh", "curl", "rustc", "rustup", "node", "bun", "go", "mojo", "pixi", "clang", "zig", "dotnet",
        "composer", "php", "lua", "uv", "luarocks", "unzip", "wrk", "7z", "cmake", "xmake", "python"
    ];

    for tool in tools { Manager::show(tool)? }

    Ok(())

}
