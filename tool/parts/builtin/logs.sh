codingmaster@codingmstr:/var/www/projects/gun$ bash -n tool/parts/builtin/string.sh
codingmaster@codingmstr:/var/www/projects/gun$ shellcheck tool/parts/builtin/string.sh
codingmaster@codingmstr:/var/www/projects/gun$ time bash tool/parts/builtin/test.sh

== existence / public api ==
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
str::normalize
[PASS] function exists: str::normalize
str::truncate
[PASS] function exists: str::truncate
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
str::bool
[PASS] function exists: str::bool
str::index
[PASS] function exists: str::index
str::last_index
[PASS] function exists: str::last_index
str::starts_with
[PASS] function exists: str::starts_with
str::ends_with
[PASS] function exists: str::ends_with
str::find
[PASS] function exists: str::find
str::contains
[PASS] function exists: str::contains
str::equals
[PASS] function exists: str::equals
str::compare
[PASS] function exists: str::compare
str::index_icase
[PASS] function exists: str::index_icase
str::last_index_icase
[PASS] function exists: str::last_index_icase
str::starts_with_icase
[PASS] function exists: str::starts_with_icase
str::ends_with_icase
[PASS] function exists: str::ends_with_icase
str::find_icase
[PASS] function exists: str::find_icase
str::contains_icase
[PASS] function exists: str::contains_icase
str::equals_icase
[PASS] function exists: str::equals_icase
str::compare_icase
[PASS] function exists: str::compare_icase
str::len
[PASS] function exists: str::len
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
str::slug
[PASS] function exists: str::slug
str::capitalize
[PASS] function exists: str::capitalize
str::uncapitalize
[PASS] function exists: str::uncapitalize
str::constant
[PASS] function exists: str::constant
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
str::escape_regex
[PASS] function exists: str::escape_regex
str::escape_sed
[PASS] function exists: str::escape_sed
str::escape_json
[PASS] function exists: str::escape_json
str::json_quote
[PASS] function exists: str::json_quote

== case / trim / newline cleanup ==
[PASS] lower ascii
[PASS] upper ascii
[PASS] ltrim spaces tabs
[PASS] rtrim spaces tabs
[PASS] trim spaces tabs newlines
[PASS] trim all blank
[PASS] trim no-op
[PASS] chomp LF
[PASS] chomp CR
[PASS] chomp CRLF
[PASS] chomp LFCR
[PASS] chomp many trailing
[PASS] chomp does not remove internal CRLF

== repeat / slice / reverse ==
[PASS] repeat zero
[PASS] repeat one
[PASS] repeat power pattern
[PASS] repeat empty string
[PASS] repeat rejects negative
[PASS] repeat rejects plus
[PASS] repeat rejects text
[PASS] slice no count
[PASS] slice count
[PASS] slice count zero
[PASS] slice negative offset
[PASS] slice start zero
[PASS] slice beyond end
[PASS] slice rejects bad start
[PASS] slice rejects bad count negative
[PASS] slice rejects bad count text
[PASS] reverse empty
[PASS] reverse one
[PASS] reverse ascii
[PASS] reverse punctuation

== normalize / truncate ==
[PASS] normalize spaces
[PASS] normalize custom dash
[PASS] normalize custom multi uses first char
[PASS] normalize empty
[PASS] normalize blank
[PASS] truncate shorter
[PASS] truncate exact
[PASS] truncate default
[PASS] truncate custom tail
[PASS] truncate tail longer than max
[PASS] truncate max zero
[PASS] truncate empty
[PASS] truncate rejects negative max
[PASS] truncate rejects text max

