codingmaster@codingmstr:/var/www/projects/gun$ bash -n tool/parts/builtin/input.sh
codingmaster@codingmstr:/var/www/projects/gun$ shellcheck tool/parts/builtin/input.sh
codingmaster@codingmstr:/var/www/projects/gun$ time bash tool/parts/builtin/test.sh
== input::get automated no-tty tests ==
[PASS] read plain line
[PASS] preserve spaces
[PASS] empty line without default
[PASS] empty line uses default
[PASS] EOF uses default
[PASS] EOF without default fails
[PASS] prompt does not pollute stdout

== input::read tests ==
[PASS] read plain text
[PASS] read multiline text via command substitution trims final newline
[PASS] read preserves final newline by byte count
[PASS] read empty stdin
[PASS] read file redirect preserves bytes
[PASS] read file redirect text via command substitution trims final newline

== input::lines tests ==
[PASS] rows
[PASS] rows_no_final
[PASS] rows_empty
[PASS] rows_file
[PASS] lines invalid target fails
[PASS] lines scalar target fails
[PASS] lines invalid target keeps old array untouched
[PASS] lines transactional invariant

== input::bool tests ==
[PASS] bool yes: y
[PASS] bool yes: yes
[PASS] bool yes: true
[PASS] bool yes: on
[PASS] bool yes: 1
[PASS] bool yes uppercase
[PASS] bool no: n
[PASS] bool no: no
[PASS] bool no: false
[PASS] bool no: off
[PASS] bool no: 0
[PASS] bool no uppercase
[PASS] bool empty uses default yes
[PASS] bool empty uses default no
[PASS] bool EOF uses default true
[PASS] bool retries then success
[PASS] bool invalid fails after tries
[PASS] bool zero tries normalized then invalid fails
[PASS] bool non-numeric tries normalized then invalid fails

== input::confirm tests ==
[PASS] confirm yes: y
[PASS] confirm yes: yes
[PASS] confirm yes: true
[PASS] confirm yes: on
[PASS] confirm yes: 1
[PASS] confirm no: n
[PASS] confirm no: no
[PASS] confirm no: false
[PASS] confirm no: off
[PASS] confirm no: 0
[PASS] confirm uppercase yes
[PASS] confirm uppercase no
[PASS] confirm default yes on empty
[PASS] confirm default no on empty
[PASS] confirm retries then yes
[PASS] confirm invalid fails after tries
[PASS] confirm zero tries normalized then invalid fails
[PASS] confirm non-numeric tries normalized then invalid fails

== input::password tests ==
[PASS] password fails without tty

== input::number tests ==
[PASS] int positive
[PASS] int negative
[PASS] int zero
[PASS] int default
[PASS] int retries then success
[PASS] int rejects float
[PASS] int rejects alpha
[PASS] int rejects empty without valid default
[PASS] uint positive
[PASS] uint zero
[PASS] uint default
[PASS] uint retries then success
[PASS] uint rejects negative
[PASS] uint rejects float
[PASS] uint rejects alpha
[PASS] float integer
[PASS] float decimal
[PASS] float negative integer
[PASS] float negative decimal
[PASS] float plus sign
[PASS] float leading dot
[PASS] float trailing dot
[PASS] float default
[PASS] float retries then success
[PASS] float rejects alpha
[PASS] float rejects double dot
[PASS] float rejects sign only
[PASS] number alias integer
[PASS] number alias float
[PASS] number alias leading dot
[PASS] number alias rejects alpha

== input::char / required / match / select tests ==
[PASS] char accepts ascii
[PASS] char accepts star
[PASS] char accepts digit
[PASS] char accepts arabic glyph
[PASS] char default
[PASS] char rejects empty without default
[PASS] char rejects multi ascii
[PASS] char rejects multi words
[PASS] required accepts value
[PASS] required preserves spaces
[PASS] required default
[PASS] required retries then success
[PASS] required rejects empty after tries
[PASS] match accepts slug
[PASS] match accepts email-ish
[PASS] match default valid
[PASS] match retries then success
[PASS] match rejects invalid after tries
[PASS] match empty pattern fails
[PASS] select picks first
[PASS] select picks middle
[PASS] select picks last
[PASS] select retries then success
[PASS] select supports spaces
[PASS] select supports empty item
[PASS] select supports star
[PASS] select missing items fails
[PASS] select invalid choice fails after tries
[PASS] select non-number fails after tries

== input::path / file / dir tests ==
[PASS] path any accepts missing
[PASS] path exists accepts file
[PASS] path exists accepts dir
[PASS] path file accepts file
[PASS] path dir accepts dir
[PASS] path readable accepts file
[PASS] path writable accepts dir
[PASS] path executable accepts executable
[PASS] path supports file with spaces
[PASS] path supports dir with spaces
[PASS] path empty input uses valid default
[PASS] path retries then success
[PASS] path invalid mode fails
[PASS] path empty fails
[PASS] path file rejects missing
[PASS] path file rejects dir
[PASS] path dir rejects file
[PASS] path exists rejects missing
[PASS] path executable rejects normal file
[PASS] file wrapper accepts file
[PASS] file wrapper supports default
[PASS] file wrapper retries then success
[PASS] file wrapper rejects dir
[PASS] file wrapper rejects missing
[PASS] dir wrapper accepts dir
[PASS] dir wrapper supports default
[PASS] dir wrapper retries then success
[PASS] dir wrapper rejects file
[PASS] dir wrapper rejects missing

== result ==
pass: 148
fail: 0

real    0m2.245s
user    0m0.828s
sys     0m0.230s
codingmaster@codingmstr:/var/www/projects/gun$
