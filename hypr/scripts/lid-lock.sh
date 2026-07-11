#!/usr/bin/env bash

# Lock the session when the laptop lid is closed.
# Requires the acpid package (provides acpi_listen).

if ! command -v acpi_listen &> /dev/null; then
    echo "lid-lock: acpi_listen not found, lid lock will not work." >&2
    exit 1
fi

acpi_listen | while IFS= read -r line; do
    case "$line" in
        *button/lid*close*)
            loginctl lock-session
            ;;
    esac
done
