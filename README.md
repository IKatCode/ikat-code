<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/logo-dark.svg">
    <img alt="IKat" src="docs/logo-light.svg" width="324">
  </picture>
</p>

<p align="center">A coding agent for your terminal that works with the model you choose.</p>

<p align="center">
  <a href="https://github.com/IKatCode/ikat-code/releases"><img alt="Latest release" src="https://img.shields.io/github/v/release/IKatCode/ikat-code?include_prereleases&label=release"></a>
  <img alt="macOS, Linux, Windows" src="https://img.shields.io/badge/macOS%20%C2%B7%20Linux%20%C2%B7%20Windows-x64%20%26%20arm64-555">
</p>

<p align="center"><b>English</b> · <a href="README.ru.md">Русский</a></p>

![IKat fixes a bug: it edits one line, adds a test and runs the project's tests](docs/fix-bug.svg)

## Install

macOS and Linux:

```sh
curl -fsSL https://github.com/IKatCode/ikat-code/releases/latest/download/install.sh | sh
```

Windows:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://github.com/IKatCode/ikat-code/releases/latest/download/install.ps1 | iex"
```

Then open a new terminal and start it in a project:

```sh
cd your-project
ikat
```

The first time, IKat asks which model to use.

<details>
<summary>Systems, requirements, what the installer does</summary>

<br>

Builds exist for macOS (Apple Silicon and Intel), Linux (x64 and arm64, glibc and musl) and
Windows (x64 and arm64).

- Windows: IKat runs shell commands in Git Bash, so install
  [Git for Windows](https://git-scm.com/download/win). Windows 10 and 11 already have the
  `ssh-keygen` the installer needs.
- Alpine and other musl systems: run `apk add libstdc++ libgcc` first.

The installer downloads the build for your system, checks it against the release's checksums and
their signature, and puts `ikat` with `rg` (ripgrep) into `~/.ikat/bin`, or
`%LOCALAPPDATA%\ikat\bin` on Windows. Then it adds that folder to your PATH. You can also take an
archive from the [releases page](https://github.com/IKatCode/ikat-code/releases) and unpack it
anywhere.

</details>

## What it does

- Reads your project, changes the code, runs your tests and linters, and tells you what it changed
  and how it checked it.
- Works with any OpenAI-compatible API: a model on your machine, OpenRouter, your company's
  gateway. API keys of OpenAI, Anthropic and Google work too, and so does a ChatGPT plan.
  `/model` switches models in the middle of a conversation.
- Asks before it runs a command or edits a file, unless you tell it not to. Any change can be
  rolled back with `/rewind`.
- Keeps commands in a sandbox on macOS and Linux.
- Runs without the interface in scripts and CI, with JSON output.
- Speaks English and Russian.

## Models

| Where the model runs | How to connect it |
|---|---|
| Any server with an OpenAI-compatible API | a `providers` entry in `~/.ikat/settings.json`, below |
| Ollama, LM Studio, llama.cpp, vLLM on your machine | `ikat --model ollama/qwen3-coder:30b`, found by itself |
| OpenAI, Anthropic, Google, OpenRouter | `ikat login openai` (`anthropic`, `google`, `openrouter`) or the usual `*_API_KEY` variable |
| ChatGPT Plus or Pro | `ikat login`, then sign in in the browser |

An OpenAI-compatible server:

```json
{
  "providers": {
    "corp": {
      "baseUrl": "https://llm.corp.example/v1",
      "apiKeyEnv": "CORP_LLM_KEY",
      "models": { "coder-xl": { "contextWindow": 200000 } }
    }
  }
}
```

```sh
ikat --model corp/coder-xl
```

The key comes from the variable named in `apiKeyEnv`, or from `ikat login corp`, which keeps it in
the system keychain. Local models need tool calling; if the server does not report its context
size, IKat assumes 32 768 tokens, and `contextWindow` sets the real one. `ikat doctor` shows what
is connected.

A project's own `.ikat/settings.json` cannot add or change providers: a repository you cloned does
not get to decide where your code is sent.

## Working with it

Describe the task the way you would to a colleague:

```
The checkout total ignores discounts on bundles. Find out why and fix it.
```

| Key or command | What it does |
|---|---|
| `Esc` | stop the current step |
| `Esc Esc`, `/rewind` | go back to an earlier point, files and conversation |
| `ikat -c`, `ikat -r` | continue the last conversation here, or pick an older one |
| `/init` | write `IKAT.md`, notes on how to build and test the project, read at every start |
| `/model` | switch the model |
| `/` and `?` | all commands and all keys |

## Permissions

Before a command or a file change, IKat shows what it is about to do and how risky it is. Allow it
once, allow that kind of command in this project from now on, or say no and tell it what to do
instead.

![IKat asks whether it may run git status, with the risk level and the answers](docs/ask.svg)

| Mode | How much it asks |
|---|---|
| `default` | asks about commands and file changes |
| `accept-edits` | edits files in the project without asking; asks about commands |
| `plan` | writes a plan and waits for your go before changing anything |
| `auto` | like `accept-edits`, and also runs commands that stay in the sandbox (macOS, Linux) |
| `readonly` | reads, never writes or runs |
| `bypass-permissions` | asks nothing |

`Shift+Tab` moves between the first three. Any mode can be set with `/mode <name>` or
`ikat --permission-mode <name>`.

<details>
<summary>Running with no questions at all</summary>

<br>

```sh
ikat --permission-mode bypass-permissions
```

Or `/mode bypass-permissions` in a running session. To start in it every time, add this to
`~/.ikat/settings.json`:

```json
{ "permissions": { "defaultMode": "bypass-permissions" } }
```

It works on every system, Windows included. `Shift+Tab` never switches into it, and a project's
settings cannot turn it on. Your deny rules and the protection of secrets (`.env` files, `~/.ssh`,
cloud credentials) still hold; everything else runs. On macOS and Linux commands still start in
the sandbox, but one that needs to leave it is let out without a question. Windows has no sandbox,
so there a command can do whatever you can. Use this mode in a container, a virtual machine or a
copy of the project you can throw away.

</details>

<details>
<summary>The sandbox</summary>

<br>

On macOS and Linux, commands IKat runs can write only inside your project and a scratch folder, and
have no network unless your settings open it for certain hosts. Something like `npm install` asks
first and then runs outside the sandbox. Windows has no sandbox yet; if you want one there, run
IKat in WSL.

Project settings, such as commands a project allows without asking, take effect only after you
say you trust the folder. IKat shows you what they are first.

</details>

## Scripts and CI

```sh
ikat -p "Fix the failing test in cart.test.ts" --permission-mode accept-edits --allowed-tools "Bash(npm test:*)"
```

`-p` runs one task and exits. It cannot ask, so anything that needs a question is refused, and
IKat prints the rule that would allow it; give each rule its own `--allowed-tools`. Add
`--output-format json` or `stream-json` to read the result from another program. In a throwaway
CI container, `--permission-mode bypass-permissions` lets it run everything.

## Updating and removing

Run the install command again to update. To remove IKat, delete `~/.ikat/bin` (or
`%LOCALAPPDATA%\ikat\bin`) and take it out of your PATH; sessions and settings are in `~/.ikat`.

## Help

`ikat doctor` checks the terminal, Git, the model connection and your settings, and says what to
fix. If that does not help, [open an issue](https://github.com/IKatCode/ikat-code/issues) and
include its output. Security problems go privately, as [SECURITY.md](SECURITY.md) describes.

## Privacy

Your code and requests go only to the model provider you chose. IKat has no telemetry.

## License

Free to use, at home and at work, commercial projects included. Not open source: please don't
redistribute it (link to this page instead), modify it or take it apart. The code IKat writes in
your projects is yours. Full text: [LICENSE](LICENSE).

IKat is built with open-source components, among them the Bun runtime. They keep their own
licenses, which come with every download in the file `THIRD-PARTY-NOTICES`.
