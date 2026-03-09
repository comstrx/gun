#![allow(unused)]

use crate::core::{Manager, AppResult};

pub fn main () -> AppResult<()> {

    let tools = [
        "git", "gh", "rustc", "rustup", "node", "bun", "go", "pixi", "clang", "zig", "dotnet",
        "composer", "php", "lua", "uv", "luarocks", "wrk", "curl", "cmake", "xmake", "python"
    ];

    println!("\n- Refresh    =>\n"); Manager::refresh()?;
    println!("\n- Manager    => {}", Manager::name());
    println!("\n- OS Name    => {}", Manager::os_name());
    println!("\n- Is Unix    => {}", Manager::is_unix());
    println!("\n- Is WSL     => {}", Manager::is_wsl());
    println!("\n- Is Linux   => {}", Manager::is_linux());
    println!("\n- Is Macos   => {}", Manager::is_macos());
    println!("\n- Is Windows => {}", Manager::is_windows());

    let start = std::time::Instant::now();

    for tool in tools {

        println!("\n\n* Tool: ( {} )\n----------------", tool);

        println!("\n- ensure     ==> Ok"); Manager::ensure(tool)?;
        println!("\n- Installed  ==> {}", Manager::has(tool));
        println!("\n- path       ==> {}", Manager::path_str(tool)?);
        println!("\n- version    ==> {}", Manager::version(tool)?);
        println!("\n- Doctor : \n"); Manager::show(tool)?;

    }

    print!("\n\n * Elapsed: {} sec.\n", start.elapsed().as_secs());
    Ok(())

}
