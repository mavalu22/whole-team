# WholeTeam installer for Windows PowerShell 5.1+ and PowerShell 7+.
# Copies the factory into an existing git project, or updates an installed one.
# Requires only PowerShell and git. See README.md, section "Install".
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 [-Path <project>] [-Type new|ongoing] [-Mode install|update] [-Yes] [-Help]

param(
    [string]$Path = "",
    [string]$Type = "",
    [string]$Mode = "",
    [switch]$Yes,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$BlockBeginMd = '<!-- >>> whole-team >>> -->'
$BlockEndMd = '<!-- <<< whole-team <<< -->'
$BlockBeginIgnore = '# >>> whole-team >>>'
$BlockEndIgnore = '# <<< whole-team <<<'
$GuideFiles = @('CLAUDE.md', 'AGENTS.md', 'CLAUDE.local.md', 'AGENTS.override.md')
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$script:Project = ""
$script:OldManifest = @()
$script:NewManifest = New-Object System.Collections.ArrayList

function Show-Usage {
    $text = @'
Usage: powershell -ExecutionPolicy Bypass -File .\install.ps1 [-Path <project>] [-Type new|ongoing] [-Mode install|update] [-Yes] [-Help]

Installs WholeTeam into an existing git project, or updates an installed one.

Options:
  -Path <project>   Project folder (must already be a git repository).
  -Type <type>      new     = a new product; Discovery starts from the idea.
                    ongoing = an existing codebase; Discovery starts by analysing the code.
  -Mode <mode>      install or update. Detected automatically when omitted.
  -Yes              Accept defaults and never prompt. Fails if the path is missing.
  -Help             Show this help.

Any missing value is asked interactively.
'@
    Write-Host $text
}

function Write-Info([string]$Message) { Write-Host $Message }
function Write-Warn([string]$Message) { [Console]::Error.WriteLine("Warning: $Message") }
function Fail([string]$Message) {
    [Console]::Error.WriteLine("Error: $Message")
    exit 1
}

function Read-Answer([string]$Prompt, [string]$Default) {
    if ($Yes) { return $Default }
    $answer = Read-Host $Prompt
    if ($null -eq $answer -or $answer -eq '') { return $Default }
    return $answer
}

function Confirm-Choice([string]$Prompt) {
    $answer = Read-Answer "$Prompt [Y/n]" 'y'
    return -not ($answer -match '^(n|no)$')
}

function Read-Text([string]$File) { return [System.IO.File]::ReadAllText($File) }
function Write-Text([string]$File, [string]$Text) { [System.IO.File]::WriteAllText($File, $Text, $Utf8NoBom) }

function Invoke-Git([string[]]$GitArgs) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git @GitArgs 2>$null
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
    return New-Object PSObject -Property @{ Code = $code; Out = $output }
}

function Get-FullPath([string]$Candidate) {
    $resolved = (Resolve-Path -LiteralPath $Candidate).ProviderPath
    if ($resolved.Length -gt 1) {
        $trimmed = $resolved.TrimEnd('\', '/')
        if ($trimmed -eq '') { $trimmed = '/' }
        if ($trimmed -match '^[A-Za-z]:$') { $trimmed = $trimmed + '\' }
        $resolved = $trimmed
    }
    return $resolved
}

# Trim, strip one pair of wrapping quotes, expand a leading ~, resolve to an absolute path.
function Get-NormalizedPath([string]$Raw) {
    $p = $Raw.Trim()
    if ($p.Length -ge 2) {
        if (($p.StartsWith('"') -and $p.EndsWith('"')) -or ($p.StartsWith("'") -and $p.EndsWith("'"))) {
            $p = $p.Substring(1, $p.Length - 2)
        }
    }
    if ($p -eq '~') {
        $p = $HOME
    } elseif ($p.StartsWith('~/') -or $p.StartsWith('~\')) {
        $p = [System.IO.Path]::Combine($HOME, $p.Substring(2))
    }
    if ($p -ne '' -and (Test-Path -LiteralPath $p -PathType Container)) {
        return Get-FullPath $p
    }
    return $p
}

function Join-ProjectPath([string]$Relative) {
    return [System.IO.Path]::Combine($script:Project, $Relative)
}

function Test-Tracked([string]$Relative) {
    $result = Invoke-Git @('-C', $script:Project, 'ls-files', '--error-unmatch', '--', $Relative)
    return ($result.Code -eq 0)
}

function Get-LineText([string]$Line) { return $Line.TrimEnd("`r") }

# Replace the text between the markers, or append the block after a blank line.
function Update-Block([string]$File, [string]$BlockText, [string]$Begin, [string]$End) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        Write-Text $File $BlockText
        return
    }
    $content = Read-Text $File
    $lines = $content -split "`n"
    $beginIndex = -1
    $endIndex = -1
    $anyEnd = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = Get-LineText $lines[$i]
        if ($line -ceq $End) { $anyEnd = $true }
        if ($beginIndex -lt 0 -and $line -ceq $Begin) {
            $beginIndex = $i
        } elseif ($beginIndex -ge 0 -and $endIndex -lt 0 -and $line -ceq $End) {
            $endIndex = $i
        }
    }
    if ($beginIndex -ge 0 -and $endIndex -ge 0) {
        $blockLines = $BlockText -split "`n"
        $output = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $beginIndex; $i++) { [void]$output.Add($lines[$i]) }
        for ($i = 0; $i -lt ($blockLines.Count - 1); $i++) { [void]$output.Add($blockLines[$i]) }
        for ($i = $endIndex + 1; $i -lt $lines.Count; $i++) { [void]$output.Add($lines[$i]) }
        Write-Text $File ([string]::Join("`n", $output.ToArray()))
    } elseif ($beginIndex -ge 0 -or $anyEnd) {
        Fail "$File has an incomplete WholeTeam block (one marker is missing). Fix or remove the markers, then run the installer again."
    } else {
        $output = $content
        if ($output.Length -gt 0) {
            if (-not $output.EndsWith("`n")) { $output = $output + "`n" }
            $output = $output + "`n"
        }
        Write-Text $File ($output + $BlockText)
    }
}

