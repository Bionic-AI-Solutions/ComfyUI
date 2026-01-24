# VS Code DevContainer GPU Runtime Issue - Solutions

## Problem

VS Code devcontainers may not properly respect `runArgs` for GPU configuration, causing containers to use `runc` instead of `nvidia` runtime even when `--runtime=nvidia` is specified in `devcontainer.json`.

## Why This Happens

VS Codes
