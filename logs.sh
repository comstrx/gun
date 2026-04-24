[[ LINUX ]]

Run "bash" tool/parts/builtin/test.sh
------------------------------------------------------------
[TEST] env.sh hard test
[BASH] 5.2.21(1)-release
------------------------------------------------------------
[PASS] valid simple
[PASS] valid underscore
[PASS] valid digits tail
[PASS] invalid empty
[PASS] invalid digit start
[PASS] invalid dash
[PASS] invalid dot
[PASS] invalid space
[PASS] invalid injection
[PASS] has unset
[PASS] missing unset
[PASS] has empty
[PASS] empty empty
[PASS] filled empty
[PASS] missing empty
[PASS] has filled
[PASS] filled filled
[PASS] empty filled
[PASS] missing filled
[PASS] get default unset
[PASS] set normal
[PASS] get normal
[PASS] equal true
[PASS] equal false
[PASS] set empty
[PASS] get empty
[PASS] set special
[PASS] get special
[PASS] set multiline
[PASS] get multiline
[PASS] set_once keeps existing call
[PASS] set_once keeps existing value
[PASS] set_once writes missing
[PASS] set_once missing value
[PASS] unset existing
[PASS] unset invalid
[PASS] true 1
[PASS] true true
[PASS] true TRUE
[PASS] true True
[PASS] true yes
[PASS] true YES
[PASS] true y
[PASS] true Y
[PASS] true on
[PASS] true ON
[PASS] false 0
[PASS] false false
[PASS] false FALSE
[PASS] false False
[PASS] false no
[PASS] false NO
[PASS] false n
[PASS] false N
[PASS] false off
[PASS] false OFF
[PASS] true rejects maybe
[PASS] false rejects maybe
[PASS] true rejects empty
[PASS] false rejects empty
[PASS] has_any one
[PASS] has_any none
[PASS] has_all all
[PASS] has_all missing
[PASS] need success
[PASS] need_all success
[PASS] need_any success
[PASS] set_all
[PASS] get_all A
[PASS] get_all B
[PASS] get_all empty
[PASS] set_all invalid pair
[PASS] set_all invalid key
[PASS] set_all_once
[PASS] set_all_once keeps
[PASS] set_all_once sets
[PASS] unset_all
[PASS] unset_all gone A
[PASS] unset_all gone B
[PASS] unset_all gone C
[PASS] keys A
[PASS] keys B
[PASS] keys EMPTY
[PASS] values aaa
[PASS] values bbb
[PASS] list A
[PASS] list B
[PASS] list EMPTY
[PASS] prefix excludes PATH
[PASS] keys_ref
[PASS] values_ref
[PASS] list_ref
[PASS] keys_ref A
[PASS] values_ref aaa
[PASS] list_ref A
[PASS] map
[PASS] map A
[PASS] map B
[PASS] map EMPTY
[PASS] path_has /bin
[PASS] path_has /usr/bin
[PASS] path_has missing
[PASS] path_prepend new
[PASS] path_prepend result
[PASS] path_prepend duplicate
[PASS] path_prepend duplicate result
[PASS] path_append new
[PASS] path_append result
[PASS] path_append duplicate
[PASS] path_append duplicate result
[PASS] path_del middle
[PASS] path_del middle result
[PASS] path_del first
[PASS] path_del first result
[PASS] path_del last
[PASS] path_del last result
[PASS] path_del missing noop
[PASS] path_del missing result
[PASS] path_del exact only
[PASS] path_del exact result
[PASS] path_has semicolon
[PASS] path_del semicolon
[PASS] path_del semicolon result
[PASS] path_prepend semicolon
[PASS] path_prepend semicolon result
[PASS] path_append semicolon
[PASS] path_append semicolon result
[PASS] path_del refuses empty PATH
[PASS] path_del keeps PATH after deny
[PASS] path invalid key
[PASS] path empty dir prepend
[PASS] path empty dir append
[PASS] path empty dir del
[PASS] has invalid
[PASS] filled invalid
[PASS] empty invalid
[PASS] equal invalid
[PASS] true invalid
[PASS] false invalid
[PASS] set invalid
[PASS] set_once invalid
ENV_TEST_A=aaa
[PASS] get_all invalid
[PASS] unset_all invalid
[PASS] set_all_once invalid
------------------------------------------------------------
[RESULT] total=144 pass=144 fail=0

