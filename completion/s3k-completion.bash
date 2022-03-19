#!/usr/bin/env bash
# shellcheck disable=SC2207

function __s3k_completion() {
  local _wordCurrent="$2"
  local _wordPrevious="$3"

  local _idx=0

  if [ "${#COMP_WORDS[@]}" -ge 2 ]; then
    for _idx in "${!COMP_WORDS[@]}"; do
      if [[ "${COMP_WORDS[_idx]}" == '--' ]]; then
        break;
      fi
    done

    # N.B. We don't do any completion after '--'.
    if [ "${COMP_CWORD}" -le "${_idx}" ]; then
      if echo "${_wordPrevious}" | grep -Eq -- '^-(a|D|S)$'; then
        COMPREPLY=($(compgen -W "$(s3k -L)" "${_wordCurrent}"))
      elif echo "${_wordPrevious}" | grep -Eq -- '^-(d|s)$'; then
        COMPREPLY=($(compgen -W "$(s3k -l)" "${_wordCurrent}"))
      elif [[ "${_wordCurrent}" == '-' ]]; then
        COMPREPLY+=('p' 'b' 'B' 't' 'T' 'r' 'R' 'g' 'G' 'k' 'K' 'm' 'M' 'a' 's'
          'S' 'd' 'D' 'l' 'L' 'e' 'W' 'x' 'c' 'C' 'V' 'h' 'H'
        )
      fi
    fi
  fi
}

complete -F __s3k_completion s3k
