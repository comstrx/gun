codingmaster@codingmstr:/var/www/projects/gun$ bash tool/parts/builtin/test.sh

▸ Gun Production Logger Showcase
================================
Program            : showcase-log.sh
Using              : /var/www/projects/gun/tool/parts/builtin/log.sh
Mode               : real CLI pipeline simulation

== Runtime Contract ==
App                  : gun
Environment          : production
Build ID             : 20260425143903
Artifact Dir         : /tmp/gun-showcase-artifact
Color                : yes
Unicode              : yes
Quiet                : no
Verbose              : no

== Display Modes ==
[INFO] Default flags + bright colors
[INFO] i Symbols enabled
[WARN] ⚠️ Emoji mode enabled
[2026-04-25 14:39:04] [STEP] Timestamp mode enabled
+ No flags, symbol only
No flags, no symbols: clean raw message
[WARN] No-color scoped wrapper

== Formatted Output ==

-- Key / Value --
Repository         : comstrx/gun
Branch             : main
Target             : release
Runtime            : bash

-- List --
  - deterministic output
  - quiet-safe rendering
  - failure output captured
  - terminal color fallback
  - progress and spinner support

-- Quoted Block --
│ This block simulates external command output.
│ It is rendered only when you choose to show it.
│ Useful for failed builds, deploy logs, and diagnostics.

-- Indented Block --
    src/
      runtime/
      builtins/
    target/
      release/

== Spinner Pipeline ==
[OK] Preparing workspace
[OK] Resolving Bash runtime
[OK] Compiling runtime entrypoint
[OK] Running static checks
[OK] Packaging artifact
[OK] Uploading artifact
[OK] Running smoke test

== Progress Renderer ==
Building release [██████████████████████████████████████] 100%
[DONE] Progress reached final state cleanly

== Failure Capture ==
[ERR] Deploying to production
│ connecting to production gateway...
│ checking deployment token...
│ boom: token expired for environment production
[WARN] Deploy failed intentionally for showcase
Captured exit code : 7

== Command Helpers ==
$ bash -c printf\ \"hello\ from\ log::run\\n\"
hello from log::run
$ bash -c printf\ \"test\ output\ hidden\?\ no\,\ this\ is\ direct\ try\ output\\n\"\;\ exit\ 0
test output hidden? no, this is direct try output
[OK] Command succeeded
[OK] try success branch
$ bash -c printf\ \"simulated\ failure\ output\\n\"\;\ exit\ 5
simulated failure output
[ERR] Command failed with exit code 5
[WARN] try returned code 5

== Summary ==
Workspace          : ready
Runtime            : resolved
Static Checks      : passed
Package            : created
Upload             : done
Deploy             : failed intentionally
======================================================
[DONE] Showcase completed
codingmaster@codingmstr:/var/www/projects/gun$ NO_COLOR=1 bash tool/parts/builtin/test.sh

▸ Gun Production Logger Showcase
================================
Program            : showcase-log.sh
Using              : /var/www/projects/gun/tool/parts/builtin/log.sh
Mode               : real CLI pipeline simulation

== Runtime Contract ==
App                  : gun
Environment          : production
Build ID             : 20260425143915
Artifact Dir         : /tmp/gun-showcase-artifact
Color                : no
Unicode              : yes
Quiet                : no
Verbose              : no

== Display Modes ==
[INFO] Default flags + bright colors
[INFO] i Symbols enabled
[WARN] ⚠️ Emoji mode enabled
[2026-04-25 14:39:15] [STEP] Timestamp mode enabled
+ No flags, symbol only
No flags, no symbols: clean raw message
[WARN] No-color scoped wrapper

== Formatted Output ==

-- Key / Value --
Repository         : comstrx/gun
Branch             : main
Target             : release
Runtime            : bash

-- List --
  - deterministic output
  - quiet-safe rendering
  - failure output captured
  - terminal color fallback
  - progress and spinner support

-- Quoted Block --
| This block simulates external command output.
| It is rendered only when you choose to show it.
| Useful for failed builds, deploy logs, and diagnostics.

-- Indented Block --
    src/
      runtime/
      builtins/
    target/
      release/

== Spinner Pipeline ==
[OK] Preparing workspace
[OK] Resolving Bash runtime
[OK] Compiling runtime entrypoint
[OK] Running static checks
[OK] Packaging artifact
[OK] Uploading artifact
[OK] Running smoke test

== Progress Renderer ==
Building release [██████████████████████████████████████] 100%
[DONE] Progress reached final state cleanly

== Failure Capture ==
[ERR] Deploying to production
| connecting to production gateway...
| checking deployment token...
| boom: token expired for environment production
[WARN] Deploy failed intentionally for showcase
Captured exit code : 7

== Command Helpers ==
$ bash -c printf\ \"hello\ from\ log::run\\n\"
hello from log::run
$ bash -c printf\ \"test\ output\ hidden\?\ no\,\ this\ is\ direct\ try\ output\\n\"\;\ exit\ 0
test output hidden? no, this is direct try output
[OK] Command succeeded
[OK] try success branch
$ bash -c printf\ \"simulated\ failure\ output\\n\"\;\ exit\ 5
simulated failure output
[ERR] Command failed with exit code 5
[WARN] try returned code 5

== Summary ==
Workspace          : ready
Runtime            : resolved
Static Checks      : passed
Package            : created
Upload             : done
Deploy             : failed intentionally
======================================================
[DONE] Showcase completed
codingmaster@codingmstr:/var/www/projects/gun$ LOG_COLOR=always LOG_SYMBOLS=1 bash tool/parts/builtin/test.sh