function Get-ManifestStatus([string]$Relative) {
    foreach ($entry in $script:OldManifest) {
        if ($entry.File -eq $Relative) { return $entry.Action }
    }
    return ''
}

function Test-ManifestHas([string]$Relative) {
    return ((Get-ManifestStatus $Relative) -ne '')
}

function Add-Record([string]$Action, [string]$Relative) {
    if ((Get-ManifestStatus $Relative) -eq 'created') { $Action = 'created' }
    [void]$script:NewManifest.Add((New-Object PSObject -Property @{ Action = $Action; File = $Relative }))
}

function Read-Manifest([string]$File) {
    $entries = @()
    if (Test-Path -LiteralPath $File -PathType Leaf) {
        foreach ($raw in ((Read-Text $File) -split "`n")) {
            $line = (Get-LineText $raw).Trim()
            if ($line -eq '') { continue }
            $parts = $line -split ' ', 2
            if ($parts.Count -eq 2) {
                $entries += New-Object PSObject -Property @{ Action = $parts[0]; File = $parts[1] }
            }
        }
    }
    return ,$entries
}

# Section 4.3 rules for one tool's guide file and its local-only fallback.
function Set-GuideFile([string]$Main, [string]$Fallback, [string]$BlockFile) {
    $block = Read-Text $BlockFile
    $mainPath = Join-ProjectPath $Main
    $fallbackPath = Join-ProjectPath $Fallback
    if (-not (Test-Path -LiteralPath $mainPath)) {
        Update-Block $mainPath $block $BlockBeginMd $BlockEndMd
        Add-Record 'created' $Main
    } elseif (-not (Test-Tracked $Main)) {
        Update-Block $mainPath $block $BlockBeginMd $BlockEndMd
        Add-Record 'block' $Main
    } else {
        if (Test-Tracked $Fallback) {
            Fail "$Main and $Fallback are both tracked by git. Untrack $Fallback (git rm --cached $Fallback), or paste the block from $BlockFile into it by hand, then run the installer again."
        }
        if (Test-Path -LiteralPath $fallbackPath) {
            Update-Block $fallbackPath $block $BlockBeginMd $BlockEndMd
            Add-Record 'block' $Fallback
        } else {
            Update-Block $fallbackPath $block $BlockBeginMd $BlockEndMd
            Add-Record 'created' $Fallback
        }
        Write-Info "  $Main is tracked by git: left untouched; the WholeTeam block is in $Fallback."
    }
}

# Section 4.4 block, listing only the guide files the factory created.
function Get-IgnoreBlock {
    $lines = @($BlockBeginIgnore, '/factory/', '/.claude/agents/factory-*.md', '/.codex/agents/factory-*.toml')
    foreach ($name in $GuideFiles) {
        foreach ($entry in $script:NewManifest) {
            if ($entry.Action -eq 'created' -and $entry.File -eq $name) { $lines += "/$name" }
        }
    }
    $lines += $BlockEndIgnore
    return ([string]::Join("`n", $lines) + "`n")
}

