#
# zaw-src-dirs
#
# Mark directories for quick cd
#

zmodload zsh/system
autoload -U fill-vars-or-accept

DIRSFILE="${DIRSFILE:-"${HOME}/.zaw-dirs"}"

ASSOC_DIRS=()
typeset -A ASSOC_DIRS

function zaw-src-dirs() {
    if [[ -f "${DIRSFILE}" ]]; then
        local -a raw_dirs
        raw_dirs=("${(Qf)$(zsystem flock -r "${DIRSFILE}" && < "${DIRSFILE}")}")
        for dir in $raw_dirs; do
            ASSOC_DIRS+=("`basename $dir`" "$dir")
            candidates+=("`basename $dir`")
        done
    fi
    actions=("zaw-dirs-execute" "zaw-dirs-add" "zaw-dirs-remove")
    act_descriptions=("execute" "add current directory to dirs" "removed directory")
    options=("-m")
}

zaw-register-src -n dirs zaw-src-dirs


#
# helper functions for dirs
#

function zaw-dirs-execute() {
    zaw-callback-replace-buffer "cd $ASSOC_DIRS[$1]"
    fill-vars-or-accept
}

function zaw-dirs-add() {
    local -a dirss

    : >> "${DIRSFILE}"
    (
        if zsystem flock -t 5 "${DIRSFILE}"; then
            dirss=("${(f)$(< "${DIRSFILE}")}" "$PWD")

            # remove empty lines
            dirss=("${(@)dirss:#}")

            # remove duplicated lines, sort and write to ${DIRSFILE}
            print -rl -- "${(@un)dirss}" > "${DIRSFILE}"
        else
            print "can't acquire lock for '${DIRSFILE}'" >&2
            exit 1
        fi
    )

    if [[ $? == 0 ]]; then
        zle -M "dirs '${(j:', ':)@}'"
    fi
}

function zaw-dirs-add-buffer() {
    zaw-dirs-add "${BUFFER}"
}

zle -N zaw-dirs-add-buffer

function zaw-dirs-remove() {
    local s
    local -a dirss

    : >> "${DIRSFILE}"
    (
        if zsystem flock -t 5 "${DIRSFILE}"; then
            dirss=("${(f)$(< "${DIRSFILE}")}")
            for s in "${(q@)@}"; do
                dirss=("${(@)dirss:#${s}}")
            done

            # remove duplicated lines, sort and write to ${DIRSFILE}
            print -rl -- "${(@un)dirss}" > "${DIRSFILE}"
        else
            print "can't acquire lock for '${DIRSFILE}'" >&2
            exit 1
        fi
    )

    if [[ $? == 0 ]]; then
        zle -M "dirs '${(j:', ':)@}' removed"
    fi
}

function zaw-dirs-remove-buffer() {
    zaw-dirs-remove "${BUFFER}"
}

zle -N zaw-dirs-remove-buffer