== padding / join / wrapping / quote / bool ==
[PASS] pad_left zero
[PASS] pad_left number
[PASS] pad_left no-op
[PASS] pad_left multi char uses first
[PASS] pad_left empty ch becomes space
[PASS] pad_right number
[PASS] pad_right no-op
[PASS] pad_right multi char uses first
[PASS] pad_center odd
[PASS] pad_center even remainder right
[PASS] pad_center no-op
[PASS] pad_left rejects bad width
[PASS] pad_right rejects bad width
[PASS] pad_center rejects bad width
[PASS] join no args
[PASS] join one
[PASS] join three
[PASS] join empty values
[PASS] join multi separator
[PASS] wrap same
[PASS] wrap different
[PASS] wrap empty
[PASS] quote spaces returns success
[PASS] bool true on
[PASS] bool false off
[PASS] bool rejects maybe
[PASS] bool rejects empty

== search / compare exact ==
[PASS] index first
[PASS] index start hit zero
[PASS] index empty needle zero
[PASS] index repeated first
[PASS] index miss
[PASS] index longer needle miss
[PASS] last_index last
[PASS] last_index needle
[PASS] last_index empty needle len
[PASS] last_index miss
[PASS] find alias
[PASS] contains hit
[PASS] contains miss
[PASS] contains empty needle false
[PASS] starts_with hit
[PASS] starts_with miss
[PASS] starts_with empty false
[PASS] ends_with hit
[PASS] ends_with miss
[PASS] ends_with empty false
[PASS] equals hit
[PASS] equals miss
[PASS] compare equal
[PASS] compare less
[PASS] compare greater

== search / compare icase ==
[PASS] index_icase hit
[PASS] index_icase empty needle
[PASS] index_icase miss
[PASS] last_index_icase hit
[PASS] find_icase hit
[PASS] contains_icase hit
[PASS] contains_icase lowercase hit
[PASS] contains_icase empty false
[PASS] contains_icase miss
[PASS] starts_with_icase hit
[PASS] starts_with_icase miss
[PASS] ends_with_icase hit
[PASS] ends_with_icase miss
[PASS] equals_icase hit
[PASS] equals_icase miss
[PASS] compare_icase equal
[PASS] compare_icase less
[PASS] compare_icase greater

== length / count / chars ==
[PASS] len empty
[PASS] len ascii
[PASS] count empty needle
[PASS] count miss
[PASS] count non-overlap aa in aaaa
[PASS] count separator
[PASS] count newline
[PASS] lines_count empty
[PASS] lines_count one
[PASS] lines_count two
[PASS] lines_count trailing newline
[PASS] first_char empty
[PASS] first_char normal
[PASS] last_char empty
[PASS] last_char normal

== before / after / between ==
[PASS] before first delimiter
[PASS] before miss returns original
[PASS] before empty delimiter returns original
[PASS] after first delimiter
[PASS] after miss fails
[PASS] after empty delimiter fails
[PASS] before_last delimiter
[PASS] before_last miss original
[PASS] after_last delimiter
[PASS] after_last miss fails
[PASS] between simple
[PASS] between last
[PASS] between missing left fails
[PASS] between missing right returns rest

== replace / remove / affixes ==
[PASS] replace all simple
[PASS] replace first simple
[PASS] replace last simple
[PASS] replace empty from no-op
[PASS] replace_first empty from no-op
[PASS] replace_last empty from no-op
[PASS] replace literal star
[PASS] replace literal question
[PASS] replace literal bracket
[PASS] replace literal slash
[PASS] remove all
[PASS] remove first
[PASS] remove last
[PASS] remove_prefix hit
[PASS] remove_prefix miss
[PASS] remove_prefix empty no-op
[PASS] remove_suffix hit
[PASS] remove_suffix miss
[PASS] remove_suffix empty no-op
[PASS] ensure_prefix hit
[PASS] ensure_prefix add
[PASS] ensure_prefix empty no-op
[PASS] ensure_suffix hit
[PASS] ensure_suffix add
[PASS] ensure_suffix empty no-op

== words / naming conversions ==
[PASS] words empty
[PASS] words separators
[PASS] words camel acronym
[PASS] words mixed digits split
[PASS] words consecutive separators
[PASS] title
[PASS] camel
[PASS] pascal
[PASS] kebab
[PASS] snake
[PASS] train
[PASS] slug alias
[PASS] constant
[PASS] capitalize empty
[PASS] capitalize word
[PASS] uncapitalize empty
[PASS] uncapitalize word
[PASS] swapcase ascii

