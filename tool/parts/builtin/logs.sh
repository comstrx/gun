[LINUX]
Run "bash" tool/parts/builtin/test.sh

== syntax / static checks ==
[PASS] bash -n target
[PASS] shellcheck target

== public api ==
log::is_tty
[PASS] function exists: log::is_tty
log::is_err_tty
[PASS] function exists: log::is_err_tty
log::is_quiet
[PASS] function exists: log::is_quiet
log::is_verbose
[PASS] function exists: log::is_verbose
log::supports_color
[PASS] function exists: log::supports_color
log::supports_unicode
[PASS] function exists: log::supports_unicode
log::level_num
[PASS] function exists: log::level_num
log::enabled
[PASS] function exists: log::enabled
log::color
[PASS] function exists: log::color
log::strip
[PASS] function exists: log::strip
log::symbol
[PASS] function exists: log::symbol
log::timestamp
[PASS] function exists: log::timestamp
log::emit
[PASS] function exists: log::emit
log::print
[PASS] function exists: log::print
log::line
[PASS] function exists: log::line
log::raw
[PASS] function exists: log::raw
log::err
[PASS] function exists: log::err
log::info
[PASS] function exists: log::info
log::ok
[PASS] function exists: log::ok
log::success
[PASS] function exists: log::success
log::done
[PASS] function exists: log::done
log::warn
[PASS] function exists: log::warn
log::warning
[PASS] function exists: log::warning
log::error
[PASS] function exists: log::error
log::fail
[PASS] function exists: log::fail
log::debug
[PASS] function exists: log::debug
log::trace
[PASS] function exists: log::trace
log::step
[PASS] function exists: log::step
log::fatal
[PASS] function exists: log::fatal
log::die
[PASS] function exists: log::die
log::title
[PASS] function exists: log::title
log::section
[PASS] function exists: log::section
log::subsection
[PASS] function exists: log::subsection
log::hr
[PASS] function exists: log::hr
log::kv
[PASS] function exists: log::kv
log::pair
[PASS] function exists: log::pair
log::list
[PASS] function exists: log::list
log::item
[PASS] function exists: log::item
log::cmd
[PASS] function exists: log::cmd
log::quote
[PASS] function exists: log::quote
log::indent
[PASS] function exists: log::indent
log::table
[PASS] function exists: log::table
log::status
[PASS] function exists: log::status
log::run
[PASS] function exists: log::run
log::try
[PASS] function exists: log::try
log::plain
[PASS] function exists: log::plain
log::quiet
[PASS] function exists: log::quiet
log::verbose
[PASS] function exists: log::verbose
log::with_color
[PASS] function exists: log::with_color
log::without_color
[PASS] function exists: log::without_color

== level numbers / enabled ==
[PASS] level trace
[PASS] level debug
[PASS] level info
[PASS] level warn
[PASS] level error
[PASS] level off
[PASS] level unknown defaults info
[PASS] enabled info at default
[PASS] debug disabled at default
[PASS] warn enabled at info
[PASS] info disabled at warn
[PASS] error enabled under quiet
[PASS] info disabled under quiet

== color / strip / unicode ==
[PASS] color disabled by NO_COLOR
[FAIL] color forced contains escape
  want: [**]
  got : [hello]
[FAIL] color forced contains reset
  want: [**]
  got : [hello]
[PASS] strip ansi
[PASS] ascii symbol ok
[PASS] ascii symbol error
[PASS] ascii symbol item

== stdout helpers ==
[PASS] print stdout
[PASS] line stdout
[PASS] raw stdout
[PASS] quiet suppresses print
[PASS] quiet suppresses line
[PASS] quiet suppresses raw

== stderr basic logs ==
[PASS] info has tag
[PASS] info has msg
[PASS] ok has tag
[PASS] ok has msg
[PASS] success alias ok
[PASS] warn has tag
[PASS] warning alias warn
[PASS] error has tag
[PASS] fail alias error
[PASS] done has tag
[PASS] step has tag

== debug / trace ==
[PASS] debug hidden by default
[PASS] debug visible with DEBUG=1
[PASS] debug visible with LOG_LEVEL=debug
[PASS] trace hidden by default
[PASS] trace visible with TRACE=1
[PASS] trace visible with LOG_LEVEL=trace

