codingmaster@codingmstr:/var/www/projects/gun$ bash -n tool/parts/builtin/list.sh
codingmaster@codingmstr:/var/www/projects/gun$ shellcheck tool/parts/builtin/list.sh
codingmaster@codingmstr:/var/www/projects/gun$ time bash tool/parts/builtin/test.sh

== existence / public api ==
list::init
[PASS] function exists: list::init
list::valid
[PASS] function exists: list::valid
list::len
[PASS] function exists: list::len
list::has
[PASS] function exists: list::has
list::count
[PASS] function exists: list::count
list::empty
[PASS] function exists: list::empty
list::filled
[PASS] function exists: list::filled
list::push
[PASS] function exists: list::push
list::pop
[PASS] function exists: list::pop
list::unshift
[PASS] function exists: list::unshift
list::shift
[PASS] function exists: list::shift
list::clear
[PASS] function exists: list::clear
list::get
[PASS] function exists: list::get
list::set
[PASS] function exists: list::set
list::put
[PASS] function exists: list::put
list::insert
[PASS] function exists: list::insert
list::first
[PASS] function exists: list::first
list::last
[PASS] function exists: list::last
list::index
[PASS] function exists: list::index
list::last_index
[PASS] function exists: list::last_index
list::remove
[PASS] function exists: list::remove
list::remove_at
[PASS] function exists: list::remove_at
list::remove_first
[PASS] function exists: list::remove_first
list::remove_last
[PASS] function exists: list::remove_last
list::replace
[PASS] function exists: list::replace
list::replace_first
[PASS] function exists: list::replace_first
list::replace_last
[PASS] function exists: list::replace_last
list::concat
[PASS] function exists: list::concat
list::copy
[PASS] function exists: list::copy
list::slice
[PASS] function exists: list::slice
list::reverse
[PASS] function exists: list::reverse
list::reversed
[PASS] function exists: list::reversed
list::unique
[PASS] function exists: list::unique
list::sort
[PASS] function exists: list::sort
list::each
[PASS] function exists: list::each
list::map
[PASS] function exists: list::map
list::filter
[PASS] function exists: list::filter
list::all
[PASS] function exists: list::all
list::any
[PASS] function exists: list::any
list::none
[PASS] function exists: list::none
list::from
[PASS] function exists: list::from
list::from_lines
[PASS] function exists: list::from_lines
list::from_args
[PASS] function exists: list::from_args
list::join
[PASS] function exists: list::join
list::print
[PASS] function exists: list::print
list::args
[PASS] function exists: list::args

== init / valid / invalid names ==
[PASS] init creates array
[PASS] valid existing array
[PASS] init len empty
[PASS] empty true
[PASS] filled false
[PASS] valid scalar false
[PASS] init scalar false
[PASS] init invalid empty
[PASS] init invalid starts digit
[PASS] init invalid dash
[PASS] valid missing false

== push / len / empty / filled / count / has ==
[PASS] len initial
[PASS] empty false
[PASS] filled true
[PASS] has b
[PASS] has empty item
[PASS] has z false
[PASS] count a
[PASS] count empty
[PASS] count missing
[PASS] items

== first / last / get ==
[PASS] first value
[PASS] last value
[PASS] first default ignored
[PASS] last default ignored
[PASS] first empty default
[PASS] last empty default
[PASS] get 0
[PASS] get 1
[PASS] get -1
[PASS] get -2
[PASS] get bad index default
[PASS] get out default
[PASS] get negative out default

== set / put / insert ==
[PASS] set middle
[PASS] a
[PASS] set negative last
[PASS] a
[PASS] set index == len fails
[PASS] set out fails
[PASS] set bad index fails
[PASS] put index == len appends sparse-safe
[PASS] a
[PASS] put existing replaces
[PASS] a
[PASS] put gap fails
[PASS] put negative fails
[PASS] insert middle multiple
[PASS] a
[PASS] insert start
[PASS] a
[PASS] insert end
[PASS] a
[PASS] insert negative before last
[PASS] a
[PASS] insert bad index fails
[PASS] insert out positive fails
[PASS] insert out negative fails

== pop / shift / unshift / clear ==
[PASS] pop into target
[PASS] pop target value
[PASS] q
[PASS] pop into target again
[PASS] pop target value again
[PASS] q
[PASS] shift into target
[PASS] shift target value
[PASS] q
[PASS] pop empty fails
[PASS] shift empty fails
[PASS] unshift multiple
[PASS] q
[PASS] shift into target again
[PASS] shift target value again
[PASS] q
[PASS] pop invalid target fails
[PASS] shift invalid target fails
[PASS] clear list
[PASS] clear len zero
[PASS] q

