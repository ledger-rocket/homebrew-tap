# ledger-rocket Homebrew tap

```bash
brew install ledger-rocket/tap/rocket-review
```

Homebrew vendors the Python runtime, so `rocket-review`'s Python 3.13+ requirement
stops being your problem.

It does **not** install the review backends. `rr` shells out to a model CLI, and you
still need at least one of them:

- `codex` — `npm i -g @openai/codex` (the default for plan reviews)
- `claude` — [Claude Code](https://claude.com/claude-code) (the default for code and diff reviews)
- `opencode`

PyPI stays canonical; the formula builds from the published sdist, and
`pipx install rocket-review` remains equally supported.
