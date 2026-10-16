<p align="center">
  <b>English</b> · <a href="README.ru.md">Русский</a>
</p>

# IKat Code

A coding agent for the terminal. You say what you need, IKat reads the project, edits the code,
runs your tests and reports what it changed.

It is not tied to one vendor. Point it at any server that speaks the OpenAI API: OpenAI itself,
OpenRouter, a model on your own machine (Ollama, LM Studio, llama.cpp, vLLM) or your company's
gateway. Keys for Anthropic and Google work too, and so does signing in with a ChatGPT plan.

![IKat fixing a bug: it edits one line, adds a test and runs the project's tests](docs/fix-bug.svg)

> [!NOTE]
> 0.1.0 is not out yet, so the install commands below have nothing to download until it is.
> A beta is available on the [Releases](https://github.com/IKatCode/ikat-code/releases) page,
> with its own install commands.

## Install

macOS and Linux:

```sh
curl -fsSL https://github.com/IKatCode/ikat-code/releases/latest/download/install.sh | sh
```

Windows, in PowerShell:

```powershell
irm https://github.com/IKatCode/ikat-code/releases/latest/download/install.ps1 | iex
```

The installer checks the download against the release's signed checksums, puts `ikat` into
`~/.ikat/bin` (`%LOCALAPPDATA%\ikat\bin` on Windows) and adds that folder to your PATH. Open a
new terminal afterwards.

Builds: macOS (Intel, Apple Silicon), Linux (x64, arm64; glibc and musl), Windows (x64, arm64).

- Windows: IKat runs shell commands in Git Bash, so install [Git for Windows](https://git-scm.com/download/win).
  The signature check uses `ssh-keygen`, which Windows 10 and 11 already have.
- Alpine and other musl systems: `apk add libstdc++ libgcc` first.

## Connect a model

Run `ikat` in a project folder. The first time, it asks how to reach a model and saves the answer.
You can also set things up by hand.

Any OpenAI-compatible server goes into `~/.ikat/settings.json`:

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

The key is read from the variable named in `apiKeyEnv`, or from `ikat login corp`, which keeps it
in the system keychain. A project's own `.ikat/settings.json` cannot add or change providers: a
repository you cloned does not decide where your code is sent.

A local server is found by itself:

```sh
ikat --model ollama/qwen3-coder:30b
ikat --model lmstudio/<model>      # also llamacpp/<model>, vllm/<model>
```

The model needs tool calling. If the server does not report its context size, IKat assumes
32 768 tokens; set `contextWindow` if yours is different.

API keys of the big providers: `ikat login openai`, `ikat login anthropic`, `ikat login google`,
`ikat login openrouter`, or the usual variables (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`,
`GEMINI_API_KEY`, `OPENROUTER_API_KEY`). A ChatGPT Plus or Pro plan: `ikat login`, then sign in
in the browser.

`ikat doctor` shows which of these are set up. `/model` switches models in the middle of a
conversation.

## Using it

```sh
cd your/project
ikat
```

Then describe the task in your own words, for example:

```
The checkout total ignores discounts on bundles. Find out why and fix it.
```

| | |
|---|---|
| `Esc` | stop the current step |
| `Esc Esc` or `/rewind` | roll files and the conversation back to an earlier point |
| `ikat -c` / `ikat -r` | continue the last conversation here / pick an older one |
| `/init` | write `IKAT.md`: how to build and test the project; IKat reads it every session |
| `/` and `?` | all commands and all keys |

## Permissions

Before a command or a file change IKat shows what it is about to do and how risky it is. You can
allow it once, allow that kind of command for this project, or refuse and say what to do instead.

![IKat asks whether it may run git status, with the risk level and three answers](docs/ask.svg)

Modes change how much it asks. `Shift+Tab` moves between the first three; any of them can be set
with `/mode <name>` or `ikat --permission-mode <name>`.

| Mode | What it does |
|---|---|
| `default` | asks about commands and file changes |
| `accept-edits` | changes files in the project without asking, still asks about commands |
| `plan` | makes a plan and waits for your go before changing anything |
| `auto` | like `accept-edits`, and also runs commands that stay in the sandbox without asking (macOS and Linux) |
| `readonly` | reads, never writes or runs |

### Without any questions

`bypass-permissions` asks nothing at all, on every system, Windows included. Start a session in
it:

```sh
ikat --permission-mode bypass-permissions
```

or switch an open session with `/mode bypass-permissions`. To make it your default, put this into
`~/.ikat/settings.json`:

```json
{ "permissions": { "defaultMode": "bypass-permissions" } }
```

`Shift+Tab` never enters this mode, and a project's settings cannot turn it on. Your deny rules
and the protection of secrets (`.env` files, `~/.ssh`, cloud credentials) stay in force; anything
else goes through. On macOS and Linux commands still start in the sandbox, but one that needs to
leave it is let out without a question. Windows has no sandbox, so there a command can do whatever
you can. Use this mode in a container, a virtual machine or a copy of the project you can throw
away.

## Scripts and CI

```sh
ikat -p "Fix the failing test in cart.test.ts" --permission-mode accept-edits --allowed-tools "Bash(npm test:*)"
```

`-p` runs one task without the interface. It cannot ask, so whatever needs a question is refused,
and IKat prints the rule that would allow it. Give each rule its own `--allowed-tools`. In a
throwaway CI container, `--permission-mode bypass-permissions` lets it run everything.
`--output-format json` or `stream-json` makes the result readable by another program.

## Sandbox

On macOS and Linux, commands IKat runs can write only inside your project and a scratch folder,
and have no network unless your settings open it for certain hosts. Something like `npm install`
asks first and then runs outside the sandbox. Windows has no sandbox yet; if you want one there,
run IKat in WSL.

Project settings, such as commands a project allows without asking, take effect only after you
say you trust the folder. IKat shows you what they are first.

## Updating and removing

Run the install command again to update.

To remove IKat, delete the folder the installer created (`~/.ikat/bin`, or
`%LOCALAPPDATA%\ikat\bin` on Windows) and take it out of your PATH. Sessions and settings are in
`~/.ikat`.

## Problems

Run `ikat doctor`: it checks the terminal, Git, the model connection and your settings. If that
does not help, [open an issue](https://github.com/IKatCode/ikat-code/issues) with its output.

The interface is in English and Russian and follows your system's language.

## Privacy

Your code and requests go only to the model provider you chose. IKat has no telemetry.

## License

Free to use, at home and at work, commercial projects included. Not open source: please don't
redistribute it (link to this page instead), modify it or take it apart. The code IKat writes in
your projects is yours. Full text: [LICENSE](LICENSE).

IKat is built with open-source components, among them the Bun runtime. They keep their own
licenses, which come with every download in the file `THIRD-PARTY-NOTICES`.
