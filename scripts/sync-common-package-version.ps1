param(
    [string]$WorkspaceRoot = $env:CI_PROJECT_DIR,
    [string]$Branch = "dev"
)

$ErrorActionPreference = "Stop"

$commonPropsPath = Join-Path $WorkspaceRoot "src/Directory.Build.props"
$targetRepoPath = Join-Path $WorkspaceRoot "demo-target"
$projectFile = Join-Path $targetRepoPath "src/Demo.Target/Demo.Target.csproj"
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
    '(<BtCmsCommonPackagesVersion>)(.*?)(</BtCmsCommonPackagesVersion>)',
    [System.Text.RegularExpressions.MatchEvaluator]{
        param($match)
        $match.Groups[1].Value + $fullVersion + $match.Groups[3].Value
    },
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

[System.IO.File]::WriteAllText($projectFile, $updatedContent, [System.Text.UTF8Encoding]::new($true))

git -C $targetRepoPath add $relativePath
git -C $targetRepoPath commit -m "chore: sync BtCmsCommonPackagesVersion to $fullVersion"
git -C $targetRepoPath push origin "HEAD:$Branch"