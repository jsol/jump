# jump - directory bookmarks stored in SQLite.
# Source this file from ~/.zshrc:  source /path/to/jump.zsh
#
# Usage:
#   jump -a [name] [path]   Add/update bookmark (defaults: name = basename of path, path = $PWD)
#   jump -d <name>          Delete bookmark
#   jump -l                 List bookmarks
#   jump <name>             cd to bookmark

: ${JUMP_DB:=${XDG_DATA_HOME:-$HOME/.local/share}/jump/bookmarks.db}

_jump_sql() {
  sqlite3 -batch -noheader "$JUMP_DB" "$@"
}

_jump_quote() {
  local q="'"
  print -r -- "'${1//$q/$q$q}'"
}

_jump_init() {
  if [[ ! -f $JUMP_DB ]]; then
    mkdir -p -- "${JUMP_DB:h}" || return 1
  fi
  _jump_sql "CREATE TABLE IF NOT EXISTS bookmarks (name TEXT PRIMARY KEY, path TEXT NOT NULL);"
}

jump() {
  (( $+commands[sqlite3] )) || { print -u2 "jump: sqlite3 not found"; return 1; }
  _jump_init || return 1

  case $1 in
    -a)
      local name=$2 dir=${3:-$PWD}
      dir=${dir:a}
      [[ -d $dir ]] || { print -u2 "jump: not a directory: $dir"; return 1; }
      [[ -n $name ]] || name=${dir:t}
      [[ -n $name ]] || { print -u2 "jump: cannot derive name from '$dir'"; return 1; }
      _jump_sql "INSERT OR REPLACE INTO bookmarks (name, path) VALUES ($(_jump_quote $name), $(_jump_quote $dir));" \
        && print "jump: $name -> $dir"
      ;;
    -d)
      [[ -n $2 ]] || { print -u2 "usage: jump -d <name>"; return 1; }
      _jump_sql "DELETE FROM bookmarks WHERE name = $(_jump_quote $2);"
      ;;
    -l|'')
      _jump_sql -separator $'\t' "SELECT name, path FROM bookmarks ORDER BY name;" | column -t -s $'\t'
      ;;
    -h|--help)
      print "usage: jump -a [name] [path] | jump -d <name> | jump -l | jump <name>"
      ;;
    *)
      local target
      target=$(_jump_sql "SELECT path FROM bookmarks WHERE name = $(_jump_quote $1);")
      [[ -n $target ]] || { print -u2 "jump: no bookmark '$1'"; return 1; }
      cd -- "$target"
      ;;
  esac
}

_jump() {
  _jump_init 2>/dev/null || return
  local -a names
  names=(${(f)"$(_jump_sql "SELECT name FROM bookmarks;")"})
  if [[ $words[2] == -a ]]; then
    (( CURRENT == 4 )) && _files -/
  elif (( CURRENT == 2 || CURRENT == 3 )) && [[ $words[2] != -l ]]; then
    compadd -a names
  fi
}
(( $+functions[compdef] )) && compdef _jump jump
