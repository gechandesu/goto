# * goto (goto directory) - bookmark directorie in Bash.
# * versuion: 0.1

# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>

_goto_cd() {
    ##### cd into directory #####

    if [ ! -d "$1" ]; then
        echo "goto: no such directory $1" >&2
        return 1
    fi

    if cd -- "$1" > /dev/null; then
        echo "$1"
    else
        echo -e "\bgoto: cannot cd into $1" >&2
    fi
    return "$?"
}

_goto_prompt() {
    ##### Prompt and cd #####

    # Exit if no dirs in ~/.gotosave
    if [ "${#dirs[@]}" -eq 0 ] || [[ "${dirs[@]}" == '' ]]; then
        echo goto: nothing to do; return 1
    fi

    # cd into dir without prompt if you have single directory
    # in ~/.gotosave
    if [ "${#dirs[@]}" -eq 1 ]; then
        _goto_cd "${dirs[@]}" && return 0
    fi

    # Print directory list
    for i in "${!dirs[@]}"; do
        echo -e "$i\t${dirs[$i]%%+(/)}/" | sed "s%${HOME}%~%"
    done

    # Count digits in number of dirs for 'read'
    local dirscount="$((${#dirs[@]}-1))"
    local numlen="${#dirscount}"

    # Read input to 'num' and set 'target' directory
    read -r -n "$numlen" -p ': ' num
    if [[ "$num" =~ [0-9]+ ]]; then
        target="${dirs[$num]}";
        # Print new line to prevent line concatenation
        [ "${#num}" -eq "$numlen" ] && echo
    elif [[ "$num" == '' ]]; then
        return 1  # Just exit if you press Enter.
    else
        # Print new line and exit if printable chars passed.
        # E.g. new line will be printed if you type 'q'.
        echo; return 1
    fi

    # cd into directory
    _goto_cd "$target"
}

_goto_search() {
    grep -iP "$1" ~/.gotosave
}

_goto() {
    ##### Main function #####

    # Get directory list ('dirs' array)
    dirs=()
    if [ -f ~/.gotosave ]; then
        if [ "$1" ]; then
            # Search dirs with Perl regex
            _source="$(_goto_search "$1")"
        else
            # Load all directories
            _source="$(<~/.gotosave)"
        fi
        while read -r dir; do
            dirs+=("$dir")
        done <<< "$_source"
    fi

    _goto_prompt  # prompt and cd
}

_goto_save() {
    ##### Save PWD or 1 to ~/.gotosave file #####

    local dir
    if [ "$1" ]; then
        dir="$1"
    else
        dir="$PWD"
    fi

    # Exit if directory is already in ~/.gotosave
    if grep "^${dir%%+(/)}\$" ~/.gotosave > /dev/null; then
        return 1
    fi

    # Save directory
    if echo "${dir%%+(/)}" >> ~/.gotosave; then
        echo "$dir"
    fi
}

_goto_complete() {
    # Autocomplete directory by pattern
    local pattern=${COMP_WORDS[COMP_CWORD]}
    local IFS=$'\n'
    COMPREPLY=($(compgen -W "$(printf "%s\n" "$(_goto_search "$pattern")")" -- ''))
}

complete -F _goto_complete g

alias g='_goto'
alias s='_goto_save'