function Set-IgnoreBlock {
    $target = '.gitignore'
    foreach ($entry in $script:OldManifest) {
        if ($GuideFiles -notcontains $entry.File) { $target = $entry.File; break }
    }
    if ([System.IO.Path]::IsPathRooted($target)) {
        $absolute = $target
    } else {
        $absolute = Join-ProjectPath $target
    }
    $block = Get-IgnoreBlock
    if (-not (Test-Path -LiteralPath $absolute)) {
        $parent = Split-Path -Parent $absolute
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Update-Block $absolute $block $BlockBeginIgnore $BlockEndIgnore
        Add-Record 'created' $target
    } else {
        Update-Block $absolute $block $BlockBeginIgnore $BlockEndIgnore
        Add-Record 'block' $target
    }
}

function Set-RootFiles([string]$RunMode) {
    $script:NewManifest = New-Object System.Collections.ArrayList
    $template = $script:Template
    if ($RunMode -eq 'install' -or (Test-ManifestHas 'CLAUDE.md') -or (Test-ManifestHas 'CLAUDE.local.md')) {
        Set-GuideFile 'CLAUDE.md' 'CLAUDE.local.md' ([System.IO.Path]::Combine($template, 'root', 'CLAUDE.md'))
    }
    if ($RunMode -eq 'install' -or (Test-ManifestHas 'AGENTS.md') -or (Test-ManifestHas 'AGENTS.override.md')) {
        Set-GuideFile 'AGENTS.md' 'AGENTS.override.md' ([System.IO.Path]::Combine($template, 'root', 'AGENTS.md'))
    }
    Set-IgnoreBlock
    $text = ''
    foreach ($entry in $script:NewManifest) { $text += "$($entry.Action) $($entry.File)`n" }
    Write-Text (Join-ProjectPath 'factory/.install-manifest') $text
}

function Show-RootSummary {
    Write-Info 'Root files:'
    foreach ($entry in (Read-Manifest (Join-ProjectPath 'factory/.install-manifest'))) {
        if ($entry.Action -eq 'created') {
            Write-Info "  created    $($entry.File)"
        } else {
            Write-Info "  block in   $($entry.File)"
        }
    }
}

function Set-ConfigType([string]$ProjectType) {
    $file = Join-ProjectPath 'factory/config.yaml'
    $lines = (Read-Text $file) -split "`n"
    $inProject = $false
    $done = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^project:') { $inProject = $true; continue }
        if ($inProject -and $line -match '^[^ #]') { $inProject = $false }
        if ($inProject -and -not $done -and $line -match '^  type:') {
            $lines[$i] = "  type: $ProjectType"
            $done = $true
        }
    }
    if (-not $done) { Fail "Could not set project.type in $file." }
    Write-Text $file ([string]::Join("`n", $lines))
}

function Set-StateVersion {
    $file = Join-ProjectPath 'factory/state.yaml'
    $lines = (Read-Text $file) -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^factory_version:') {
            $lines[$i] = "factory_version: `"$script:Version`""
            break
        }
    }
    Write-Text $file ([string]::Join("`n", $lines))
}

function Copy-Agents {
    $pairs = @(@('.claude', 'factory-*.md'), @('.codex', 'factory-*.toml'))
    foreach ($pair in $pairs) {
        $targetDir = Join-ProjectPath ([System.IO.Path]::Combine($pair[0], 'agents'))
        if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        Get-ChildItem -LiteralPath $targetDir -Filter $pair[1] -File | Remove-Item -Force
        $sourceDir = [System.IO.Path]::Combine($script:Template, 'root', $pair[0], 'agents')
        Get-ChildItem -LiteralPath $sourceDir -Filter $pair[1] -File | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination ([System.IO.Path]::Combine($targetDir, $_.Name)) -Force
        }
    }
    $marker = 'The WholeTeam installer rewrote the agent files with default models.' + "`n" +
        'On the next `Let''s code`, the Orchestrator re-applies the models block of factory/config.yaml and deletes this file.' + "`n"
    Write-Text (Join-ProjectPath 'factory/.models-sync-needed') $marker
}

function Write-CoreVersion {
    Write-Text (Join-ProjectPath 'factory/core/VERSION') ("$script:Version" + "`n")
}

function Get-GitignoreState {
    if (-not (Test-Tracked '.gitignore')) { return '' }
    $result = Invoke-Git @('-C', $script:Project, 'diff', '--quiet', '--', '.gitignore')
    if ($result.Code -eq 0) { return 'clean' }
    return 'dirty'
}