== split / lines / indent / dedent ==
[PASS] split simple
[PASS] split keeps empty middle
[PASS] split keeps empty tail len
[PASS] split keeps empty tail first
[PASS] split keeps empty tail second
[PASS] split keeps empty head len
[PASS] split keeps empty head first
[PASS] split keeps empty head second
[PASS] split empty input emits one empty field
[PASS] split empty input field empty
[PASS] split empty separator fails
[PASS] lines empty
[PASS] lines one
[PASS] lines multi command-substitution strips final newline
[PASS] indent empty
[PASS] indent one
[PASS] indent multi
[PASS] indent preserves middle empty
[PASS] dedent empty
[PASS] dedent simple
[PASS] dedent blank lines
[PASS] dedent no indent

== predicates ==
[PASS] is_empty empty
[PASS] is_empty space false
[PASS] is_blank empty
[PASS] is_blank spaces tabs newlines
[PASS] is_blank text false
[PASS] is_lower a
[PASS] is_lower A false
[PASS] is_lower multi false
[PASS] is_lower empty false
[PASS] is_upper A
[PASS] is_upper a false
[PASS] is_upper multi false
[PASS] is_alpha lower
[PASS] is_alpha upper
[PASS] is_alpha digit false
[PASS] is_alpha underscore false
[PASS] is_digit
[PASS] is_digit letter false
[PASS] is_digit multi false
[PASS] is_alnum letter
[PASS] is_alnum digit
[PASS] is_alnum symbol false
[PASS] is_char one
[PASS] is_char empty false
[PASS] is_char many false
[PASS] is_int positive
[PASS] is_int negative
[PASS] is_int zero
[PASS] is_int empty false
[PASS] is_int float false
[PASS] is_uint zero
[PASS] is_uint number
[PASS] is_uint signed false
[PASS] is_uint negative false
[PASS] is_float int-compatible
[PASS] is_float decimal
[PASS] is_float leading dot
[PASS] is_float trailing dot
[PASS] is_float dot false
[PASS] is_float exponent unsupported false
[PASS] is_bool true
[PASS] is_bool on uppercase
[PASS] is_bool zero
[PASS] is_bool maybe false
[PASS] is_bool empty false
[PASS] is_email basic
[PASS] is_email subdomain
[PASS] is_email no tld false
[PASS] is_email spaces false
[PASS] is_url http
[PASS] is_url https
[PASS] is_url ftp false
[PASS] is_url spaces false
[PASS] is_slug simple
[PASS] is_slug uppercase false
[PASS] is_slug leading dash false
[PASS] is_slug trailing dash false
[PASS] is_identifier simple
[PASS] is_identifier caps
[PASS] is_identifier leading digit false
[PASS] is_identifier dash false
[PASS] is_ascii true
[PASS] is_ascii false

== escaping ==
[PASS] escape_sed slash amp backslash
[PASS] escape_regex literal matches raw
[PASS] escape_regex literal does not overmatch
[PASS] escape_json specials
[PASS] escape_json control U+0001
[PASS] json_quote quoted
[PASS] json_quote empty

== properties / invariants ==
[PASS] property trim idempotent
[PASS] property normalize idempotent
[PASS] property lower idempotent
[PASS] property upper idempotent
[PASS] property snake stable
[PASS] property kebab stable
[PASS] property ensure_prefix idempotent
[PASS] property ensure_suffix idempotent
[PASS] property remove_prefix inverse simple
[PASS] property remove_suffix inverse simple

== summary ==

TOTAL=382 PASS=382 FAIL=0
GAME OVER: string.sh passed the savage suite.

real    0m0.300s
user    0m0.212s
sys     0m0.099s
codingmaster@codingmstr:/var/www/projects/gun$