[[ MACOS ]]

Run "/opt/homebrew/bin/bash" tool/parts/builtin/test.sh
------------------------------------------------------------
[TEST] env.sh hard test
[BASH] 5.3.9(1)-release
------------------------------------------------------------
[PASS] valid simple
[PASS] valid underscore
[PASS] valid digits tail
[PASS] invalid empty
[PASS] invalid digit start
[PASS] invalid dash
[PASS] invalid dot
[PASS] invalid space
[PASS] invalid injection
[PASS] has unset
[PASS] missing unset
[PASS] has empty
[PASS] empty empty
[PASS] filled empty
[PASS] missing empty
[PASS] has filled
[PASS] filled filled
[PASS] empty filled
[PASS] missing filled
[PASS] get default unset
[PASS] set normal
[PASS] get normal
[PASS] equal true
[PASS] equal false
[PASS] set empty
[PASS] get empty
[PASS] set special
[PASS] get special
[PASS] set multiline
[PASS] get multiline
[PASS] set_once keeps existing call
[PASS] set_once keeps existing value
[PASS] set_once writes missing
[PASS] set_once missing value
[PASS] unset existing
[PASS] unset invalid
[PASS] true 1
[PASS] true true
[PASS] true TRUE
[PASS] true True
[PASS] true yes
[PASS] true YES
[PASS] true y
[PASS] true Y
[PASS] true on
[PASS] true ON
[PASS] false 0
[PASS] false false
[PASS] false FALSE
[PASS] false False
[PASS] false no
[PASS] false NO
[PASS] false n
[PASS] false N
[PASS] false off
[PASS] false OFF
[PASS] true rejects maybe
[PASS] false rejects maybe
[PASS] true rejects empty
[PASS] false rejects empty
[PASS] has_any one
[PASS] has_any none
[PASS] has_all all
[PASS] has_all missing
[PASS] need success
[PASS] need_all success
[PASS] need_any success
[PASS] set_all
[PASS] get_all A
[PASS] get_all B
[PASS] get_all empty
[PASS] set_all invalid pair
[PASS] set_all invalid key
[PASS] set_all_once
[PASS] set_all_once keeps
[PASS] set_all_once sets
[PASS] unset_all
[PASS] unset_all gone A
[PASS] unset_all gone B
[PASS] unset_all gone C
[PASS] keys A
[PASS] keys B
[PASS] keys EMPTY
[PASS] values aaa
[PASS] values bbb
[PASS] list A
[PASS] list B
[PASS] list EMPTY
[PASS] prefix excludes PATH
[PASS] keys_ref
[PASS] values_ref
[PASS] list_ref
[PASS] keys_ref A
[PASS] values_ref aaa
[PASS] list_ref A
[PASS] map
[PASS] map A
[PASS] map B
[PASS] map EMPTY
[PASS] path_has /bin
[PASS] path_has /usr/bin
[PASS] path_has missing
[PASS] path_prepend new
[PASS] path_prepend result
[PASS] path_prepend duplicate
[PASS] path_prepend duplicate result
[PASS] path_append new
[PASS] path_append result
[PASS] path_append duplicate
[PASS] path_append duplicate result
[PASS] path_del middle
[PASS] path_del middle result
[PASS] path_del first
[PASS] path_del first result
[PASS] path_del last
[PASS] path_del last result
[PASS] path_del missing noop
[PASS] path_del missing result
[PASS] path_del exact only
[PASS] path_del exact result
[PASS] path_has semicolon
[PASS] path_del semicolon
[PASS] path_del semicolon result
[PASS] path_prepend semicolon
[PASS] path_prepend semicolon result
[PASS] path_append semicolon
[PASS] path_append semicolon result
[PASS] path_del refuses empty PATH
[PASS] path_del keeps PATH after deny
[PASS] path invalid key
[PASS] path empty dir prepend
[PASS] path empty dir append
[PASS] path empty dir del
[PASS] has invalid
[PASS] filled invalid
[PASS] empty invalid
[PASS] equal invalid
[PASS] true invalid
[PASS] false invalid
[PASS] set invalid
[PASS] set_once invalid
ENV_TEST_A=aaa
[PASS] get_all invalid
[PASS] unset_all invalid
[PASS] set_all_once invalid
------------------------------------------------------------
[RESULT] total=144 pass=144 fail=0