== quiet / level filtering ==
[PASS] quiet suppresses info
[PASS] quiet keeps error
[PASS] LOG_LEVEL warn suppresses info
[PASS] LOG_LEVEL warn keeps warn
[PASS] LOG_LEVEL warn keeps error

== timestamp ==
[PASS] timestamp includes message
[PASS] timestamp date format

== format helpers ==
[PASS] title contains text
[PASS] title underline
[PASS] section format
[PASS] subsection format
[PASS] hr width
[PASS] kv key
[PASS] kv value
[PASS] pair alias key
[PASS] pair alias value
[PASS] list item one
[PASS] list item spaces
[PASS] list item star
[PASS] item output
[PASS] cmd prefix
[PASS] quote first
[PASS] quote second
[PASS] indent first
[PASS] indent second
[PASS] table name
[PASS] table gun
[PASS] table lang
[PASS] table bash

== status ==
[PASS] status ok
[PASS] status warn
[PASS] status error
[PASS] status debug hidden default
[PASS] status unknown info

== fatal / die ==
[PASS] fatal returns non-zero
[PASS] fatal exact return code
[PASS] die exits exact code

== run / try ==
[PASS] run prints command
[PASS] run executes command
[PASS] run returns command code
[PASS] try success command
[PASS] try success output
[PASS] try success log
[PASS] try failure returns command code
[PASS] try failure message

== wrappers ==
[PASS] without_color disables ansi
[FAIL] with_color forces ansi
  want: [**]
  got : [hello]
[PASS] quiet wrapper suppresses line

== result ==

pass: 140
fail: 3
Error: Process completed with exit code 1.

[MACOS]
Run "/opt/homebrew/bin/bash" tool/parts/builtin/test.sh

== syntax / static checks ==
[PASS] bash -n target
[PASS] shellcheck skipped

== public api ==
log::is_tty
[PASS] function exists: log::is_tty
log::is_err_tty
[PASS] function exists: log::is_err_tty
log::is_quiet
[PASS] function exists: log::is_quiet
log::is_verbose
[PASS] function exists: log::is_verbose
log::supports_color
[PASS] function exists: log::supports_color
log::supports_unicode
[PASS] function exists: log::supports_unicode
log::level_num
[PASS] function exists: log::level_num
log::enabled
[PASS] function exists: log::enabled
log::color
[PASS] function exists: log::color
log::strip
[PASS] function exists: log::strip
log::symbol
[PASS] function exists: log::symbol
log::timestamp
[PASS] function exists: log::timestamp
log::emit
[PASS] function exists: log::emit
log::print
[PASS] function exists: log::print
log::line
[PASS] function exists: log::line
log::raw
[PASS] function exists: log::raw
log::err
[PASS] function exists: log::err
log::info
[PASS] function exists: log::info
log::ok
[PASS] function exists: log::ok
log::success
[PASS] function exists: log::success
log::done
[PASS] function exists: log::done
log::warn
[PASS] function exists: log::warn
log::warning
[PASS] function exists: log::warning
log::error
[PASS] function exists: log::error
log::fail
[PASS] function exists: log::fail
log::debug
[PASS] function exists: log::debug
log::trace
[PASS] function exists: log::trace
log::step
[PASS] function exists: log::step
log::fatal
[PASS] function exists: log::fatal
log::die
[PASS] function exists: log::die
log::title
[PASS] function exists: log::title
log::section
[PASS] function exists: log::section
log::subsection
[PASS] function exists: log::subsection
log::hr
[PASS] function exists: log::hr
log::kv
[PASS] function exists: log::kv
log::pair
[PASS] function exists: log::pair
log::list
[PASS] function exists: log::list
log::item
[PASS] function exists: log::item
log::cmd
[PASS] function exists: log::cmd
log::quote
[PASS] function exists: log::quote
log::indent
[PASS] function exists: log::indent
log::table
[PASS] function exists: log::table
log::status
[PASS] function exists: log::status
log::run
[PASS] function exists: log::run
log::try
[PASS] function exists: log::try
log::plain
[PASS] function exists: log::plain
log::quiet
[PASS] function exists: log::quiet
log::verbose
[PASS] function exists: log::verbose
log::with_color
[PASS] function exists: log::with_color
log::without_color
[PASS] function exists: log::without_color

