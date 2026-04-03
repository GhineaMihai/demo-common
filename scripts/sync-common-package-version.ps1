param(
    [string]$WorkspaceRoot = $env:GITHUB_WORKSPACE,
    [string]$Branch = "dev",
    [switch]$Commit,
    [switch]$Push
)

$ErrorActionPreference = "Stop"

if ($Push -and -not $Commit) {
    throw "Push requires -Commit"
}

$commonPropsPath = Join-Path $WorkspaceRoot "src\Directory.Build.props"
$targetRepoPath = Join-Path $WorkspaceRoot "demo-target"
$projectFile = Join-Path $targetRepoPath "src\Demo.Target\Demo.Target.csproj"
$relativePath = "src/Demo.Target/Demo.Target.csproj"

[xml]$commonXml = Get-Content $commonPropsPath

$baseVersion = [string]$commonXml.Project.PropertyGroup.BaseVersion
$suffix = [string]$commonXml.Project.PropertyGroup.PreReleaseSuffix
$iteration = [string]$commonXml.Project.PropertyGroup.PreReleaseIteration

if ([string]::IsNullOrWhiteSpace($suffix) -and [string]::IsNullOrWhiteSpace($iteration)) {
    $fullVersion = $baseVersion
}
elseif (-not [string]::IsNullOrWhiteSpace($suffix) -and -not [string]::IsNullOrWhiteSpace($iteration)) {
    $fullVersion = "$baseVersion-$suffix.$iteration"
}
elseif ([string]::IsNullOrWhiteSpace($suffix) -and -not [string]::IsNullOrWhiteSpace($iteration)) {
    $fullVersion = "$baseVersion.$iteration"
}
else {
    throw "Invalid version configuration"
}

$content = [System.IO.File]::ReadAllText($projectFile)
$updatedContent = [System.Text.RegularExpressions.Regex]::Replace(
    $content,
    "(<BtCmsCommonPackagesVersion>)(.*?)(</BtCmsCommonPackagesVersion>)",
    [System.Text.RegularExpressions.MatchEvaluator]{
        param($match)
        $match.Groups[1].Value + $fullVersion + $match.Groups[3].Value
    },
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

if ($updatedContent -eq $content) {
    Write-Host "No change needed"
    exit 0
}

[System.IO.File]::WriteAllText($projectFile, $updatedContent, [System.Text.UTF8Encoding]::new($true))

if ($Commit) {
    git -C $targetRepoPath add $relativePath
    git -C $targetRepoPath commit -m "chore: sync BtCmsCommonPackagesVersion to $fullVersion"
}

if ($Push) {
    git -C $targetRepoPath push origin "HEAD:$Branch"
}