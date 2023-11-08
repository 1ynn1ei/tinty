#!/usr/bin/env bash

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

if [[ -z "$BASE16_COLOR_00_HEX" || -z "$(command -v 'bc')" ]]; then
  # BASE16_SHELL_ENABLE_VARS not set or `bc` command does not exist.
  return 1
fi

read -r current_theme_name < "$BASE16_SHELL_THEME_NAME_PATH"

# Determine if theme is dark or light based on HSP calculation:
# http://alienryderflex.com/hsp.html

# We'll calculate the "perceived brightness" of the theme's background color.
# We will use `bc`, and it only understands upper-case hex values:
current_bg_color=$(echo "$BASE16_COLOR_00_HEX" | tr '[:lower:]' '[:upper:]')

r_hex_value=${current_bg_color:0:2}
g_hex_value=${current_bg_color:2:2}
b_hex_value=${current_bg_color:4:2}

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

if [[ $is_light_theme == "1" ]]; then
  is_light_theme="true"
else
  is_light_theme="false"
fi

gitconfig_output="# vim: ft=gitconfig\n"
gitconfig_output+="#\n"
gitconfig_output+="# DO NOT EDIT! Generated by base16-shell.\n"
gitconfig_output+="#\n"
gitconfig_output+="# Configures difftool \`delta\` to use light or dark mode based on perceived brightness (HSP) of base16 theme's background color.\n"
gitconfig_output+="# Learn more: http://alienryderflex.com/hsp.html\n"
gitconfig_output+="#\n"
gitconfig_output+="# Base16 Theme: ${current_theme_name}\n"
gitconfig_output+="#\n"
gitconfig_output+="# Values & HSP calculation results:\n"
gitconfig_output+=$(echo "$bc_output" | grep "^#")
gitconfig_output+="\n"
gitconfig_output+="[delta]\n"
gitconfig_output+="\tlight = ${is_light_theme}"

echo -e "$gitconfig_output" >| "$DELTA_GITCONFIG_PATH"

unset is_light_theme
unset gitconfig_output
unset bc_output
unset current_bg_color
unset r_hex_value
unset g_hex_value
unset b_hex_value
unset current_theme_name
