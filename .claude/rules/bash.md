---
paths:
  - **/*.sh
---

# Bash scripting rules

## Overall rules

- Always start scripts with the sequence: `#!/usr/bin/env bash`
- Always add `set -euo pipefail` at the beginning of the script
  - `set -e` (errexit): exit immediately if a command exits with a non-zero status
  - `set -u` (nounset): treat unset variables as an error and exit immediately
  - `set -o pipefail`: the return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if all commands exit successfully
- Always add a detailed description at the beginning of the script

```bash
#!/usr/bin/env bash
set -euo pipefail

## my-script.sh
#
# Description:
#
# Usage: ./my-script.sh [--help | ...]
#
# Globals:
#
# Arguments:
#
# Returns:
#   0 on success, non-zero on error.
#
# Author: Your Name <your.email@example.com>
# Date: 2026-01-01
#
###############################################################################

# ... remaining code
```

## Functions

- Write all operations and functionalities using functions
- Use the main function to call other functions:

```bash
main() {
  echo "Script started."
  for arg in "$@"; do
    process_item "${arg}"
  done
  echo "Script finished."
}

main "$@"
```

## Variables and logic

- Always use `readonly` when defining global constants
- Use `UPPER_SNAKE_CASE` for global `readonly` constants
- Use `lower_snake_case` for local variables and function names
- Always use quotation marks around variables, e.g.: `for f in "${files[@]}"; to`
- Always use `[[ ... ]]` to define conditions
- Always use `((... ))` for arithmetic operations
- When performing operations on other directories, always use sub-shell `(cd ...)` to keep the scope of the operation
- Prefer long-form command options (`--recursive`) over short-form (`-r`) in scripts for improved readability.

## Indentation and structure

- Always use two spaces for indentation
- Limit lines to approximately 80 characters
- Break long lines with backslashes `\` for readability
- Use heredocs for multi-line strings
- Quote the tag (`<<'EOF'`) to prevent variable expansion and command substitution within the heredoc

## Validation

- Use `bash -n` (syntax check) and `shellcheck` to check bash scripts
- Use `set -x` (xtrace) for debugging, it prints each command and its arguments after expansion, localize its use to specific sections


## Logging

- Always use redirection to `STDERR`:

```bash
log_error() {
  printf "[ERROR] %s: %s\n" "$(date '+%Y-%m-%dT%H:%M:%S%z')" "${*}" >&2
}

if ! some_command; then
  log_error "Failed to execute some_command."
  exit 1
fi
```

## Error handling

- Always use `trap` to capture signals and for cleanup

```bash
readonly TMP_DIR="$(mktemp -d)"

cleanup() {
  echo "Cleaning up temporary directory: ${TMP_DIR}" >&2
  rm -rf "${TMP_DIR}"
}

# Trap EXIT, INT (Ctrl+C), and TERM signals to run cleanup
trap cleanup EXIT INT TERM
```

## Common pitfalls

- Variables set inside a `while read` loop that is part of a pipeline will not persist outside the loop, as the loop runs in a sub-shell
- Redirection (`>`) happens before `sudo` executes the command, to write to a root-owned file, run the entire command under `sudo`
  - `echo "Sensitive data" | sudo tee /root/protected_file > /dev/null`
  - `sudo bash -c 'echo "Sensitive data" > /root/protected_file'`
- Avoid `eval` (unless absolutely necessary and you fully control the input), as it's a security risk and makes scripts hard to debug