▸ Gun Production Logger Showcase
================================
Program            : showcase-log.sh
Using              : /var/www/projects/gun/tool/parts/builtin/log.sh
Mode               : real CLI pipeline simulation

== Runtime Contract ==
App                  : gun
Environment          : production
Build ID             : 20260425143926
Artifact Dir         : /tmp/gun-showcase-artifact
Color                : yes
Unicode              : yes
Quiet                : no
Verbose              : no

== Display Modes ==
[INFO] i Default flags + bright colors
[INFO] i Symbols enabled
[WARN] ⚠️ Emoji mode enabled
[2026-04-25 14:39:26] [STEP] > Timestamp mode enabled
+ No flags, symbol only
No flags, no symbols: clean raw message
[WARN] ! No-color scoped wrapper

== Formatted Output ==

-- Key / Value --
Repository         : comstrx/gun
Branch             : main
Target             : release
Runtime            : bash

-- List --
  - deterministic output
  - quiet-safe rendering
  - failure output captured
  - terminal color fallback
  - progress and spinner support

-- Quoted Block --
│ This block simulates external command output.
│ It is rendered only when you choose to show it.
│ Useful for failed builds, deploy logs, and diagnostics.

-- Indented Block --
    src/
      runtime/
      builtins/
    target/
      release/

== Spinner Pipeline ==
[OK] + Preparing workspace
[OK] + Resolving Bash runtime
[OK] + Compiling runtime entrypoint
[OK] + Running static checks
[OK] + Packaging artifact
[OK] + Uploading artifact
[OK] + Running smoke test

== Progress Renderer ==
Building release [██████████████████████████████████████] 100%
[DONE] + Progress reached final state cleanly

== Failure Capture ==
[ERR] x Deploying to production
│ connecting to production gateway...
│ checking deployment token...
│ boom: token expired for environment production
[WARN] ! Deploy failed intentionally for showcase
Captured exit code : 7

== Command Helpers ==
$ bash -c printf\ \"hello\ from\ log::run\\n\"
hello from log::run
$ bash -c printf\ \"test\ output\ hidden\?\ no\,\ this\ is\ direct\ try\ output\\n\"\;\ exit\ 0
test output hidden? no, this is direct try output
[OK] + Command succeeded
[OK] + try success branch
$ bash -c printf\ \"simulated\ failure\ output\\n\"\;\ exit\ 5
simulated failure output
[ERR] x Command failed with exit code 5
[WARN] ! try returned code 5

== Summary ==
Workspace          : ready
Runtime            : resolved
Static Checks      : passed
Package            : created
Upload             : done
Deploy             : failed intentionally
======================================================
[DONE] + Showcase completed
codingmaster@codingmstr:/var/www/projects/gun$ LOG_COLOR=always LOG_SYMBOLS=1 LOG_EMOJIS=1 bash tool/parts/builtin/test.sh

▸ Gun Production Logger Showcase
================================
Program            : showcase-log.sh
Using              : /var/www/projects/gun/tool/parts/builtin/log.sh
Mode               : real CLI pipeline simulation

== Runtime Contract ==
App                  : gun
Environment          : production
Build ID             : 20260425143935
Artifact Dir         : /tmp/gun-showcase-artifact
Color                : yes
Unicode              : yes
Quiet                : no
Verbose              : no

== Display Modes ==
[INFO] ℹ  Default flags + bright colors
[INFO] ℹ  Symbols enabled
[WARN] ⚠️ Emoji mode enabled
[2026-04-25 14:39:35] [STEP] 🚀 Timestamp mode enabled
✅ No flags, symbol only
No flags, no symbols: clean raw message
[WARN] ⚠️ No-color scoped wrapper

== Formatted Output ==

-- Key / Value --
Repository         : comstrx/gun
Branch             : main
Target             : release
Runtime            : bash

-- List --
  • deterministic output
  • quiet-safe rendering
  • failure output captured
  • terminal color fallback
  • progress and spinner support

-- Quoted Block --
│ This block simulates external command output.
│ It is rendered only when you choose to show it.
│ Useful for failed builds, deploy logs, and diagnostics.

-- Indented Block --
    src/
      runtime/
      builtins/
    target/
      release/

== Spinner Pipeline ==
[OK] ✅ Preparing workspace
[OK] ✅ Resolving Bash runtime
[OK] ✅ Compiling runtime entrypoint
[OK] ✅ Running static checks
[OK] ✅ Packaging artifact
[OK] ✅ Uploading artifact
[OK] ✅ Running smoke test

== Progress Renderer ==
Building release [██████████████████████████████████████] 100%
[DONE] ✅ Progress reached final state cleanly

== Failure Capture ==
[ERR] ❌ Deploying to production
│ connecting to production gateway...
│ checking deployment token...
│ boom: token expired for environment production
[WARN] ⚠️ Deploy failed intentionally for showcase
Captured exit code : 7

== Command Helpers ==
$ bash -c printf\ \"hello\ from\ log::run\\n\"
hello from log::run
$ bash -c printf\ \"test\ output\ hidden\?\ no\,\ this\ is\ direct\ try\ output\\n\"\;\ exit\ 0
test output hidden? no, this is direct try output
[OK] ✅ Command succeeded
[OK] ✅ try success branch
$ bash -c printf\ \"simulated\ failure\ output\\n\"\;\ exit\ 5
simulated failure output
[ERR] ❌ Command failed with exit code 5
[WARN] ⚠️ try returned code 5

== Summary ==
Workspace          : ready
Runtime            : resolved
Static Checks      : passed
Package            : created
Upload             : done
Deploy             : failed intentionally
======================================================
[DONE] ✅ Showcase completed
codingmaster@codingmstr:/var/www/projects/gun$
