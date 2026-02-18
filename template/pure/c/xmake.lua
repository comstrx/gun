---@diagnostic disable: undefined-global, undefined-field

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

task("format")

    set_category("plugin")

    on_run(function ()

        import("core.base.option")
        import("lib.detect.find_tool")

        local tool = find_tool("clang-format")
        if not tool then
            raise("clang-format not found!")
        end

        local check = option.get("check")
        local patterns = option.get("files") or { "src/**/*", "include/**/*" }
        local base = {"-style=file"}

        if check then base = {"-style=file", "--dry-run", "--Werror"}
        else base = {"-style=file", "-i"}
        end

        for _, pattern in ipairs(patterns) do
            for _, file in ipairs(os.files(pattern)) do
                os.execv(tool.program, table.join(base, {file}))
            end
        end

    end)

    set_menu {
        usage = "xmake format [options]",
        description = "Format C/C++ code via clang-format",
        options = {
            {'c', "check", "k", nil, "Verify only (no changes)"},
            {'f', "files", "vs", nil, "File patterns"}
        }
    }
