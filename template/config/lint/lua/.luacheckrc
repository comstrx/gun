std = "max"
codes = true
unused_args = false

max_line_length = 120
max_code_line_length = 120
max_comment_line_length = 120

files["**/spec/**/*_spec.lua"].std = "max+busted"
files["**/test/**/*_spec.lua"].std = "max+busted"
files["**/tests/**/*_spec.lua"].std = "max+busted"
