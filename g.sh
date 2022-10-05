# * g (goto directory) - bookmark directories in shell.
# * version: 0.4

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

_g_file=~/.g

_read_char() {
    # Read number of chars into variable
    # Usage: _read_char VAR NUM
    stty -icanon
    eval "$1=\$(dd bs=1 count="$2" 2>/dev/null)"
    stty icanon echo
}

_g_cd() {
    # cd into directory
    if [ ! -d "$1" ]; then
        printf 'g: no such directory %s\n' "$1" >&2
        return 1
    fi
    _dir="$(echo "$1" | sed "s%^~%$HOME%;s%//%/%g")"
    if cd -- "$_dir" > /dev/null; then
        echo "$_dir"
    else
        printf '\bg: cannot cd into %s\n' "$_dir" >&2
    fi
    return "$?"
}

_g_prompt() {
    # Exit if no dirs in $_g_file
    if [ "$#" -eq 0 ] || [ "$*" = '' ]; then
        echo goto: nothing to do; return 1
    fi

    # cd into dir without prompt if you have single directory
    # in $_g_file
    if [ "$(echo "$*" | wc -l)" -eq 1 ]; then
        _g_cd "$*" && return 0
    fi

    # Print directory list
    i=0
    echo "$*" | while read -r dir; do
        dir="$(echo "$dir" | sed "s%$HOME%~%")"
        printf '%s\t%s\n' "$i" "$dir"
        i=$((i+1))
    done

    # Input target dir number
    dirs_num="$(echo "$*" | wc -l)"
    num_len="${#dirs_num}"
    printf '%s' ": "
    _read_char _num "$num_len"
    if echo "$_num" | grep -E '[0-9]+' >/dev/null; then
        _target_dir="$(echo "$*" |
            awk -v line="$((_num+1))" 'NR==line {print}')"
        # Print new line to prevent line concatenation
        [ "${#_num}" -eq "$num_len" ] && echo
    elif [ "$_num" = '' ]; then
        return 1  # Just exit if you press Enter.
    else
        # Print new line and exit if printable chars passed.
        # E.g. new line will be printed if you type 'q'.
        echo; return 1
    fi

    # cd into directory
    _g_cd "$_target_dir"
}

_g_search() {
    grep -iP "$1" "$_g_file"
}

_g() {
    # Get dirs from $_g_file
    if [ -f "$_g_file" ]; then
        if [ "$1" ]; then
            # Search dirs with Perl regex
            _dirs="$(_g_search "$1")"
        else
            # Load all directories
            _dirs="$(cat "$_g_file")"
        fi
    fi

    _g_prompt "$_dirs" # prompt and cd
}

_g_save() {
    # Save dir in $_g_file
    if [ -n "$1" ]; then
        if hash realpath >/dev/null 2>&1; then
            _dir="$(realpath "$1")"
        else
            _dir="$(echo "${PWD}/${1%*/}" | sed 's%//%/%g')"
            [ -d "$_dir" ] || _dir="$1"
        fi
    else
        _dir="$PWD"
    fi

    # Exit if directory is already in $_g_file
    if grep "^${_dir%%+(/)}\$" "$_g_file" >/dev/null 2>&1; then
        return 1
    fi

    # Save directory
    if echo "${_dir%%+(/)}" >> "$_g_file"; then
        echo "$_dir"
    fi
}

if type complete >/dev/null 2>&1; then
    # Bash completion
    _g_complete_bash() {
        _pattern=${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=($(compgen -W \
            "$(printf "%s\n" "$(_g_search "$_pattern")")" -- ''))
    }
    complete -F _g_complete_bash g
else
    :
fi

alias g='_g'
alias g_save='_g_save'
