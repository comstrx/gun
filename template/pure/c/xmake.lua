---@diagnostic disable: undefined-global

set_project("demo")
set_version("0.1.0")

set_languages("clatest")
add_rules("mode.debug", "mode.release")
set_policy("build.warning", true)

option("native")
    set_showmenu(true)
    set_default(false)
option_end()

target("demo")

    set_kind("binary")
    add_files("src/main.c")

    set_warnings("allextra", "pedantic", "error")

    if has_config("native") then
        add_cflags("-march=native", "-mtune=native", { tools = { "clang", "gcc" } })
        add_cflags("/arch:AVX2", { tools = "cl" })
    end

    if is_mode("debug") then
        add_defines("DEBUG=1")
        set_symbols("debug")
        set_optimize("none")
    else
        add_defines("NDEBUG=1")
        set_symbols("debug", "hidden")
        set_optimize("fastest")
        set_strip("all")
        set_policy("build.optimization.lto", true)
    end
