codingmaster@codingmstr:/var/www/projects/gun$ bash tool/parts/builtin/test.sh

== syntax / static checks ==
[PASS] bash -n cast.sh
[PASS] bash -n daily.sh
[PASS] shellcheck cast.sh
[PASS] shellcheck daily.sh

== public api ==
int
[PASS] function exists: int
uint
[PASS] function exists: uint
float
[PASS] function exists: float
number
[PASS] function exists: number
abs
[PASS] function exists: abs
char
[PASS] function exists: char
str
[PASS] function exists: str
bool
[PASS] function exists: bool
is_int
[PASS] function exists: is_int
is_uint
[PASS] function exists: is_uint
is_float
[PASS] function exists: is_float
is_number
[PASS] function exists: is_number
is_char
[PASS] function exists: is_char
is_str
[PASS] function exists: is_str
is_bool
[PASS] function exists: is_bool
is_true
[PASS] function exists: is_true
is_false
[PASS] function exists: is_false
is_list
[PASS] function exists: is_list
is_map
[PASS] function exists: is_map
typeof
[PASS] function exists: typeof
defined
[PASS] function exists: defined
filled
[PASS] function exists: filled
missed
[PASS] function exists: missed
empty
[PASS] function exists: empty
use
[PASS] function exists: use
not
[PASS] function exists: not
default
[PASS] function exists: default
coalesce
[PASS] function exists: coalesce
assert_eq
[PASS] function exists: assert_eq
assert_ne
[PASS] function exists: assert_ne

== int ==
[PASS] int empty
[PASS] int missing arg
[PASS] int true
[PASS] int yes
[PASS] int y
[PASS] int on
[PASS] int false
[PASS] int no
[PASS] int n
[PASS] int off
[PASS] int positive
[PASS] int negative
[PASS] int plus
[PASS] int spaces
[PASS] int prefix number
[PASS] int from float
[PASS] int from negative float
[PASS] int from leading dot
[PASS] int invalid

== uint ==
[PASS] uint empty
[PASS] uint positive
[PASS] uint plus stripped
[PASS] uint negative clamps zero
[PASS] uint true
[PASS] uint false
[PASS] uint float
[PASS] uint invalid

== float / number ==
[PASS] float empty
[PASS] float true
[PASS] float false
[PASS] float int
[PASS] float plus int
[PASS] float negative int
[PASS] float decimal
[PASS] float trailing dot
[PASS] float leading dot
[PASS] float plus leading dot
[PASS] float negative leading dot
[PASS] float prefix
[PASS] float invalid
[PASS] number alias

== abs / char / str / bool ==
[PASS] abs positive
[PASS] abs negative
[PASS] abs plus
[PASS] abs bool true
[PASS] abs invalid
[PASS] char empty
[PASS] char ascii
[PASS] char digit
[PASS] char star
[PASS] str empty
[PASS] str preserves spaces
[PASS] str special
[PASS] bool true
[PASS] bool yes
[PASS] bool y
[PASS] bool on
[PASS] bool 1
[PASS] bool false
[PASS] bool no
[PASS] bool 0
[PASS] bool invalid
[PASS] bool empty

== is_int / is_uint / is_float / is_number ==
[PASS] is_int accepts: 0
[PASS] is_int accepts: 1
[PASS] is_int accepts: -1
[PASS] is_int accepts: +1
[PASS] is_int accepts: 123
[PASS] is_int accepts:   -7
[PASS] is_int accepts: true
[PASS] is_int accepts: false
[PASS] is_int accepts: yes
[PASS] is_int accepts: no
[PASS] is_int accepts: on
[PASS] is_int accepts: off
[PASS] is_int accepts: y
[PASS] is_int accepts: n
[PASS] is_int rejects:
[PASS] is_int rejects: 1.2
[PASS] is_int rejects: .2
[PASS] is_int rejects: abc
[PASS] is_int rejects: --1
[PASS] is_int rejects: 1x
[PASS] is_uint accepts: 0
[PASS] is_uint accepts: 1
[PASS] is_uint accepts: +1
[PASS] is_uint accepts: 123
[PASS] is_uint accepts:   +7
[PASS] is_uint accepts: true
[PASS] is_uint accepts: false
[PASS] is_uint accepts: yes
[PASS] is_uint accepts: no
[PASS] is_uint rejects: -1
[PASS] is_uint rejects: 1.2
[PASS] is_uint rejects: .2
[PASS] is_uint rejects: abc
[PASS] is_uint rejects:
[PASS] is_float accepts: 0
[PASS] is_number accepts: 0
[PASS] is_float accepts: 1
[PASS] is_number accepts: 1
[PASS] is_float accepts: -1
[PASS] is_number accepts: -1
[PASS] is_float accepts: +1
[PASS] is_number accepts: +1
[PASS] is_float accepts: 1.2
[PASS] is_number accepts: 1.2
[PASS] is_float accepts: -1.2
[PASS] is_number accepts: -1.2
[PASS] is_float accepts: +1.2
[PASS] is_number accepts: +1.2
[PASS] is_float accepts: .5
[PASS] is_number accepts: .5
[PASS] is_float accepts: -.5
[PASS] is_number accepts: -.5
[PASS] is_float accepts: +.5
[PASS] is_number accepts: +.5
[PASS] is_float accepts: 5.
[PASS] is_number accepts: 5.
[PASS] is_float accepts:   7.0
[PASS] is_number accepts:   7.0
[PASS] is_float accepts: true
[PASS] is_number accepts: true
[PASS] is_float accepts: false
[PASS] is_number accepts: false
[PASS] is_float accepts: yes
[PASS] is_number accepts: yes
[PASS] is_float accepts: no
[PASS] is_number accepts: no
[PASS] is_float rejects:
[PASS] is_number rejects:
[PASS] is_float rejects: .
[PASS] is_number rejects: .
[PASS] is_float rejects: +
[PASS] is_number rejects: +
[PASS] is_float rejects: -
[PASS] is_number rejects: -
[PASS] is_float rejects: +.
[PASS] is_number rejects: +.
[PASS] is_float rejects: -.
[PASS] is_number rejects: -.
[PASS] is_float rejects: abc
[PASS] is_number rejects: abc
[PASS] is_float rejects: 1.2.3
[PASS] is_number rejects: 1.2.3

