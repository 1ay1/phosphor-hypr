# bash completion for `wear`. Source from ~/.bashrc or drop in
# /usr/share/bash-completion/completions/wear (or ~/.local/share/...).

_wear() {
    local cur prev words cword
    _init_completion 2>/dev/null || {
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        cword=$COMP_CWORD
    }

    local subs="list current reload pick tweak gui set unset reset undo save \
random shuffle from from-color gallery demo dark light toggle doctor import \
export update show tweaks schema options get values help"

    # first word: subcommand OR a theme name
    if [ "$cword" -eq 1 ]; then
        local themes; themes="$(wear list 2>/dev/null)"
        COMPREPLY=($(compgen -W "$subs $themes" -- "$cur"))
        return
    fi

    case "${COMP_WORDS[1]}" in
        set|unset|get|is-overridden)
            if [ "$cword" -eq 2 ]; then
                local keys; keys="$(wear schema 2>/dev/null | grep -vE '^(##|$)' | cut -d'|' -f1)"
                COMPREPLY=($(compgen -W "$keys" -- "$cur"))
            fi
            return ;;
        random|shuffle)
            COMPREPLY=($(compgen -W "accents colours shape feel bar popups everything" -- "$cur"))
            return ;;
        options)
            COMPREPLY=($(compgen -W "icon_theme cursor_theme gtk_theme kvantum_theme wallpaper_shader" -- "$cur"))
            return ;;
        doctor)
            COMPREPLY=($(compgen -W "--fix" -- "$cur"))
            return ;;
        demo)
            COMPREPLY=($(compgen -W "--interval --loop --shuffle" -- "$cur"))
            return ;;
        from|from-image|from-color|color)
            case "$cur" in
                -*) COMPREPLY=($(compgen -W "--light" -- "$cur")) ;;
                *)  COMPREPLY=($(compgen -f -- "$cur")) ;;
            esac
            return ;;
        import)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
    esac
}
complete -F _wear wear