[[ WINDOWS ]]

Run "bash" tool/parts/builtin/test.sh
------------------------------------------------------------
[TEST] env.sh hard test
[BASH] 5.2.37(1)-release
------------------------------------------------------------
[PASS] valid simple
[PASS] valid underscore
[PASS] valid digits tail
[PASS] invalid empty
[PASS] invalid digit start
[PASS] invalid dash
[PASS] invalid dot
[PASS] invalid space
[PASS] invalid injection
[PASS] has unset
[PASS] missing unset
[PASS] has empty
[PASS] empty empty
[PASS] filled empty
[PASS] missing empty
[PASS] has filled
[PASS] filled filled
[PASS] empty filled
[PASS] missing filled
[PASS] get default unset
[PASS] set normal
[PASS] get normal
[PASS] equal true
[PASS] equal false
[PASS] set empty
[PASS] get empty
[PASS] set special
[PASS] get special
[PASS] set multiline
[PASS] get multiline
[PASS] set_once keeps existing call
[PASS] set_once keeps existing value
[PASS] set_once writes missing
[PASS] set_once missing value
[PASS] unset existing
[PASS] unset invalid
[PASS] true 1
[PASS] true true
[PASS] true TRUE
[PASS] true True
[PASS] true yes
[PASS] true YES
[PASS] true y
[PASS] true Y
[PASS] true on
[PASS] true ON
[PASS] false 0
[PASS] false false
[PASS] false FALSE
[PASS] false False
[PASS] false no
[PASS] false NO
[PASS] false n
[PASS] false N
[PASS] false off
[PASS] false OFF
[PASS] true rejects maybe
[PASS] false rejects maybe
[PASS] true rejects empty
[PASS] false rejects empty
[PASS] has_any one
[PASS] has_any none
[PASS] has_all all
[PASS] has_all missing
[PASS] need success
[PASS] need_all success
[PASS] need_any success
[PASS] set_all
[PASS] get_all A
[PASS] get_all B
[PASS] get_all empty
[PASS] set_all invalid pair
[PASS] set_all invalid key
[PASS] set_all_once
[PASS] set_all_once keeps
[PASS] set_all_once sets
[PASS] unset_all
[PASS] unset_all gone A
[PASS] unset_all gone B
[PASS] unset_all gone C
[PASS] keys A
[PASS] keys B
[PASS] keys EMPTY
[PASS] values aaa
[PASS] values bbb
[PASS] list A
[PASS] list B
[PASS] list EMPTY
[PASS] prefix excludes PATH
[PASS] keys_ref
[PASS] values_ref
[PASS] list_ref
[PASS] keys_ref A
[PASS] values_ref aaa
[PASS] list_ref A
[PASS] map
[PASS] map A
[PASS] map B
[PASS] map EMPTY
[PASS] path_has /bin
[PASS] path_has /usr/bin
[PASS] path_has missing
[PASS] path_prepend new
[PASS] path_prepend result
[PASS] path_prepend duplicate
[PASS] path_prepend duplicate result
[PASS] path_append new
[PASS] path_append result
[PASS] path_append duplicate
[PASS] path_append duplicate result
[PASS] path_del middle
[PASS] path_del middle result
[PASS] path_del first
[PASS] path_del first result
[PASS] path_del last
[PASS] path_del last result
[PASS] path_del missing noop
[PASS] path_del missing result
[PASS] path_del exact only
[PASS] path_del exact result
[PASS] path_has semicolon
[PASS] path_del semicolon
[PASS] path_del semicolon result
[PASS] path_prepend semicolon
[PASS] path_prepend semicolon result
[PASS] path_append semicolon
[PASS] path_append semicolon result
[PASS] path_del refuses empty PATH
[PASS] path_del keeps PATH after deny
[PASS] path invalid key
[PASS] path empty dir prepend
[PASS] path empty dir append
[PASS] path empty dir del
[PASS] has invalid
[PASS] filled invalid
[PASS] empty invalid
[PASS] equal invalid
[PASS] true invalid
[PASS] false invalid
[PASS] set invalid
[PASS] set_once invalid
ENV_TEST_A=aaa
[PASS] get_all invalid
[PASS] unset_all invalid
[PASS] set_all_once invalid
------------------------------------------------------------
[RESULT] total=144 pass=144 fail=0
