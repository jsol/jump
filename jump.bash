# jump - directory bookmarks stored in SQLite.
# Source this file from ~/.bashrc: source /path/to/jump.bash
#
# Usage:
#   jump -a [name] [path]   Add/update bookmark (defaults: name = basename of path, path = $PWD)
#   jump -d <name>          Delete bookmark
#   jump -l                 List bookmarks
#   jump <name>             cd to bookmark

: "${JUMP_DB:=${XDG_DATA_HOME:-$HOME/.local/share}/jump/bookmarks.db}"

_jump_sql() {
  sqlite3 -batch -noheader "$JUMP_DB" "$@"
}

_jump_quote() {
  local escaped=${1//\'/\'\'}
  printf "'%s'" "$escaped"
}

_jump_init() {
  if [[ ! -f $JUMP_DB ]]; then
    mkdir -p -- "$(dirname -- "$JUMP_DB")" || return 1
  fi
  _jump_sql "CREATE TABLE IF NOT EXISTS bookmarks (name TEXT PRIMARY KEY, path TEXT NOT NULL);"
}

jump() {
  command -v sqlite3 >/dev/null 2>&1 || { printf '%s\n' "jump: sqlite3 not found" >&2; return 1; }
  _jump_init || return 1

  case ${1:-} in
    -a)
      local name=${2:-} dir=${3:-$PWD}
      dir=$(cd -- "$dir" 2>/dev/null && pwd -L) || dir=
      [[ -n $dir && -d $dir ]] || { printf 'jump: not a directory: %s\n' "${3:-$PWD}" >&2; return 1; }
      [[ -n $name ]] || name=${dir##*/}
      [[ -n $name ]] || { printf "jump: cannot derive name from '%s'\n" "$dir" >&2; return 1; }
      _jump_sql "INSERT OR REPLACE INTO bookmarks (name, path) VALUES ($(_jump_quote "$name"), $(_jump_quote "$dir"));" \
        && printf 'jump: %s -> %s\n' "$name" "$dir"
      ;;
    -d)
      [[ -n ${2:-} ]] || { printf '%s\n' "usage: jump -d <name>" >&2; return 1; }
      _jump_sql "DELETE FROM bookmarks WHERE name = $(_jump_quote "$2");"
      ;;
    -l|'')
      _jump_sql -separator $'\t' "SELECT name, path FROM bookmarks ORDER BY name;" | column -t -s $'\t'
      ;;
    -h|--help)
      printf '%s\n' "usage: jump -a [name] [path] | jump -d <name> | jump -l | jump <name>"
      ;;
    *)
      local target
      target=$(_jump_sql "SELECT path FROM bookmarks WHERE name = $(_jump_quote "$1");")
      [[ -n $target ]] || { printf "jump: no bookmark '%s'\n" "$1" >&2; return 1; }
      cd -- "$target"
      ;;
  esac
}

_jump_completion() {
  local cur name
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=()

  if [[ ${COMP_WORDS[1]} == -a ]]; then
    if (( COMP_CWORD >= 3 )); then
      mapfile -t COMPREPLY < <(compgen -d -- "$cur")
    fi
    return
  fi

  if [[ ${COMP_WORDS[1]} == -d || ( $COMP_CWORD == 1 && $cur != -* ) ]]; then
    while IFS= read -r name; do
      [[ $name == "$cur"* ]] && COMPREPLY+=("$name")
    done < <(_jump_sql "SELECT name FROM bookmarks ORDER BY name;")
  fi
}

if [[ $- == *i* ]]; then
  complete -F _jump_completion jump
fi
