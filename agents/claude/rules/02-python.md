# Python: run everything with uv

## The rule

**Any Python file you write or run gets a PEP 723 header and is run with `uv run`.**
Never hand-build a venv, never `pip install` — the script declares its own dependencies.

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx", "rich"]
# ///
```

Both forms then work with no environment setup by whoever runs it next:

```bash
uv run script.py <args>
./script.py <args>          # the shebang handles it
```

A script with an inline header is **self-contained**: hand the single file to a
colleague and it runs. A script that needs "create a venv, pip install three things,
then patch site-packages" does not survive being handed to anyone.

## Where this does NOT apply

- **Stdlib-only one-liners** — `python3 -c "import json,sys; ..."` for parsing command
  output stays as-is. Wrapping those in `uv run` buys nothing and costs latency.
- **Scripts you did not write** — anything under a plugin, venv or `site-packages`
  path. Run someone else's tool the way it expects.
- **A host without `uv`** — say so and use what is there rather than installing a
  toolchain unasked.

The line is **dependencies, not formality**: the moment a script imports something
outside the stdlib, it needs the header.

## Commands

| Task | Command |
|---|---|
| Run a script | `uv run script.py` |
| Add a dependency to a script | `uv add --script script.py <pkg>` |
| Run a tool without installing it | `uvx <tool>` |
| Project with `pyproject.toml` | `uv sync`, then `uv run <cmd>` |
| Pin the interpreter | `requires-python` in the header |

## When a dependency is broken

Fix it **inside the script**, not by patching `site-packages`: `uv run` builds a fresh
environment each time, so a site-packages patch silently disappears. Leave a comment
naming what upstream must fix, so the workaround can be deleted later.

```python
# upstream bug: the module annotates a class before defining it and has no
# `from __future__ import annotations`, so importing it raises NameError.
import builtins
_shimmed = not hasattr(builtins, "TheClass")
if _shimmed:
    builtins.TheClass = object
try:
    import the_package
finally:
    if _shimmed:
        del builtins.TheClass
```

## Style

Follow `01-coding-style.md`, plus: type hints on anything public, `pathlib` over
`os.path`, f-strings over `%`/`.format()`, and `dataclasses` before hand-written
`__init__`. Prefer the stdlib when it is genuinely enough — a dependency you do not
add is a dependency that cannot break.
