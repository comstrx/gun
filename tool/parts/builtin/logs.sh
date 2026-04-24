codingmaster@codingmstr:/var/www/projects/gun$ bash -n tool/parts/builtin/string.sh
codingmaster@codingmstr:/var/www/projects/gun$ shellcheck tool/parts/builtin/string.sh
codingmaster@codingmstr:/var/www/projects/gun$ bash tool/parts/builtin/test.sh

== syntax / existence ==
str::len
[PASS] function exists: str::len
str::lower
[PASS] function exists: str::lower
str::upper
[PASS] function exists: str::upper
str::ltrim
[PASS] function exists: str::ltrim
str::rtrim
[PASS] function exists: str::rtrim
str::trim
[PASS] function exists: str::trim
str::chomp
[PASS] function exists: str::chomp
str::repeat
[PASS] function exists: str::repeat
str::slice
[PASS] function exists: str::slice
str::reverse
[PASS] function exists: str::reverse
str::truncate
[PASS] function exists: str::truncate
str::normalize
[PASS] function exists: str::normalize
str::pad_left
[PASS] function exists: str::pad_left
str::pad_right
[PASS] function exists: str::pad_right
str::pad_center
[PASS] function exists: str::pad_center
str::join_by
[PASS] function exists: str::join_by
str::wrap
[PASS] function exists: str::wrap
str::quote
[PASS] function exists: str::quote
str::index
[PASS] function exists: str::index
str::index_ci
[PASS] function exists: str::index_ci
str::last_index
[PASS] function exists: str::last_index
str::last_index_ci
[PASS] function exists: str::last_index_ci
str::find
[PASS] function exists: str::find
str::find_ci
[PASS] function exists: str::find_ci
str::contains
[PASS] function exists: str::contains
str::contains_ci
[PASS] function exists: str::contains_ci
str::starts_with
[PASS] function exists: str::starts_with
str::starts_with_ci
[PASS] function exists: str::starts_with_ci
str::ends_with
[PASS] function exists: str::ends_with
str::ends_with_ci
[PASS] function exists: str::ends_with_ci
str::equals
[PASS] function exists: str::equals
str::equals_ci
[PASS] function exists: str::equals_ci
str::count
[PASS] function exists: str::count
str::lines_count
[PASS] function exists: str::lines_count
str::first_char
[PASS] function exists: str::first_char
str::last_char
[PASS] function exists: str::last_char
str::before
[PASS] function exists: str::before
str::after
[PASS] function exists: str::after
str::before_last
[PASS] function exists: str::before_last
str::after_last
[PASS] function exists: str::after_last
str::between
[PASS] function exists: str::between
str::between_last
[PASS] function exists: str::between_last
str::replace
[PASS] function exists: str::replace
str::replace_first
[PASS] function exists: str::replace_first
str::replace_last
[PASS] function exists: str::replace_last
str::remove
[PASS] function exists: str::remove
str::remove_first
[PASS] function exists: str::remove_first
str::remove_last
[PASS] function exists: str::remove_last
str::remove_prefix
[PASS] function exists: str::remove_prefix
str::remove_suffix
[PASS] function exists: str::remove_suffix
str::ensure_prefix
[PASS] function exists: str::ensure_prefix
str::ensure_suffix
[PASS] function exists: str::ensure_suffix
str::words
[PASS] function exists: str::words
str::title
[PASS] function exists: str::title
str::camel
[PASS] function exists: str::camel
str::pascal
[PASS] function exists: str::pascal
str::kebab
[PASS] function exists: str::kebab
str::snake
[PASS] function exists: str::snake
str::train
[PASS] function exists: str::train
str::constant
[PASS] function exists: str::constant
str::slug
[PASS] function exists: str::slug
str::capitalize
[PASS] function exists: str::capitalize
str::uncapitalize
[PASS] function exists: str::uncapitalize
str::swapcase
[PASS] function exists: str::swapcase
str::split
[PASS] function exists: str::split
str::lines
[PASS] function exists: str::lines
str::indent
[PASS] function exists: str::indent
str::dedent
[PASS] function exists: str::dedent
str::is_empty
[PASS] function exists: str::is_empty
str::is_blank
[PASS] function exists: str::is_blank
str::is_lower
[PASS] function exists: str::is_lower
str::is_upper
[PASS] function exists: str::is_upper
str::is_alpha
[PASS] function exists: str::is_alpha
str::is_digit
[PASS] function exists: str::is_digit
str::is_alnum
[PASS] function exists: str::is_alnum
str::is_char
[PASS] function exists: str::is_char
str::is_int
[PASS] function exists: str::is_int
str::is_uint
[PASS] function exists: str::is_uint
str::is_float
[PASS] function exists: str::is_float
str::is_bool
[PASS] function exists: str::is_bool
str::is_email
[PASS] function exists: str::is_email
str::is_url
[PASS] function exists: str::is_url
str::is_slug
[PASS] function exists: str::is_slug
str::is_identifier
[PASS] function exists: str::is_identifier
str::bool
[PASS] function exists: str::bool
str::escape_regex
[PASS] function exists: str::escape_regex
str::escape_sed
[PASS] function exists: str::escape_sed
str::escape_json
[PASS] function exists: str::escape_json
str::json_quote
[PASS] function exists: str::json_quote

== basic transform ==
[PASS] len empty
[PASS] len ascii
[PASS] lower
[PASS] upper
[PASS] trim spaces
[PASS] ltrim tabs/spaces
[PASS] rtrim tabs/spaces
[PASS] chomp LF
[PASS] chomp CRLF once