== level numbers / enabled ==
[PASS] level trace
[PASS] level debug
[PASS] level info
[PASS] level warn
[PASS] level error
[PASS] level off
[PASS] level unknown defaults info
[PASS] enabled info at default
[PASS] debug disabled at default
[PASS] warn enabled at info
[PASS] info disabled at warn
[PASS] error enabled under quiet
[PASS] info disabled under quiet

== color / strip / unicode ==
[PASS] color disabled by NO_COLOR
[FAIL] color forced contains escape
  want: [**]
  got : [hello]
[FAIL] color forced contains reset
  want: [**]
  got : [hello]
[PASS] strip ansi
[PASS] ascii symbol ok
[PASS] ascii symbol error
[PASS] ascii symbol item

== stdout helpers ==
[PASS] print stdout
[PASS] line stdout
[PASS] raw stdout
[PASS] quiet suppresses print
[PASS] quiet suppresses line
[PASS] quiet suppresses raw

== stderr basic logs ==
[PASS] info has tag
[PASS] info has msg
[PASS] ok has tag
[PASS] ok has msg
[PASS] success alias ok
[PASS] warn has tag
[PASS] warning alias warn
[PASS] error has tag
[PASS] fail alias error
[PASS] done has tag
[PASS] step has tag

== debug / trace ==
[PASS] debug hidden by default
[PASS] debug visible with DEBUG=1
[PASS] debug visible with LOG_LEVEL=debug
[PASS] trace hidden by default
[PASS] trace visible with TRACE=1
[PASS] trace visible with LOG_LEVEL=trace

== quiet / level filtering ==
[PASS] quiet suppresses info
[PASS] quiet keeps error
[PASS] LOG_LEVEL warn suppresses info
[PASS] LOG_LEVEL warn keeps warn
[PASS] LOG_LEVEL warn keeps error

== timestamp ==
[PASS] timestamp includes message
[PASS] timestamp date format

== format helpers ==
[PASS] title contains text
[PASS] title underline
[PASS] section format
[PASS] subsection format
[PASS] hr width
[PASS] kv key
[PASS] kv value
[PASS] pair alias key
[PASS] pair alias value
[PASS] list item one
[PASS] list item spaces
[PASS] list item star
[PASS] item output
[PASS] cmd prefix
[PASS] quote first
[PASS] quote second
[PASS] indent first
[PASS] indent second
[PASS] table name
[PASS] table gun
[PASS] table lang
[PASS] table bash

== status ==
[PASS] status ok
[PASS] status warn
[PASS] status error
[PASS] status debug hidden default
[PASS] status unknown info

== fatal / die ==
[PASS] fatal returns non-zero
[PASS] fatal exact return code
[PASS] die exits exact code

== run / try ==
[PASS] run prints command
[PASS] run executes command
[PASS] run returns command code
[PASS] try success command
[PASS] try success output
[PASS] try success log
[PASS] try failure returns command code
[PASS] try failure message

== wrappers ==
[PASS] without_color disables ansi
[FAIL] with_color forces ansi
  want: [**]
  got : [hello]
[PASS] quiet wrapper suppresses line

== result ==

pass: 140
fail: 3
Error: Process completed with exit code 1.

[WINDOWS]
Run "bash" tool/parts/builtin/test.sh

== syntax / static checks ==
[PASS] bash -n target
[PASS] shellcheck skipped

