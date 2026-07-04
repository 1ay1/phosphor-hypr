# fish completions for `wear` — the one-palette desktop theme engine.
# Dynamic: theme names, tweakable keys, and pick-key options come straight from
# the running `wear` binary, so they never drift from the schema.

function __wear_themes
    command wear list 2>/dev/null
end

function __wear_keys
    # every settable schema key (first field of `wear schema`, skipping ## headers)
    command wear schema 2>/dev/null | string match -rv '^(##|$)' | string split -f1 '|'
end

function __wear_subcommands
    printf '%s\n' \
        list current reload pick tweak gui set unset reset undo save \
        random shuffle from from-color gallery demo dark light toggle \
        doctor import export update show tweaks schema options get values help
end

# no subcommand yet -> offer subcommands AND theme names (both are valid as $1)
complete -c wear -n '__fish_use_subcommand' -a '(__wear_subcommands)' -f
complete -c wear -n '__fish_use_subcommand' -a '(__wear_themes)' -d 'theme' -f

# `wear set <key>` -> keys ; second arg free-form
complete -c wear -n '__fish_seen_subcommand_from set unset get is-overridden' \
    -a '(__wear_keys)' -f

# `wear random <section>`
complete -c wear -n '__fish_seen_subcommand_from random shuffle' \
    -a 'accents colours shape feel bar popups everything' -f

# `wear doctor` flag
complete -c wear -n '__fish_seen_subcommand_from doctor' -l fix -d 'auto-repair failing contrast'

# `wear demo` flags
complete -c wear -n '__fish_seen_subcommand_from demo' -s i -l interval -d 'seconds per theme'
complete -c wear -n '__fish_seen_subcommand_from demo' -s l -l loop -d 'loop forever'
complete -c wear -n '__fish_seen_subcommand_from demo' -s s -l shuffle -d 'random order'

# `wear options <kind>`
complete -c wear -n '__fish_seen_subcommand_from options' \
    -a 'icon_theme cursor_theme gtk_theme kvantum_theme wallpaper_shader' -f

# `wear from-color <colour>` / `from-color ... --light`
complete -c wear -n '__fish_seen_subcommand_from from-color color from from-image' -l light -d 'light variant'
