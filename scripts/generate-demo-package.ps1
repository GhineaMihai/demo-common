param([string]$WorkspaceRoot = $env:GITHUB_WORKSPACE)

$propsPath = Join-Path $WorkspaceRoot "src\Directory.Build.props"
[xml]$xml = Get-Content $propsPath

$baseVersion = [string]$xml.Project.PropertyGroup.BaseVersion
$suffix = [string]$xml.Project.PropertyGroup.PreReleaseSuffix
$iteration = [string]$xml.Project.PropertyGroup.PreReleaseIteration

if ([string]::IsNullOrWhiteSpace($suffix) -and [string]::IsNullOrWhiteSpace($iteration)) {
    $fullVersion = $baseVersion
}
elseif (-not [string]::IsNullOrWhiteSpace($suffix) -and -not [string]::IsNullOrWhiteSpace($iteration)) {
    $fullVersion = "$baseVersion-$suffix.$iteration"
}
elseif ([string]::IsNullOrWhiteSpace($suffix) -and -not [string]::IsNullOrWhiteSpace($iteration)) {
    $fullVersion = "$baseVersion.$PreReleaseIteration"
}
else {
    throw "Invalid version configuration"
}

$outDir = Join-Path $WorkspaceRoot "artifacts"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
Set-Content -Path (Join-Path $outDir "Demo.Common.$fullVersion.nupkg") -Value "demo package $fullVersion"