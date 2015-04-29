#
# zaw-src-bookmark
#
# bookmark your favorite command lines, access it using zaw interface.
# you can bookmark command line using zaw-history's `bookmark this command line` action,
# or bind some key to ``zaw-bookmark-add-buffer`` and use it.
#

zmodload zsh/system
autoload -U fill-vars-or-accept

BOOKMARKFILE="./.zaw_dir_bookmarks"

function zaw-src-dir-bookmark() {
    if [[ -f "${BOOKMARKFILE}" ]]; then
        candidates=("${(Qf)$(zsystem flock -r "${BOOKMARKFILE}" && < "${BOOKMARKFILE}")}")
    fi
    actions=("zaw-dir-bookmark-execute" "zaw-dir-callback-replace-buffer" "zaw-dir-callback-append-to-buffer" "zaw-dir-bookmark-remove")
    act_descriptions=("execute" "replace edit buffer" "append to edit buffer" "removed bookmark")
    options=("-m")
}

zaw-register-src -n dir_bookmark zaw-src-dir-bookmark


#
# helper functions for bookmark
#

function zaw-dir-bookmark-execute() {
    zaw-callback-replace-buffer "$@"
    fill-vars-or-accept
}

function zaw-dir-bookmark-add() {
    local -a bookmarks

    : >> "${BOOKMARKFILE}"
    (
        if zsystem flock -t 5 "${BOOKMARKFILE}"; then
            bookmarks=("${(f)$(< "${BOOKMARKFILE}")}" "${(q@)@}")

            # remove empty lines
            bookmarks=("${(@)bookmarks:#}")

            # remove duplicated lines, sort and write to ${BOOKMARKFILE}
            print -rl -- "${(@un)bookmarks}" > "${BOOKMARKFILE}"
        else
            print "can't acquire lock for '${BOOKMARKFILE}'" >&2
            exit 1
        fi
    )

    if [[ $? == 0 ]]; then
        zle -M "bookmark '${(j:', ':)@}'"
    fi
}

function zaw-dir-bookmark-add-buffer() {
    zaw-dir-bookmark-add "${BUFFER}"
}

zle -N zaw-dir-bookmark-add-buffer

function zaw-dir-bookmark-remove() {
    local s
    local -a bookmarks

    : >> "${BOOKMARKFILE}"
    (
        if zsystem flock -t 5 "${BOOKMARKFILE}"; then
            bookmarks=("${(f)$(< "${BOOKMARKFILE}")}")
            for s in "${(q@)@}"; do
                bookmarks=("${(@)bookmarks:#${s}}")
            done

            # remove duplicated lines, sort and write to ${BOOKMARKFILE}
            print -rl -- "${(@un)bookmarks}" > "${BOOKMARKFILE}"
        else
            print "can't acquire lock for '${BOOKMARKFILE}'" >&2
            exit 1
        fi
    )

    if [[ $? == 0 ]]; then
        zle -M "bookmark '${(j:', ':)@}' removed"
    fi
}

function zaw-dir-bookmark-remove-buffer() {
    zaw-dir-bookmark-remove "${BUFFER}"
}

zle -N zaw-dir-bookmark-remove-buffer
