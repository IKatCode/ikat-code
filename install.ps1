# Installs IKat Code on Windows (ADR 0027):
#   powershell -ExecutionPolicy ByPass -c "irm https://github.com/IKatCode/ikat-code/releases/latest/download/install.ps1 | iex"
#
# Downloads the release for this computer, checks it against SHA256SUMS and the release
# signature, puts ikat.exe and rg.exe into %LOCALAPPDATA%\ikat\bin and that folder onto the
# user's PATH. Run again to update. $env:IKAT_VERSION = '1.2.3' installs that version;
# $env:IKAT_INSTALL_DIR another folder.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Repository = 'https://github.com/IKatCode/ikat-code/releases'
# The release key (ed25519, OpenSSH format). Only checksums signed by its private half, in the
# `ikat-release` namespace, are trusted (ADR 0027).
$ReleaseKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJ1sNTbYadhe+abodUb6TfX5s62gtoO7V/N7mQEiB9r ikat-release'

function Fail([string] $Message) {
  Write-Host "ikat install: $Message" -ForegroundColor Red
  throw "ikat install: $Message"
}

function Get-Target {
  if ($env:IKAT_TARGET) { return $env:IKAT_TARGET }
  # The processor of the machine, not of this PowerShell: an x64 shell on Arm still gets arm64.
  $arch = $env:PROCESSOR_ARCHITEW6432
  if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
  switch ($arch) {
    'AMD64' { return 'windows-x64' }
    'ARM64' { return 'windows-arm64' }
    default { Fail "no release for the $arch processor" }
  }
}

function Get-File([string] $Url, [string] $Path) {
  # HTTPS only (TLS 1.2+); plain HTTP to this computer alone (tests).
  if ($Url -notmatch '^https://' -and $Url -notmatch '^http://(localhost|127\.0\.0\.1):') {
    Fail "refusing to download over plain HTTP: $Url"
  }
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
  for ($attempt = 1; ; $attempt++) {
    try {
      Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing -MaximumRedirection 10
      return
    } catch {
      if ($attempt -ge 3) { Fail "could not download $Url ($($_.Exception.Message))" }
      Start-Sleep -Seconds (2 * $attempt)
    }
  }
}

# 0: verified, 1: not signed by the release key, 2: no ssh-keygen to check with.
function Test-Signature([string] $Work) {
  $keygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
  if (-not $keygen) { return 2 }
  $signers = Join-Path $Work 'allowed_signers'
  Set-Content -Path $signers -Value "ikat-release namespaces=`"ikat-release`" $ReleaseKey" -Encoding ascii
  $sums = Join-Path $Work 'SHA256SUMS'
  $process = Start-Process -FilePath $keygen.Source -NoNewWindow -Wait -PassThru `
    -RedirectStandardInput $sums -RedirectStandardOutput (Join-Path $Work 'verify.out') `
    -RedirectStandardError (Join-Path $Work 'verify.err') `
    -ArgumentList @('-Y', 'verify', '-f', "`"$signers`"", '-I', 'ikat-release', '-n', 'ikat-release', '-s', "`"$sums.sig`"")
  if ($process.ExitCode -eq 0) { return 0 }
  return 1
}

function Add-ToPath([string] $Dir) {
  $current = [Environment]::GetEnvironmentVariable('Path', 'User')
  $parts = @()
  if ($current) { $parts = $current.Split(';') | Where-Object { $_ } }
  if ($parts -notcontains $Dir) {
    [Environment]::SetEnvironmentVariable('Path', (@($Dir) + $parts) -join ';', 'User')
    Write-Host "Added $Dir to your PATH; open a new terminal to use it."
  }
  if (($env:Path.Split(';')) -notcontains $Dir) { $env:Path = "$Dir;$env:Path" }
}

function Install-Ikat {
  $base = if ($env:IKAT_DOWNLOAD_URL) { $env:IKAT_DOWNLOAD_URL } else { $Repository }
  $platform = Get-Target
  $url = if ($env:IKAT_VERSION) { "$base/download/v$($env:IKAT_VERSION.TrimStart('v'))" } else { "$base/latest/download" }
  $dir = if ($env:IKAT_INSTALL_DIR) { $env:IKAT_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'ikat\bin' }
  $archive = "ikat-$platform.zip"

  $work = Join-Path ([IO.Path]::GetTempPath()) ("ikat-install-" + [Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $work | Out-Null
  try {
    Write-Host "Downloading IKat Code for $platform..."
    Get-File "$url/$archive" (Join-Path $work $archive)
    Get-File "$url/SHA256SUMS" (Join-Path $work 'SHA256SUMS')
    Get-File "$url/SHA256SUMS.sig" (Join-Path $work 'SHA256SUMS.sig')

    switch (Test-Signature $work) {
      0 { Write-Host 'Release signature verified.' }
      1 { Fail 'the release signature does not match: the download is not from IKat; nothing was installed' }
      default {
        if ($env:IKAT_SKIP_SIGNATURE -ne '1') {
          Fail 'ssh-keygen (OpenSSH client, a Windows optional feature) is needed to check the release signature; install it, or set $env:IKAT_SKIP_SIGNATURE = ''1'' to trust the checksum alone'
        }
        Write-Host 'The release signature was not checked (IKAT_SKIP_SIGNATURE=1): only the checksum is.'
      }
    }
    $expected = $null
    foreach ($line in Get-Content (Join-Path $work 'SHA256SUMS')) {
      $fields = $line -split '\s+', 2
      if ($fields.Count -eq 2 -and $fields[1].TrimStart('*') -eq $archive) { $expected = $fields[0].ToLower() }
    }
    if (-not $expected) { Fail "$archive is not in the release checksums" }
    $actual = (Get-FileHash -Algorithm SHA256 (Join-Path $work $archive)).Hash.ToLower()
    if ($actual -ne $expected) { Fail "the checksum of $archive does not match: the download is damaged; nothing was installed" }

    $files = Join-Path $work 'files'
    Expand-Archive -Path (Join-Path $work $archive) -DestinationPath $files
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    foreach ($name in @('ikat.exe', 'rg.exe')) {
      $source = Join-Path $files $name
      if (-not (Test-Path $source)) { continue }
      $target = Join-Path $dir $name
      # A running .exe cannot be overwritten but can be renamed: the old one steps aside.
      if (Test-Path $target) {
        Remove-Item -Force "$target.old" -ErrorAction SilentlyContinue
        Rename-Item -Path $target -NewName "$name.old"
      }
      Copy-Item -Path $source -Destination $target
    }
    # The licences go with the programs.
    foreach ($name in @('LICENSE', 'THIRD-PARTY-NOTICES')) {
      $source = Join-Path $files $name
      if (Test-Path $source) { Copy-Item -Force -Path $source -Destination (Join-Path $dir $name) }
    }
    Add-ToPath $dir
    $version = & (Join-Path $dir 'ikat.exe') --version
    Write-Host "$version is installed in $dir."
    Write-Host 'Start it in a project folder with: ikat - the first time it asks how to reach a model.'
  } finally {
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
  }
}

Install-Ikat