function Invoke-Install {
    $projectType = $Type
    if ($projectType -eq '') {
        if ($Yes) {
            $projectType = 'new'
        } else {
            Write-Info ''
            Write-Info 'Project type:'
            Write-Info '  1) new      A new product; Discovery starts from the idea.'
            Write-Info '  2) ongoing  An existing codebase; Discovery starts by analysing the code.'
            while ($projectType -eq '') {
                $choice = Read-Answer 'Choose 1 or 2 [1]' '1'
                if ($choice -eq '1' -or $choice -eq 'new') { $projectType = 'new' }
                elseif ($choice -eq '2' -or $choice -eq 'ongoing') { $projectType = 'ongoing' }
                else { Write-Warn 'Please answer 1 (new) or 2 (ongoing).' }
            }
        }
    }

    Write-Info ''
    Write-Info "Installing WholeTeam $script:Version into $script:Project (type: $projectType) ..."
    Copy-Item -LiteralPath ([System.IO.Path]::Combine($script:Template, 'factory')) -Destination (Join-ProjectPath 'factory') -Recurse
    Write-CoreVersion
    Set-ConfigType $projectType
    Set-StateVersion
    Copy-Agents
    $script:OldManifest = @()
    Set-RootFiles 'install'

    Write-Info ''
    Write-Info "WholeTeam $script:Version is installed."
    Show-RootSummary
    Write-Info ''
    Write-Info 'Next steps:'
    Write-Info "  1. Open the project in VS Code:  code `"$script:Project`""
    Write-Info '  2. Start Claude Code (claude) or Codex (codex) in the project root.'
    Write-Info "     Recommended main-session model: Claude Code 'sonnet'; Codex 'gpt-6-sol' at medium effort."
    Write-Info "  3. Type: Let's code"
    Write-Info ''
    Write-Info 'Factory files live in factory/, which git ignores. Back that folder up.'
}

function Invoke-Update {
    $installed = (Read-Text (Join-ProjectPath 'factory/core/VERSION')).Trim()
    Write-Info ''
    Write-Info "Updating WholeTeam $installed -> $script:Version in $script:Project ..."

    Remove-Item -LiteralPath (Join-ProjectPath 'factory/core') -Recurse -Force
    Copy-Item -LiteralPath ([System.IO.Path]::Combine($script:Template, 'factory', 'core')) -Destination (Join-ProjectPath 'factory/core') -Recurse
    Write-CoreVersion
    Copy-Agents

    $manifestPath = Join-ProjectPath 'factory/.install-manifest'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        Write-Warn 'factory/.install-manifest is missing; the root files are handled as in a new install.'
    }
    $script:OldManifest = Read-Manifest $manifestPath
    $before = Get-GitignoreState
    if ($script:OldManifest.Count -gt 0) {
        Set-RootFiles 'update'
    } else {
        Set-RootFiles 'install'
    }
    if ($before -eq 'clean' -and (Get-GitignoreState) -eq 'dirty') {
        Write-Info '  The WholeTeam block in .gitignore changed. Commit it:'
        Write-Info '    git add .gitignore && git commit -m "chore: update WholeTeam ignore rules"'
    }

    $copied = 0
    $sourceRoot = [System.IO.Path]::Combine($script:Template, 'factory')
    $sourceFull = (Get-Item -LiteralPath $sourceRoot).FullName.TrimEnd('\', '/')
    $relatives = @()
    foreach ($item in (Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Force)) {
        $relative = $item.FullName.Substring($sourceFull.Length + 1) -replace '\\', '/'
        if ($relative -like 'core/*') { continue }
        $relatives += $relative
    }
    foreach ($relative in ($relatives | Sort-Object)) {
        $destination = Join-ProjectPath ('factory/' + $relative)
        if (-not (Test-Path -LiteralPath $destination)) {
            $parent = Split-Path -Parent $destination
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item -LiteralPath ([System.IO.Path]::Combine($sourceRoot, $relative)) -Destination $destination
            $copied++
            Write-Info "  added missing starting file factory/$relative"
        }
    }

    Write-Info ''
    Write-Info "WholeTeam is updated to $script:Version."
    Show-RootSummary
    if ($copied -eq 0) {
        Write-Info 'No starting files were missing. Your config, state, tasks, bugs, input and output were not touched.'
    }
    Write-Info ''
    Write-Info "On your next ``Let's code``, the Orchestrator will migrate your config and state to the new version if needed."
    Write-Info "The update reset the agent files to the default models; the next ``Let's code`` re-applies the models from factory/config.yaml."
}

# --- Main ---------------------------------------------------------------------

if ($Help) { Show-Usage; exit 0 }
if (@('', 'new', 'ongoing') -notcontains $Type) { Fail '-Type must be new or ongoing.' }
if (@('', 'install', 'update') -notcontains $Mode) { Fail '-Mode must be install or update.' }
$Type = $Type.ToLowerInvariant()
$Mode = $Mode.ToLowerInvariant()

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail 'git was not found on PATH. Install git, then run the installer again.'
}
$script:ScriptDir = Get-FullPath $PSScriptRoot
$script:Template = [System.IO.Path]::Combine($script:ScriptDir, 'template')
$versionFile = [System.IO.Path]::Combine($script:ScriptDir, 'VERSION')
if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf) -or -not (Test-Path -LiteralPath ([System.IO.Path]::Combine($script:Template, 'factory', 'core')) -PathType Container)) {
    Fail 'Run this script from a complete WholeTeam folder (VERSION or template/ is missing next to it).'
}
$script:Version = (Read-Text $versionFile).Trim()

Write-Info "WholeTeam installer $script:Version"

$raw = $Path
if ($raw -eq '') {
    if ($Yes) { Fail '-Yes needs -Path <project>.' }
    $raw = Read-Answer 'Path to your project folder (paste it here)' ''
    if ($raw -eq '') { Fail 'No path given.' }
}
$script:Project = Get-NormalizedPath $raw
if ($script:Project -eq '' -or -not (Test-Path -LiteralPath $script:Project -PathType Container)) {
    Fail "Folder not found: $($script:Project). The factory never creates project folders: create or clone your project first, then run the installer again."
}

$inside = Invoke-Git @('-C', $script:Project, 'rev-parse', '--is-inside-work-tree')
if ($inside.Code -ne 0) {
    Fail 'This folder is not a git repository. Create or clone your project first, then run the installer again.'
}
$prefix = Invoke-Git @('-C', $script:Project, 'rev-parse', '--show-prefix')
$prefixText = [string]($prefix.Out | Select-Object -First 1)
if ($prefixText -ne '') {
    $topResult = Invoke-Git @('-C', $script:Project, 'rev-parse', '--show-toplevel')
    $top = Get-NormalizedPath ([string]($topResult.Out | Select-Object -First 1))
    Write-Info "This folder is inside the git repository at: $top"
    if (Confirm-Choice "WholeTeam installs at the repository top level. Use $($top)?") {
        $script:Project = $top
    } else {
        Fail "Installation cancelled. Run the installer with the repository's top-level folder."
    }
}
$isSelf = ($script:Project -eq $script:ScriptDir)
if ((Test-Path -LiteralPath (Join-ProjectPath 'install.sh')) -and (Test-Path -LiteralPath (Join-ProjectPath 'template/factory/core/FACTORY.md'))) { $isSelf = $true }
if ($isSelf) { Fail 'This is the WholeTeam folder itself. Give the path of your project instead.' }

$installed = ''
$coreVersion = Join-ProjectPath 'factory/core/VERSION'
if (Test-Path -LiteralPath $coreVersion -PathType Leaf) {
    $installed = (Read-Text $coreVersion).Trim()
    $proposed = 'update'
    Write-Info "WholeTeam $installed is installed in this project; the new version is $script:Version."
} elseif (Test-Path -LiteralPath (Join-ProjectPath 'factory')) {
    Fail "$(Join-ProjectPath 'factory') exists but is not a WholeTeam installation (factory/core/VERSION is missing). Rename or move that folder, then run the installer again."
} else {
    $proposed = 'install'
}

$runMode = $Mode
if ($runMode -eq '') {
    if ($proposed -eq 'update') {
        if (-not (Confirm-Choice "Update WholeTeam $installed -> $($script:Version)?")) { Write-Info 'Nothing changed.'; exit 0 }
    } else {
        if (-not (Confirm-Choice "Install WholeTeam $($script:Version) into $($script:Project)?")) { Write-Info 'Nothing changed.'; exit 0 }
    }
    $runMode = $proposed
} elseif ($runMode -eq 'install' -and $proposed -eq 'update') {
    Write-Info 'WholeTeam is already installed here: running update instead, so your factory files are kept.'
    $runMode = 'update'
} elseif ($runMode -eq 'update' -and $proposed -eq 'install') {
    Fail "WholeTeam is not installed in $($script:Project). Run the installer with -Mode install."
}

if ($runMode -eq 'install') {
    Invoke-Install
} else {
    Invoke-Update
}
exit 0
