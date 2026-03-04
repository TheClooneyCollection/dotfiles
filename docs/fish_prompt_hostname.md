# `prompt_hostname` in Fish

`prompt_hostname` is a built-in Fish prompt helper function.

## Behavior

1. It reads the current system hostname.
2. It returns the short hostname by removing everything after the first `.`.

Example:

- System hostname: `device.clooney.io`
- `prompt_hostname` output: `device`

## Why use it in prompts

Using `prompt_hostname` keeps prompts compact and readable, especially when your full hostname includes a domain.

## In this setup

Your prompt in `~/.config/fish/config.fish` uses `prompt_hostname` to show `username@device` (short host), not the full FQDN like `device.clooney.io`.

Example in `fish_prompt`:

```fish
echo -n (prompt_hostname)
```
