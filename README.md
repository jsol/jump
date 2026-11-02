# Jump

A cli tool to jump to directories quickly. Needs to be sourced in your shell. Variants for bash and zsh are provided.

## Installation

Requires sqlite3, install with

```bash
sudo apt install sqlite3
```

then source the script in your shell rc file, e.g. for bash add to `~/.bashrc`:

```bash
source /path/to/jump.sh
```


## How it works

The script uses a sqlite database to store paths and their aliases.

Add a path with

```bash
jump -a <alias> <path>
```

where path defaults to the current directory, and alias defaults to the last part of the directory name.

Then you can jump to that path with

```bash
jump <alias>
```

see all aliases with

```bash
jump -l
```

And remove an alias with

```bash
jump -d <alias>
```
