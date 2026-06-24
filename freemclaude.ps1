# freemclaude — run Claude Code against FreeModel's Anthropic-compatible API (Windows).
#
# Key resolution order:
#   1. `freemclaude config [KEY]` — set/replace the stored key (inline or prompt)
#   2. stored config file          — set on a previous run
#   3. $env:FREEMODEL_API_KEY      — used and saved for next time
#   4. interactive prompt          — asks for the key if you haven't included it yet

$ErrorActionPreference = 'Stop'

$ConfigDir  = Join-Path $env:APPDATA 'freemclaude'
$ConfigFile = Join-Path $ConfigDir 'config'

function Save-Key([string]$Key) {
  $Key = $Key.Trim()
  if ([string]::IsNullOrEmpty($Key)) {
    Write-Host 'Refusing to save an empty key.'
    return
  }
  New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
  Set-Content -Path $ConfigFile -Value ("FREEMODEL_API_KEY=" + $Key) -Encoding ASCII
  # Restrict the file to the current user only.
  try {
    $acl  = New-Object System.Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
      "$env:USERDOMAIN\$env:USERNAME", 'FullControl', 'Allow')
    $acl.AddAccessRule($rule)
    Set-Acl -Path $ConfigFile -AclObject $acl
  } catch { }
  Write-Host "Key saved to $ConfigFile"
}

function Get-Key {
  if (-not (Test-Path $ConfigFile)) { return $null }
  foreach ($line in Get-Content $ConfigFile) {
    if ($line -like 'FREEMODEL_API_KEY=*') {
      return $line.Substring('FREEMODEL_API_KEY='.Length)
    }
  }
  return $null
}

function Invoke-Setup {
  Write-Host ''
  Write-Host '+------------------------------------------+'
  Write-Host '|  freemclaude - first-time setup          |'
  Write-Host '+------------------------------------------+'
  Write-Host ''
  Write-Host "Claude Code will run against FreeModel's API."
  Write-Host 'You only need to enter your key once.'
  Write-Host 'Get a key: https://freemodel.dev/dashboard'
  Write-Host ''
  for ($i = 0; $i -lt 3; $i++) {
    $secure = Read-Host -AsSecureString 'FreeModel API key'
    $bstr   = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $key    = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    $key = $key.Trim()
    if ($key) { Save-Key $key; return }
    Write-Host "Key can't be empty."
  }
  Write-Host 'Aborting after 3 empty attempts.'
  exit 1
}

# --- subcommands -----------------------------------------------------------
if ($args.Count -ge 1) {
  switch -Regex ($args[0]) {
    '^(config|--config|set-key|--set-key|change|--change|change-key|--change-key|login|--login)$' {
      if ($args.Count -ge 2) { Save-Key $args[1] } else { Invoke-Setup }
      Write-Host "Done. Run 'freemclaude' to start."
      exit 0
    }
    '^(reset|--reset|logout|--logout)$' {
      if (Test-Path $ConfigFile) { Remove-Item $ConfigFile -Force }
      Write-Host 'Stored key removed (logged out).'
      exit 0
    }
    '^(update|--update|upgrade|--upgrade)$' {
      Write-Host 'Updating freemclaude to the latest version...'
      Write-Host 'Please pull updates from your git repository or re-run the installer.'
      exit 0
    }
  }
}

function Test-ApiKey([string]$Key) {
  $body = @{
    model = "gpt-5.5"
    messages = @(
      @{ role = "user"; content = "ping" }
    )
    max_tokens = 1
  } | ConvertTo-Json
  
  try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
    $response = Invoke-WebRequest -Uri 'https://api.freemodel.dev/v1/chat/completions' -Method Post -Headers @{'Authorization'="Bearer $Key"} -Body $body -ContentType 'application/json' -TimeoutSec 5 -ErrorAction Stop | Out-Null
    return $true
  } catch {
    if ($_.Exception -and $_.Exception.Response) {
      $statusCode = [int]$_.Exception.Response.StatusCode
      if ($statusCode -eq 401 -or $statusCode -eq 403) {
        return $false
      }
    }
    return $true
  }
}

# --- resolve the key -------------------------------------------------------
$key = Get-Key

if (-not $key -and $env:FREEMODEL_API_KEY) {
  $key = $env:FREEMODEL_API_KEY.Trim()
  Write-Host 'Using FREEMODEL_API_KEY from environment; saving for next time.'
  Save-Key $key
}

if (-not $key) {
  Invoke-Setup
  $key = Get-Key
}

if (-not $key) {
  Write-Host "No API key available. Run 'freemclaude config' to set one."
  exit 1
}

# --- check if key is valid --------------------------------------------------
if (-not (Test-ApiKey $key)) {
  Write-Host ''
  Write-Warning 'Stored FreeModel API key is invalid, expired, or unauthorized.'
  $choice = Read-Host 'Would you like to enter a new FreeModel API key? (Y/N)'
  if ($choice -and $choice.Trim().ToUpper() -eq 'Y') {
    Invoke-Setup
    $key = Get-Key
  } else {
    Write-Host 'Aborting launch.'
    exit 1
  }
}

# --- launch ----------------------------------------------------------------
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Host 'claude CLI not found on PATH.'
  Write-Host 'Install Claude Code first: https://docs.claude.com/en/docs/claude-code'
  exit 127
}

$env:ANTHROPIC_BASE_URL                 = 'https://cc.freemodel.dev'
$env:ANTHROPIC_AUTH_TOKEN               = $key
if (Test-Path env:\ANTHROPIC_API_KEY) { Remove-Item env:\ANTHROPIC_API_KEY }
$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = '1'

& claude --dangerously-skip-permissions @args
exit $LASTEXITCODE
