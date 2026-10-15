# IKat Code

A terminal AI coding agent. It understands your codebase, plans, makes minimal, correct changes
and checks them with your own tests, linters and type checker before it calls the work done.
Every change can be rolled back, and nothing risky happens without your permission.

Works with your **ChatGPT plan** (Sign in with ChatGPT), with an API key of OpenAI, Anthropic,
Google Gemini or OpenRouter, with a local model (Ollama, LM Studio, llama.cpp, vLLM), or with any
OpenAI-compatible endpoint.

## Install

macOS and Linux:

```sh
curl -fsSL https://github.com/IKatCode/ikat-code/releases/latest/download/install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://github.com/IKatCode/ikat-code/releases/latest/download/install.ps1 | iex
```

The installer checks the download against the release's signed checksums, puts `ikat` into
`~/.ikat/bin` (`%LOCALAPPDATA%\ikat\bin` on Windows) and adds it to your PATH. IKat updates itself
in the background; `ikat update` updates now, `ikat update --rollback` goes back one version.

## Start in a minute

```sh
cd your-project
ikat
```

The first start asks how to reach a model. With a ChatGPT Plus or Pro plan, choose ChatGPT and
sign in in the browser — that's all. Then describe the task:

```
> The checkout total ignores discounts on bundles. Find out why and fix it.
```

IKat explores the code, keeps a plan, edits files, runs your checks and tells you what it changed
and how it verified it. Approve or reject what it asks about; press `Esc` twice to rewind.

For scripts and CI:

```sh
ikat -p "Fix the failing test" --output-format stream-json
```

## What it does

- **Reads before it writes.** Repository map, search, a language server for definitions and
  references, and project instructions in `IKAT.md`.
- **Verifies its work.** After changes it runs the project's tests, linter and type checker and
  goes back to fix what it broke before it answers.
- **Safe by default.** Permission modes, rules per command, a sandbox for commands, checkpoints of
  every change and `/rewind`.
- **Parallel work when you ask for it.** Subagents explore, review and build parts of a task in
  their own copies of the project.
- **Extensible.** Commands, hooks, skills, MCP servers and plugins.
- **Headless.** Print mode, stream JSON, a TypeScript SDK and a GitHub Action.

## Privacy

Your code and requests go only to the model provider you choose. IKat has no telemetry. Checking
for updates is a plain request to this repository's releases.

## License

Free to use, including commercially; not open source. See [LICENSE](LICENSE). Code IKat
writes in your projects is yours.
