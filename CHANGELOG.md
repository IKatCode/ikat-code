# Changelog

## 0.1.2

A long session is now easy to read. On a real 24-minute session the transcript went from 295
lines to 174.

- A new file takes one line instead of its first lines, and a change shows at most 10 lines of
  its diff. Long paths are cut from the start, so the file name stays visible, and the files of
  the session's scratch folder show as `scratch/<file>`.
- A command of several lines shows its first line and how many more there are. When a command
  fails, its preview shows the error that made it fail, not a test runner's `fail 0` line.
- The task list stays above the input while IKat works, instead of being repeated in the
  transcript.
- The working line says what the model is thinking about and how much it has written, and when
  the response has gone quiet, for how long.
- A long turn ends with a summary: how long it took, the files changed with lines added and
  removed, the checks that ran, and the tokens used.
- When a ChatGPT plan limit is reached, IKat says when it resets.
- A new start screen; your own messages stand out in the transcript; tool names are colored by
  what they do; the permission mode sits at the start of the status bar. In a narrow window the
  status bar drops the key hint first, then the context meter, and keeps the cost.
- With OpenAI, Gemini and OpenAI-compatible APIs, a response that stops arriving after the model
  has begun writing is retried after 160 seconds instead of five minutes.
- In `ikat -p --output-format stream-json`, each `message.completed` event says how the
  request's time was spent (`timing`), and `usage` counts reasoning tokens where the provider
  reports them.

To update, run the install command again.

## 0.1.1

- The model you set up in IKat is the default. Signing in with `ikat login` or saving a key with
  `ikat login <provider>` now wins over a provider IKat only finds in environment variables that
  another program left behind. Without either, the order is OpenAI, then Anthropic, then Google.
- The first-run screen offers an API key first (OpenAI, OpenRouter, Anthropic, Gemini), then the
  ChatGPT plan, your own endpoint and a local server. Going back returns to the option you came
  from.

To update, run the install command again.

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
