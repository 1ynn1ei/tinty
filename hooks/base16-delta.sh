#!/usr/bin/env sh

# ----------------------------------------------------------------------
# Setup config variables and env
# ----------------------------------------------------------------------

DELTA_GITCONFIG_PATH="$BASE16_CONFIG_PATH/delta.gitconfig"

if [ ! -e "$DELTA_GITCONFIG_PATH" ]; then
  touch "$DELTA_GITCONFIG_PATH"
fi

# ----------------------------------------------------------------------
# Execution
# ----------------------------------------------------------------------

if [ -z "$BASE16_COLOR_00_HEX" ] || [ ! -x "$(command -v bc)" ]; then
  # BASE16_SHELL_ENABLE_VARS not set or `bc` command does not exist.
  exit 1
fi

# Determine if theme is dark or light based on HSP calculation:
# http://alienryderflex.com/hsp.html

# We'll calculate the "perceived brightness" of the theme's background color.
# We will use `bc`, and it only understands upper-case hex values:
current_bg_color=$(echo "$BASE16_COLOR_00_HEX" | tr '[:lower:]' '[:upper:]')

r_hex_value=$(echo "$current_bg_color" | cut -c1-2)
g_hex_value=$(echo "$current_bg_color" | cut -c3-4)
b_hex_value=$(echo "$current_bg_color" | cut -c5-6)

# Calculate the perceived brightness, and check against brightness threshold of 7F.8 (127.5 in decimal).
# We'll do it in a way that bc outputs an evaluatable bash script that contains:
# 1.) The final result is_light_theme=1 or is_light_theme=0
# 2.) The relevant values & HSP calculations that is in Bash comments,
#     and will be added in the header section of the generated gitconfig.
bc_output=$(bc <<-HSP_BC
scale=3
obase=10
ibase=16

r=$r_hex_value
g=$g_hex_value
b=$b_hex_value
hsp=sqrt((.4C8 * ${r_hex_value} ^ 2) + (0.964 * ${g_hex_value} ^ 2) + (.1D2 * ${b_hex_value} ^ 2))

is_light_theme=(hsp>7F.8)

# gitconfig headers (Bash comments)
print "# hex            = #$current_bg_color\n"
print "# r              = ", r, "\n"
print "# g              = ", g, "\n"
print "# b              = ", b, "\n"
print "# hsp            = sqrt(.299r^2 + .587g^2 + .114b^2)\n"
print "# hsp            = ", hsp, "\n"
print "# is_light_theme = hsp > 127.5\n"
print "# is_light_theme = ", is_light_theme, "\n"

# Variable assignment to Bash variable is_light_theme
print "is_light_theme=", is_light_theme
HSP_BC
)

eval "$bc_output"

if [ "$is_light_theme" = "1" ]; then
  is_light_theme="true"
else
  is_light_theme="false"
fi


cat > "$DELTA_GITCONFIG_PATH" << EOF
# vim: ft=gitconfig
#
# DO NOT EDIT! Generated by base16-shell.
#
# Configures difftool \`delta\` to use light or dark mode based on perceived brightness (HSP) of base16 theme's background color.
# Learn more: http://alienryderflex.com/hsp.html
#
# Base16 Theme: ${current_theme_name}
#
# Values & HSP calculation results:
$(echo "$bc_output" | grep "^#")

[delta]
    light = ${is_light_theme}
EOF

unset is_light_theme
unset bc_output
unset current_bg_color
unset r_hex_value
unset g_hex_value
unset b_hex_value
unset current_theme_name