== public api ==
log::is_tty
[PASS] function exists: log::is_tty
log::is_err_tty
[PASS] function exists: log::is_err_tty
log::is_quiet
[PASS] function exists: log::is_quiet
log::is_verbose
[PASS] function exists: log::is_verbose
log::supports_color
[PASS] function exists: log::supports_color
log::supports_unicode
[PASS] function exists: log::supports_unicode
log::level_num
[PASS] function exists: log::level_num
log::enabled
[PASS] function exists: log::enabled
log::color
[PASS] function exists: log::color
log::strip
[PASS] function exists: log::strip
log::symbol
[PASS] function exists: log::symbol
log::timestamp
[PASS] function exists: log::timestamp
log::emit
[PASS] function exists: log::emit
log::print
[PASS] function exists: log::print
log::line
[PASS] function exists: log::line
log::raw
[PASS] function exists: log::raw
log::err
[PASS] function exists: log::err
log::info
[PASS] function exists: log::info
log::ok
[PASS] function exists: log::ok
log::success
[PASS] function exists: log::success
log::done
[PASS] function exists: log::done
log::warn
[PASS] function exists: log::warn
log::warning
[PASS] function exists: log::warning
log::error
[PASS] function exists: log::error
log::fail
[PASS] function exists: log::fail
log::debug
[PASS] function exists: log::debug
log::trace
[PASS] function exists: log::trace
log::step
[PASS] function exists: log::step
log::fatal
[PASS] function exists: log::fatal
log::die
[PASS] function exists: log::die
log::title
[PASS] function exists: log::title
log::section
[PASS] function exists: log::section
log::subsection
[PASS] function exists: log::subsection
log::hr
[PASS] function exists: log::hr
log::kv
[PASS] function exists: log::kv
log::pair
[PASS] function exists: log::pair
log::list
[PASS] function exists: log::list
log::item
[PASS] function exists: log::item
log::cmd
[PASS] function exists: log::cmd
log::quote
[PASS] function exists: log::quote
log::indent
[PASS] function exists: log::indent
log::table
[PASS] function exists: log::table
log::status
[PASS] function exists: log::status
log::run
[PASS] function exists: log::run
log::try
[PASS] function exists: log::try
log::plain
[PASS] function exists: log::plain
log::quiet
[PASS] function exists: log::quiet
log::verbose
[PASS] function exists: log::verbose
log::with_color
[PASS] function exists: log::with_color
log::without_color
[PASS] function exists: log::without_color

== level numbers / enabled ==
[PASS] level trace
[PASS] level debug
[PASS] level info
[PASS] level warn
[PASS] level error
[PASS] level off
[PASS] level unknown defaults info
[PASS] enabled info at default
[PASS] debug disabled at default
[PASS] warn enabled at info
[PASS] info disabled at warn
[PASS] error enabled under quiet
[PASS] info disabled under quiet

== color / strip / unicode ==
[PASS] color disabled by NO_COLOR
[PASS] color forced contains escape
[PASS] color forced contains reset
[PASS] strip ansi
[PASS] ascii symbol ok
[PASS] ascii symbol error
[PASS] ascii symbol item

== stdout helpers ==
[PASS] print stdout
[PASS] line stdout
[PASS] raw stdout
[PASS] quiet suppresses print
[PASS] quiet suppresses line
[PASS] quiet suppresses raw

== stderr basic logs ==
[PASS] info has tag
[PASS] info has msg
[PASS] ok has tag
[PASS] ok has msg
[PASS] success alias ok
[PASS] warn has tag
[PASS] warning alias warn
[PASS] error has tag
[PASS] fail alias error
[PASS] done has tag
[PASS] step has tag

== debug / trace ==
[PASS] debug hidden by default
[PASS] debug visible with DEBUG=1
[PASS] debug visible with LOG_LEVEL=debug
[PASS] trace hidden by default
[PASS] trace visible with TRACE=1
[PASS] trace visible with LOG_LEVEL=trace

== quiet / level filtering ==
[PASS] quiet suppresses info
[PASS] quiet keeps error
[PASS] LOG_LEVEL warn suppresses info
[PASS] LOG_LEVEL warn keeps warn
[PASS] LOG_LEVEL warn keeps error

== timestamp ==
[PASS] timestamp includes message
[PASS] timestamp date format

== format helpers ==
[PASS] title contains text
[PASS] title underline
[PASS] section format
[PASS] subsection format
[PASS] hr width
[PASS] kv key
[PASS] kv value
[PASS] pair alias key
[PASS] pair alias value
[PASS] list item one
[PASS] list item spaces
[PASS] list item star
[PASS] item output
[PASS] cmd prefix
[PASS] quote first
[PASS] quote second
[PASS] indent first
[PASS] indent second
[PASS] table name
[PASS] table gun
[PASS] table lang
[PASS] table bash

== status ==
[PASS] status ok
[PASS] status warn
[PASS] status error
[PASS] status debug hidden default
[PASS] status unknown info

== fatal / die ==
[PASS] fatal returns non-zero
[PASS] fatal exact return code
[PASS] die exits exact code

== run / try ==
[PASS] run prints command
[PASS] run executes command
[PASS] run returns command code
[PASS] try success command
[PASS] try success output
[PASS] try success log
[PASS] try failure returns command code
[PASS] try failure message

== wrappers ==
[PASS] without_color disables ansi
[PASS] with_color forces ansi
[PASS] quiet wrapper suppresses line

== result ==

pass: 143
fail: 0
