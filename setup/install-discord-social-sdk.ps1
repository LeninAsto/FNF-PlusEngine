$ErrorActionPreference = 'Stop'

function Set-SdkEnv([string]$value) {
    if ($env:GITHUB_ENV) { Add-Content -LiteralPath $env:GITHUB_ENV -Value "DISCORD_SOCIAL_SDK_DIR=$value" }
    [Environment]::SetEnvironmentVariable('DISCORD_SOCIAL_SDK_DIR', $value, 'Process')
}

function Find-SdkRoot([string]$root) {
    $header = Get-ChildItem -LiteralPath $root -Filter discordpp.h -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '[\\/]include[\\/]discordpp\.h$' } | Select-Object -First 1
    if ($null -eq $header) { return $null }
    return (Split-Path (Split-Path $header.FullName -Parent) -Parent)
}

$existing = $env:DISCORD_SOCIAL_SDK_DIR
if ($existing -and (Test-Path (Join-Path $existing 'include/discordpp.h'))) {
    Set-SdkEnv ((Resolve-Path -LiteralPath $existing).Path)
    exit 0
}

$url = $env:DISCORD_SOCIAL_SDK_URL
$expected = if ($env:DISCORD_SOCIAL_SDK_SHA256) { $env:DISCORD_SOCIAL_SDK_SHA256.Trim().ToLowerInvariant() } else { '' }
if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($expected)) {
    throw 'Set DISCORD_SOCIAL_SDK_URL and DISCORD_SOCIAL_SDK_SHA256 secrets, or preinstall the SDK and set DISCORD_SOCIAL_SDK_DIR.'
}
if ($expected -notmatch '^[0-9a-f]{64}$') { throw 'DISCORD_SOCIAL_SDK_SHA256 must be a 64-character SHA-256 hex digest.' }

$work = Join-Path ($(if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP })) 'discord-social-sdk'
if (Test-Path $work) { Remove-Item -LiteralPath $work -Recurse -Force }
New-Item -ItemType Directory -Path $work | Out-Null
$archive = Join-Path $work 'sdk.zip'
$extract = Join-Path $work 'extracted'
Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
$actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $expected) { throw "Discord Social SDK checksum mismatch. Expected $expected, got $actual." }
Expand-Archive -LiteralPath $archive -DestinationPath $extract -Force
$sdkRoot = Find-SdkRoot $extract
if ($null -eq $sdkRoot) { throw 'The archive does not contain include/discordpp.h.' }
Set-SdkEnv ((Resolve-Path -LiteralPath $sdkRoot).Path)
