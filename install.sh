#!/bin/sh
# Installs IKat Code (ADR 0027):
#   curl -fsSL https://github.com/IKatCode/ikat-code/releases/latest/download/install.sh | sh
#
# Downloads the release for this computer, checks it against SHA256SUMS and the release
# signature, puts `ikat` and `rg` into ~/.ikat/bin and that folder onto the PATH. Run again to
# update. IKAT_VERSION=1.2.3 installs that version; IKAT_INSTALL_DIR another folder.
set -eu

REPOSITORY="https://github.com/IKatCode/ikat-code/releases"
# The release key (ed25519, OpenSSH format). Only checksums signed by its private half, in the
# `ikat-release` namespace, are trusted (ADR 0027).
RELEASE_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJ1sNTbYadhe+abodUb6TfX5s62gtoO7V/N7mQEiB9r ikat-release'

say() { printf '%s\n' "$*"; }
fail() {
  printf 'ikat install: %s\n' "$*" >&2
  exit 1
}

target() {
  os=$(uname -s)
  arch=$(uname -m)
  case "$os" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *) fail "this installer is for Linux and macOS; on Windows run install.ps1 in PowerShell" ;;
  esac
  case "$arch" in
    x86_64 | amd64) arch=x64 ;;
    aarch64 | arm64) arch=arm64 ;;
    *) fail "no release for the $arch processor" ;;
  esac
  # A Rosetta shell on Apple silicon reports x86_64; the native build is the one to run.
  if [ "$os" = darwin ] && [ "$arch" = x64 ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = 1 ]; then
    arch=arm64
  fi
  musl=""
  if [ "$os" = linux ] && { ls /lib/ld-musl-* >/dev/null 2>&1 || ldd --version 2>&1 | grep -qi musl; }; then
    musl="-musl"
  fi
  printf '%s-%s%s' "$os" "$arch" "$musl"
}

download() {
  # HTTPS only, also after redirects; plain HTTP is allowed to this computer alone (tests).
  case "$1" in
    http://localhost:* | http://127.0.0.1:*) proto='=http' ;;
    *) proto='=https' ;;
  esac
  if command -v curl >/dev/null 2>&1; then
    if [ "$proto" = '=https' ]; then
      curl -fsSL --proto '=https' --tlsv1.2 --retry 3 -o "$2" "$1"
    else
      curl -fsSL --retry 3 -o "$2" "$1"
    fi
  elif command -v wget >/dev/null 2>&1; then
    if [ "$proto" = '=https' ]; then
      wget -q --https-only -O "$2" "$1"
    else
      wget -q -O "$2" "$1"
    fi
  else
    fail "curl or wget is needed to download IKat"
  fi
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 "$1" | cut -d ' ' -f 1
  fi
}

# Checks SHA256SUMS against its signature with ssh-keygen (OpenSSH 8.1+, on macOS and nearly
# every Linux). 0: verified, 1: not signed by the release key, 2: no ssh-keygen to check with.
verify_signature() {
  command -v ssh-keygen >/dev/null 2>&1 || return 2
  printf 'ikat-release namespaces="ikat-release" %s\n' "$RELEASE_KEY" >"$work/allowed_signers"
  ssh-keygen -Y verify -f "$work/allowed_signers" -I ikat-release -n ikat-release \
    -s "$work/SHA256SUMS.sig" <"$work/SHA256SUMS" >/dev/null 2>&1 || return 1
}

profile_of() {
  case "${SHELL:-}" in
    */zsh) printf '%s' "$HOME/.zshrc" ;;
    */fish) printf '%s' "$HOME/.config/fish/config.fish" ;;
    */bash) printf '%s' "$HOME/.bashrc" ;;
    *) printf '%s' "$HOME/.profile" ;;
  esac
}

add_to_path() {
  profile=$(profile_of)
  case "$profile" in
    *.fish) line="fish_add_path $1" ;;
    *) line="export PATH=\"$1:\$PATH\"" ;;
  esac
  if [ -f "$profile" ] && grep -qF "$line" "$profile"; then
    return
  fi
  mkdir -p "$(dirname "$profile")"
  printf '\n# IKat Code\n%s\n' "$line" >>"$profile"
  say "Added $1 to the PATH in $profile; open a new terminal, or run: $line"
}

main() {
  base="${IKAT_DOWNLOAD_URL:-$REPOSITORY}"
  platform="${IKAT_TARGET:-}"
  [ -n "$platform" ] || platform=$(target)
  if [ -n "${IKAT_VERSION:-}" ]; then
    url="$base/download/v${IKAT_VERSION#v}"
  else
    url="$base/latest/download"
  fi
  dir="${IKAT_INSTALL_DIR:-$HOME/.ikat/bin}"
  # The folder goes into the shell profile: nothing in it may be read there as code.
  newline='
'
  case "$dir" in
    *[\\\"\'\`\$\;\&\|\<\>]* | *"$newline"*)
      fail "IKAT_INSTALL_DIR may not contain quotes, \$, backslashes, newlines or shell operators: $dir"
      ;;
  esac
  if [ "$(id -u)" = 0 ] && [ -z "${IKAT_INSTALL_DIR:-}" ]; then
    say "Installing for root: other users will not have IKat. Run the installer as yourself, without sudo, to install it for you."
  fi
  archive="ikat-$platform.tar.gz"

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT INT TERM
  say "Downloading IKat Code for $platform…"
  download "$url/$archive" "$work/$archive" || fail "could not download $url/$archive"
  download "$url/SHA256SUMS" "$work/SHA256SUMS" || fail "could not download the checksums"
  download "$url/SHA256SUMS.sig" "$work/SHA256SUMS.sig" || fail "could not download the signature"

  if verify_signature; then
    say "Release signature verified."
  else
    case $? in
      1) fail "the release signature does not match: the download is not from IKat; nothing was installed" ;;
      *)
        [ "${IKAT_SKIP_SIGNATURE:-}" = 1 ] ||
          fail "ssh-keygen (OpenSSH) is needed to check the release signature; install OpenSSH, or set IKAT_SKIP_SIGNATURE=1 to trust the checksum alone"
        say "The release signature was not checked (IKAT_SKIP_SIGNATURE=1): only the checksum is."
        ;;
    esac
  fi
  expected=$(awk -v name="$archive" '$2 == name || $2 == "*" name { print $1 }' "$work/SHA256SUMS")
  [ -n "$expected" ] || fail "$archive is not in the release checksums"
  [ "$(sha256 "$work/$archive")" = "$expected" ] ||
    fail "the checksum of $archive does not match: the download is damaged; nothing was installed"

  mkdir -p "$work/files" "$dir"
  tar -xzf "$work/$archive" -C "$work/files"
  for name in ikat rg; do
    [ -f "$work/files/$name" ] || continue
    # Next to the old file and then renamed over it: a running ikat keeps its copy.
    cp "$work/files/$name" "$dir/.$name.new"
    chmod 755 "$dir/.$name.new"
    mv -f "$dir/.$name.new" "$dir/$name"
  done

  case ":${PATH}:" in
    *":$dir:"*) ;;
    *) add_to_path "$dir" ;;
  esac
  say "$("$dir/ikat" --version) is installed in $dir."
  say "Start it in a project folder with: ikat — then sign in to your ChatGPT plan with: ikat login"
}

main "$@"
