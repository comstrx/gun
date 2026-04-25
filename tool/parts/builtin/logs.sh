codingmaster@codingmstr:/var/www/projects/gun$ bash -n tool/parts/builtin/map.sh
codingmaster@codingmstr:/var/www/projects/gun$ shellcheck tool/parts/builtin/map.sh
codingmaster@codingmstr:/var/www/projects/gun$ time bash tool/parts/builtin/test.sh

== existence / public api ==
map::init
[PASS] function exists: map::init
map::valid
[PASS] function exists: map::valid
map::len
[PASS] function exists: map::len
map::empty
[PASS] function exists: map::empty
map::filled
[PASS] function exists: map::filled
map::has
[PASS] function exists: map::has
map::get
[PASS] function exists: map::get
map::set
[PASS] function exists: map::set
map::put
[PASS] function exists: map::put
map::del
[PASS] function exists: map::del
map::delete
[PASS] function exists: map::delete
map::set_once
[PASS] function exists: map::set_once
map::replace
[PASS] function exists: map::replace
map::clear
[PASS] function exists: map::clear
map::keys0
[PASS] function exists: map::keys0
map::values0
[PASS] function exists: map::values0
map::items0
[PASS] function exists: map::items0
map::keys
[PASS] function exists: map::keys
map::values
[PASS] function exists: map::values
map::items
[PASS] function exists: map::items
map::merge
[PASS] function exists: map::merge
map::concat
[PASS] function exists: map::concat
map::copy
[PASS] function exists: map::copy
map::only
[PASS] function exists: map::only
map::without
[PASS] function exists: map::without
map::each
[PASS] function exists: map::each
map::map
[PASS] function exists: map::map
map::filter
[PASS] function exists: map::filter
map::all
[PASS] function exists: map::all
map::any
[PASS] function exists: map::any
map::none
[PASS] function exists: map::none
map::print
[PASS] function exists: map::print
map::str
[PASS] function exists: map::str
map::from
[PASS] function exists: map::from
map::from_pairs
[PASS] function exists: map::from_pairs
map::from_lines
[PASS] function exists: map::from_lines

== init / valid / invalid names ==
[PASS] init creates assoc map
[PASS] valid existing assoc map
[PASS] len empty
[PASS] empty true
[PASS] filled false
[PASS] valid scalar false
[PASS] init scalar false
[PASS] init invalid empty
[PASS] init invalid starts digit
[PASS] init invalid dash
[PASS] valid missing false

== set / put / get / has / len / empty / filled ==
[PASS] set name
[PASS] set empty value
[PASS] set key with spaces
[PASS] set key with star
[PASS] set key with equals
[PASS] set empty key fails
[PASS] get name
[PASS] get empty value
[PASS] get missing default
[PASS] get empty key returns default
[PASS] has name
[PASS] has empty value key
[PASS] has missing false
[PASS] has empty key false
[PASS] len after set
[PASS] empty false
[PASS] filled true
[PASS] put alias set
[PASS] put alias get

== set_once / replace / del / delete / clear ==
[PASS] set_once existing returns ok
[PASS] set_once existing unchanged
[PASS] set_once missing writes
[PASS] set_once missing value
[PASS] set_once empty key fails
[PASS] replace existing
[PASS] replace existing value
[PASS] replace missing fails
[PASS] replace empty key fails
[PASS] del existing
[PASS] del removed missing
[PASS] del missing fails
[PASS] del empty key fails
[PASS] delete alias existing
[PASS] delete removed missing
[PASS] clear map
[PASS] clear len zero
[PASS] clear empty true

== from_pairs ==
[PASS] from_pairs creates map
[PASS] fp
[PASS] from_pairs duplicate last wins
[PASS] duplicate value
[PASS] duplicate len
[PASS] from_pairs zero pairs creates empty
[PASS] from_pairs zero len
[PASS] from_pairs odd args fails
[PASS] from_pairs empty key fails

== from / from_lines / str ==
[PASS] from default newline
[PASS] mf
[PASS] from custom separators
[PASS] mf2
[PASS] from duplicate last wins
[PASS] from duplicate value
[PASS] from trailing item sep
[PASS] mf4
[PASS] from empty string creates empty
[PASS] from empty len
[PASS] from empty item_sep fails
[PASS] from empty pair_sep fails
[PASS] from empty key fails
[PASS] from_lines default
[PASS] ml
[PASS] from_lines custom sep
[PASS] ml2
[PASS] from_lines no final newline
[PASS] from_lines no final newline value
[PASS] from_lines empty sep fails
[PASS] from_lines empty key fails
[PASS] str returns parseable text
[PASS] str_dst
[PASS] str default newline parseable
[PASS] str_dst2
[PASS] str empty item sep fails
[PASS] str empty pair sep fails