== index / last_index / remove_at ==
[PASS] index first a
[PASS] last_index a
[PASS] index empty
[PASS] last_index empty
[PASS] index missing fails
[PASS] last_index missing fails
[PASS] remove_at target
[PASS] remove_at target value
[PASS] idx
[PASS] remove_at negative target
[PASS] remove_at target value empty
[PASS] idx
[PASS] remove_at out fails
[PASS] remove_at bad index fails
[PASS] remove_at invalid target fails

== remove / remove_first / remove_last ==
[PASS] remove all a
[PASS] r
[PASS] remove all empty
[PASS] r
[PASS] remove_first a
[PASS] r
[PASS] remove_last a
[PASS] r
[PASS] remove_first missing fails
[PASS] remove_last missing fails

== replace / replace_first / replace_last ==
[PASS] replace all a
[PASS] rp
[PASS] replace empty
[PASS] rp
[PASS] replace missing fails
[PASS] replace_first
[PASS] rp
[PASS] replace_last
[PASS] rp
[PASS] replace_first missing fails
[PASS] replace_last missing fails

== concat / copy / slice ==
[PASS] concat
[PASS] left
[PASS] right
[PASS] copy
[PASS] copied
[PASS] left
[PASS] copied
[PASS] slice from 1 count 3
[PASS] sliced
[PASS] slice negative start
[PASS] sliced2
[PASS] slice start beyond len empty
[PASS] sliced3
[PASS] slice negative far clamps zero
[PASS] sliced4
[PASS] slice bad target fails
[PASS] slice bad start fails
[PASS] slice bad count fails

== reverse / reversed ==
[PASS] reverse in-place
[PASS] rev
[PASS] reversed copy
[PASS] rev
[PASS] rev2
[PASS] reverse empty
[PASS] empty_list
[PASS] reversed bad target fails

== unique ==
[PASS] unique preserves first occurrence including empty
[PASS] u
[PASS] unique all empty
[PASS] u2

== sort ==
[PASS] sort asc
[PASS] s
[PASS] sort desc
[PASS] s
[PASS] sort bad order fails

== join / print / args ==
[PASS] join comma
[PASS] join empty sep
[PASS] print lines
[PASS] args alias lines
[PASS] print empty no output
[PASS] args empty no output

== from / from_args / from_lines ==
[PASS] fa
[PASS] from comma
[PASS] ff
[PASS] from multi sep
[PASS] fm
[PASS] from default newline
[PASS] fl
[PASS] from empty string gives one empty item
[PASS] fe
[PASS] from empty separator fails
[PASS] stdin_lines
[PASS] no_final_newline

== callbacks each / map / filter / all / any / none ==
[PASS] each collect
[PASS] cb_seen
[PASS] each stops on failure
[PASS] map upper
[PASS] mapped
[PASS] filter nonempty
[PASS] filtered
[PASS] missing callback each fails
[PASS] missing callback map fails
[PASS] missing callback filter fails
[PASS] all nonempty true
[PASS] all nonempty false
[PASS] any is a true
[PASS] any missing false
[PASS] none missing true
[PASS] none is a false

== failure paths / non arrays ==
[PASS] len scalar fails
[PASS] push scalar fails
[PASS] get scalar fails
[PASS] set scalar fails
[PASS] insert scalar fails
[PASS] remove scalar fails
[PASS] concat scalar fails
[PASS] copy bad target fails

== property / invariants ==
[PASS] reverse twice returns original
[PASS] reverse twice second
[PASS] reverse twice invariant
[PASS] copy then join equal
[PASS] copy content invariant
[PASS] slice full equals original
[PASS] slice full invariant

== self reference safety ==
[PASS] copy to self preserves
[PASS] self_copy
[PASS] slice to self preserves selected
[PASS] self_slice
[PASS] map to self works
[PASS] self_map
[PASS] filter to self works
[PASS] self_filter
[PASS] concat self duplicates once
[PASS] self_concat

== result ==
total: 255
pass : 255
fail : 0

real    0m0.246s
user    0m0.174s
sys     0m0.070s
codingmaster@codingmstr:/var/www/projects/gun$