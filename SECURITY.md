# Security

IKat runs commands and changes files on your computer, so a security problem in it matters. If
you find one, please report it privately rather than in a public issue:

- through [Report a vulnerability](https://github.com/IKatCode/ikat-code/security/advisories/new)
  on this repository, or
- by email to ikatcodeofficial@gmail.com.

Say which version you used (`ikat --version`), on which system, and how to reproduce it. You will
get an answer within a few days. Once a fix is released, the advisory is published and, if you
like, names you.

Worth reporting: a way for a project, a web page or a tool's output to make IKat run a command
or change a file without asking (outside `bypass-permissions`), to read the secrets it protects
(`.env` files, `~/.ssh`, cloud credentials, its own login), to get around the sandbox on macOS or
Linux, or to make the installer accept a release that is not signed by IKat.

Only the latest release gets security fixes.