== keys0 / values0 / items0 ==
[PASS] kv:keys0
[PASS] kv:values0
[PASS] kv:items0
[PASS] keys0 supports newline key
[PASS] values0 supports newline value
[PASS] weird:items0

== keys / values / items / print ==
[PASS] keys printable
[PASS] values printable
[PASS] items printable
[PASS] print alias items

== copy / merge / concat ==
[PASS] copy src dst
[PASS] dst
[PASS] copy is independent
[PASS] copy changed dst
[PASS] copy source unchanged
[PASS] copy to self safe
[PASS] src
[PASS] merge overwrites and adds
[PASS] left
[PASS] right
[PASS] merge self safe
[PASS] self_merge
[PASS] concat alias merge
[PASS] concat_left

== only / without ==
[PASS] only selected keys
[PASS] public
[PASS] user
[PASS] only self-reference safe
[PASS] user
[PASS] without removes selected
[PASS] safe_user
[PASS] secret_user
[PASS] without self-reference safe
[PASS] secret_user

== callbacks each / map / filter / all / any / none ==
[PASS] each collect
[PASS] each collected all
[PASS] each stops on callback failure
[PASS] map upper values
[PASS] cb_upper
[PASS] map self-reference safe
[PASS] cb
[PASS] filter nonempty values
[PASS] cb_filtered
[PASS] filter self-reference safe
[PASS] cb2
[PASS] missing callback each fails
[PASS] missing callback map fails
[PASS] missing callback filter fails
[PASS] all nonempty true
[PASS] all nonempty false
[PASS] any key is name true
[PASS] any never false
[PASS] none never true
[PASS] none key is name false
[PASS] any value is admin true

== failure paths / non maps ==
[PASS] len scalar fails
[PASS] empty scalar fails
[PASS] filled scalar fails
[PASS] has scalar fails
[PASS] get scalar fails
[PASS] set scalar fails
[PASS] del scalar fails
[PASS] set_once scalar fails
[PASS] replace scalar fails
[PASS] clear scalar fails
[PASS] keys0 scalar fails
[PASS] values0 scalar fails
[PASS] items0 scalar fails
[PASS] copy scalar fails
[PASS] merge scalar left fails
[PASS] merge scalar right fails
[PASS] only scalar fails
[PASS] without scalar fails
[PASS] each scalar fails
[PASS] map scalar fails
[PASS] filter scalar fails
[PASS] all scalar fails
[PASS] any scalar fails
[PASS] str scalar fails
[PASS] copy bad target fails
[PASS] only bad target fails
[PASS] without bad target fails
[PASS] map bad target fails
[PASS] filter bad target fails

== property / invariants ==
[PASS] copy invariant
[PASS] copy dump equals original
[PASS] str/from roundtrip with rare separators
[PASS] roundtrip dump equals original
[PASS] merge empty into prop
[PASS] merge empty does not change
[PASS] merge empty invariant
[PASS] only all keys equals original
[PASS] only all invariant
[PASS] without no keys equals original
[PASS] without none invariant

== transactional from failures ==
[PASS] from_pairs failure keeps old map
[PASS] from_pairs transactional invariant
[PASS] from failure keeps old map
[PASS] from transactional invariant
[PASS] from_lines failure keeps old map
[PASS] from_lines transactional invariant

== unset weird keys ==
[PASS] del key with bracket
[PASS] bracket key removed
[PASS] del key with space
[PASS] space key removed
[PASS] del key with star
[PASS] star key removed
[PASS] del key with newline
[PASS] newline key removed

== transactional failures ==
[PASS] from_pairs failure keeps old map
[PASS] from_pairs transactional invariant
[PASS] from failure keeps old map
[PASS] from transactional invariant
[PASS] from_lines failure keeps old map
[PASS] from_lines transactional invariant

== delete weird keys ==
[PASS] del bracket key
[PASS] bracket key removed
[PASS] del space key
[PASS] space key removed
[PASS] del star key
[PASS] star key removed
[PASS] del dollar key
[PASS] dollar key removed
[PASS] del newline key
[PASS] newline key removed

== result ==

== result ==
total: 245
pass : 245
fail : 0

real    0m0.702s
user    0m0.431s
sys     0m0.118s
codingmaster@codingmstr:/var/www/projects/gun$