== repeat / slice / reverse / truncate / normalize ==
[PASS] repeat zero
[PASS] repeat one
[PASS] repeat many
[PASS] repeat rejects negative
[PASS] repeat rejects text
[PASS] slice from start
[PASS] slice count
[PASS] slice negative
[PASS] slice bad start
[PASS] slice bad count
[PASS] reverse empty
[PASS] reverse ascii
[PASS] truncate short
[PASS] truncate exact
[PASS] truncate zero
[PASS] truncate default tail
[PASS] truncate tiny tail clipped
[PASS] normalize spaces
[PASS] normalize custom sep

== padding / join / wrap / quote ==
[PASS] pad left
[PASS] pad right
[PASS] pad center odd
[PASS] pad center even remainder right
[PASS] pad no-op
[PASS] pad bad width
[PASS] join none
[PASS] join one
[PASS] join many
[PASS] wrap symmetric
[PASS] wrap same
[PASS] quote returns something

== search / compare ==
[PASS] index first
[PASS] index empty needle
[PASS] index miss rc
[PASS] index_ci
[PASS] last_index
[PASS] last_index empty needle
[PASS] last_index miss rc
[PASS] last_index_ci
[PASS] contains
[PASS] contains empty needle false
[PASS] contains miss
[PASS] contains_ci
[PASS] starts_with
[PASS] starts_with empty false
[PASS] starts_with miss
[PASS] starts_with_ci
[PASS] ends_with
[PASS] ends_with empty false
[PASS] ends_with miss
[PASS] ends_with_ci
[PASS] equals
[PASS] equals miss
[PASS] equals_ci

== count / lines / char ==
[PASS] count non-overlap
[PASS] count miss
[PASS] count empty needle
[PASS] lines_count empty
[PASS] lines_count one
[PASS] lines_count two
[PASS] first_char empty
[PASS] first_char
[PASS] last_char empty
[PASS] last_char

== before / after / between ==
[PASS] before hit
[PASS] before miss returns original
[PASS] before empty delimiter returns original
[PASS] after hit
[PASS] after miss rc
[PASS] after empty delimiter rc
[PASS] before_last hit
[PASS] after_last hit
[PASS] between hit
[PASS] between_last hit

== replace / remove / prefix / suffix ==
[PASS] replace all simple
[PASS] replace first simple
[PASS] replace last simple
[PASS] replace literal star
[PASS] replace literal question
[PASS] replace literal bracket
[PASS] remove all
[PASS] remove first
[PASS] remove last
[PASS] remove_prefix hit
[PASS] remove_prefix miss
[PASS] remove_suffix hit
[PASS] remove_suffix miss
[PASS] ensure_prefix hit
[PASS] ensure_prefix miss
[PASS] ensure_prefix add
[PASS] ensure_suffix hit
[PASS] ensure_suffix add

== case conversions ==
[PASS] words camel acronym
[PASS] words mixed
[PASS] title
[PASS] camel
[PASS] pascal
[PASS] kebab
[PASS] snake
[PASS] train
[PASS] constant
[PASS] slug alias
[PASS] capitalize
[PASS] uncapitalize
[PASS] swapcase

== split / lines / indent / dedent ==
[PASS] split simple
[PASS] split keeps empty middle
[PASS] split keeps empty tail len
[PASS] split keeps empty tail first
[PASS] split keeps empty tail second
[PASS] split empty sep rc
[PASS] lines empty
[PASS] lines one
[PASS] indent multi
[PASS] dedent simple
[PASS] dedent blank lines

== predicates ==
[PASS] is_empty true
[PASS] is_empty false
[PASS] is_blank empty
[PASS] is_blank spaces
[PASS] is_blank false
[PASS] is_lower
[PASS] is_lower multi false
[PASS] is_upper
[PASS] is_alpha lower
[PASS] is_alpha upper
[PASS] is_alpha digit false
[PASS] is_digit
[PASS] is_alnum alpha
[PASS] is_alnum digit
[PASS] is_alnum symbol false
[PASS] is_char one
[PASS] is_char empty false
[PASS] is_char many false
[PASS] is_int positive
[PASS] is_int negative
[PASS] is_int float false
[PASS] is_uint zero
[PASS] is_uint signed false
[PASS] is_float int-compatible
[PASS] is_float decimal
[PASS] is_float leading dot
[PASS] is_float trailing dot
[PASS] is_float bad false
[PASS] is_bool true
[PASS] is_bool false input
[PASS] is_email simple
[PASS] is_email bad false
[PASS] is_url http
[PASS] is_url https
[PASS] is_url ftp false
[PASS] is_slug
[PASS] is_slug uppercase false
[PASS] is_identifier
[PASS] is_identifier leading digit false

== bool conversion ==
[PASS] bool true
[PASS] bool false
[PASS] bool invalid rc

== escaping ==
[PASS] escape_sed slash amp backslash
[PASS] escape_regex produces matching literal regex
[PASS] escape_json specials
[PASS] escape_json control U+0001
[PASS] json_quote

== properties / invariants ==
[PASS] property trim idempotent
[PASS] property lower idempotent
[PASS] property upper idempotent
[PASS] property snake is stable through words
[PASS] property kebab is stable through words

== summary ==

TOTAL=266 PASS=266 FAIL=0
LOCKED: string.sh passed the brutal suite.
codingmaster@codingmstr:/var/www/projects/gun$
