# secrets — local secret storage with sops + age

`utility/secrets` keeps tokens in one sops-encrypted JSON file. `setup-utility`
symlinks it onto your PATH.

sops owns the file format, age owns the key. The script is the ergonomics: it
keeps values off the command line, out of shell history and out of `ps`.

## Setup

```bash
mise install          # brings in age, sops, jq
secrets init          # creates the key, warns you to back it up
```

`init` refuses to continue until you confirm the backup. That is deliberate:
the age key is the only way to read the store, and there is no recovery.

## Use

```bash
secrets set GITHUB_TOKEN          # prompts; input hidden
secrets list                      # names only, never values
secrets get GITHUB_TOKEN
secrets search 'token$'
secrets rm OLD_TOKEN

secrets exec -- claude            # only that process sees them
eval "$(secrets export)"          # or load into this shell
```

`export` takes `--file` to select names from a template, `--format
shell|dotenv|json`, and `--on-missing throw|empty|keep`.

## Export and import a `.env` file

```bash
secrets export --format dotenv > backup.env    # plaintext: protect it, delete it after use
secrets import backup.env                      # or: secrets import < backup.env
secrets import --overwrite new.env             # replace values that already exist
```

`export --format dotenv` quotes a value that holds a space, a quote, a backslash or a newline, so
`import` restores every value exactly. `import` reads `KEY=VALUE` lines, an optional `export ` prefix,
`#` comments, and single- or double-quoted values. Inside double quotes `\n`, `\t`, `\r`, `\\` and `\"` are
escapes and any other backslash stays as written; single quotes are always literal (use them for `C:\temp`). A line
that is not `KEY=VALUE` stops the import with its line number; an empty value is skipped, as in
`secrets set`. An existing name is kept unless you pass `--overwrite`, so importing an old file cannot silently
replace a live credential. The output lists names, never values.

## Scope

`secrets exec` reads the store directly through sops. The store is **not**
declared in any mise config, so nothing is injected into your shell merely by
entering a directory, and `mise exec` will not see it either. Only the command
you name gets the values. Add `--pristine` to pass the secrets and nothing else.

If you would rather have them everywhere, declare the store in the global mise
config instead - at the cost of every process you start being able to read it.

## Paths

| | Default | Override |
|---|---|---|
| Store | `~/.config/mise/secrets.json` | `SECRETS_FILE` |
| Key | `~/.config/mise/age.txt` | `SOPS_AGE_KEY_FILE` |

The store is safe to commit. The key is not, and `init` refuses to create one
inside a git repo.
