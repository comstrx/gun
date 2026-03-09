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

    let tools = ["wrk", "curl"];

    println!("\n- Manager    => {}", Manager::name());
    println!("\n- OS Name    => {}", Manager::os_name());
    println!("\n- Is Linux   => {}", Manager::is_linux());
    println!("\n- Is Macos   => {}", Manager::is_macos());
    println!("\n- Is Windows => {}", Manager::is_windows());
    println!("\n- Is Unix    => {}", Manager::is_unix());
    println!("\n- Is WSL     => {}", Manager::is_wsl());
    println!("\n- Refresh    =>\n"); Manager::refresh()?;

    for tool in tools {

        println!("\n\n* Tool ( {} ) *\n-------------\n", tool);

        println!("\n- ensure"); Manager::ensure(tool)?;

        println!("\n- Installed  ==> {}", Manager::has(tool));
        println!("\n- path       ==> {}", Manager::path(tool)?.to_string_lossy());
        println!("\n- version    ==> {}", Manager::version(tool)?);

    }

    Ok(())

}