== is_bool / is_true / is_false ==
[PASS] is_bool accepts: 1
[PASS] is_bool accepts: 0
[PASS] is_bool accepts: true
[PASS] is_bool accepts: false
[PASS] is_bool accepts: yes
[PASS] is_bool accepts: no
[PASS] is_bool accepts: y
[PASS] is_bool accepts: n
[PASS] is_bool accepts: on
[PASS] is_bool accepts: off
[PASS] is_bool rejects:
[PASS] is_bool rejects: maybe
[PASS] is_bool rejects: 2
[PASS] is_bool rejects: enabled
[PASS] is_bool rejects: disabled
[PASS] is_true accepts: 1
[PASS] is_false rejects true value: 1
[PASS] is_true accepts: true
[PASS] is_false rejects true value: true
[PASS] is_true accepts: yes
[PASS] is_false rejects true value: yes
[PASS] is_true accepts: y
[PASS] is_false rejects true value: y
[PASS] is_true accepts: on
[PASS] is_false rejects true value: on
[PASS] is_true rejects: 0
[PASS] is_false accepts non-true: 0
[PASS] is_true rejects: false
[PASS] is_false accepts non-true: false
[PASS] is_true rejects: no
[PASS] is_false accepts non-true: no
[PASS] is_true rejects: n
[PASS] is_false accepts non-true: n
[PASS] is_true rejects: off
[PASS] is_false accepts non-true: off
[PASS] is_true rejects:
[PASS] is_false accepts non-true:
[PASS] is_true rejects: maybe
[PASS] is_false accepts non-true: maybe

== is_char / is_str / is_list / is_map ==
[PASS] is_char empty rejects
[PASS] is_char one ascii
[PASS] is_char two ascii rejects
[PASS] is_char star
[PASS] is_str literal
[PASS] is_str scalar var name
[PASS] is_str empty scalar var name
[PASS] is_str list var rejects
[PASS] is_str map var rejects
[PASS] is_list arr
[PASS] is_list map rejects
[PASS] is_list scalar rejects
[PASS] is_list missing rejects
[PASS] is_map map
[PASS] is_map arr rejects
[PASS] is_map scalar rejects
[PASS] is_map missing rejects

== typeof values ==
[PASS] typeof empty literal
[PASS] typeof bool true
[PASS] typeof bool false
[PASS] typeof int
[PASS] typeof negative int
[PASS] typeof float
[PASS] typeof leading dot float
[PASS] typeof char
[PASS] typeof str
[PASS] typeof invalid str

== typeof variables ==
[PASS] typeof var int
[PASS] typeof var float
[PASS] typeof var bool
[PASS] typeof var char
[PASS] typeof var str
[PASS] typeof var empty
[PASS] typeof var list
[PASS] typeof var map

== defined / missed / empty / filled ==
[PASS] defined empty var
[PASS] defined filled var
[PASS] defined missing var rejects
[PASS] missed existing empty var rejects
[PASS] missed existing filled var rejects
[PASS] missed missing var accepts
[PASS] empty empty value
[PASS] empty filled value rejects
[PASS] filled value
[PASS] filled empty rejects

== default / coalesce / not ==
[PASS] default keeps filled
[PASS] default uses fallback
[PASS] default empty fallback
[PASS] default preserves spaces
[PASS] coalesce first
[PASS] coalesce skips empty
[PASS] coalesce preserves spaces
[PASS] coalesce all empty fails
[PASS] not false command
[PASS] not true command
[PASS] not is_true false
[PASS] not is_true true

== assertions ==
[PASS] assert_eq equal
[PASS] assert_eq different fails
[PASS] assert_ne different
[PASS] assert_ne equal fails

== use loader ==
[PASS] use file module silent
[PASS] use file function works
[PASS] use file loaded once initial
[PASS] use file module second time silent
[PASS] use file loaded once after repeat
[PASS] use dir mod module silent
[PASS] use dir function works
[PASS] use dir loaded once initial
[PASS] use dir mod second time silent
[PASS] use dir loaded once after repeat
[PASS] use missing module fails
[PASS] use empty module fails
[PASS] circular use detected

== subshell integration / source order ==
[PASS] source cast then daily typeof
[PASS] source cast then daily default

== result ==

pass: 294
fail: 0
codingmaster@codingmstr:/var/www/projects/gun$
