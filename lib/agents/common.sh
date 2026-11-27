#!/usr/bin/env bash

skip_or_fail() {
    echo "$1" >&2
    [[ "${CI:-}" != "true" ]]
}
