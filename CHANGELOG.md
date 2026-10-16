# Changelog

## 0.1.0

The first release of IKat Code, a coding agent for your terminal that works with the model you
choose.

- Connect any OpenAI-compatible API, a model on your machine (Ollama, LM Studio, llama.cpp,
  vLLM), API keys of OpenAI, Anthropic, Google or OpenRouter, or a ChatGPT plan. `/model` switches
  models in the middle of a conversation.
- IKat reads the project, changes the code, runs your tests and linters, and says what it changed
  and how it checked it.
- It asks before commands and file changes, in six modes from `readonly` to
  `bypass-permissions`, which asks nothing. Any change can be rolled back with `/rewind`.
- Commands run in a sandbox on macOS and Linux.
- `ikat -p` runs a task in scripts and CI, with JSON output.
- Builds for macOS, Linux (glibc and musl) and Windows, x64 and arm64.

Install:

```sh
curl -fsSL https://github.com/IKatCode/ikat-code/releases/latest/download/install.sh | sh
```

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://github.com/IKatCode/ikat-code/releases/latest/download/install.ps1 | iex"
```

Since 0.1.0-beta.1 only the version number and the documentation have changed.

## 0.1.0-beta.1

The first public build of IKat Code, a beta: it works for everyday tasks, and we want to hear
where it falls short before 0.1.0.

- An AI coding agent in your terminal: it reads your project, changes the code, runs your tests
  and tells you what it did.
- Works with any OpenAI-compatible server, a local model (Ollama, LM Studio, llama.cpp, vLLM),
  API keys of OpenAI, Anthropic, Google or OpenRouter, or a ChatGPT plan.
- Asks before risky commands and file changes; every change can be rolled back with `/rewind`.
  `bypass-permissions` asks nothing, for throwaway environments.
- A sandbox for commands on macOS and Linux. On Windows commands run in Git Bash and IKat asks
  about each one you have not allowed.
- `ikat -p` for scripts and CI, with JSON output.
- Builds for macOS, Linux (glibc and musl) and Windows, x64 and arm64. The installers check the
  signed checksums of the release. On Alpine, `apk add libstdc++ libgcc` first.

A beta is not the latest release, so the install commands of the README do not pick it up. To
install this one:

```sh
curl -fsSL https://github.com/IKatCode/ikat-code/releases/download/v0.1.0-beta.1/install.sh | IKAT_VERSION=0.1.0-beta.1 sh
```

```powershell
$env:IKAT_VERSION = '0.1.0-beta.1'; irm https://github.com/IKatCode/ikat-code/releases/download/v0.1.0-beta.1/install.ps1 | iex
```
