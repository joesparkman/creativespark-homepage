$ErrorActionPreference = "Stop"

$gh = "C:\Program Files\GitHub CLI\gh.exe"
if (-not (Test-Path $gh)) {
  throw "GitHub CLI not found at $gh"
}

$repos = @(
  "joesparkman/creativespark-homepage",
  "joesparkman/biometric",
  "joesparkman/call-triage-pipeline",
  "joesparkman/pet-recipe",
  "joesparkman/QuickBite",
  "joesparkman/fifa-neon-soccer",
  "joesparkman/creativespark-identity-hub",
  "joesparkman/food-scanner"
)

Write-Host "Checking GitHub auth..." -ForegroundColor Cyan
& $gh auth status | Out-Null

foreach ($repo in $repos) {
  Write-Host "\n=== Resetting $repo ===" -ForegroundColor Cyan

  # Read current metadata so recreated repo keeps core settings.
  $json = & $gh repo view $repo --json nameWithOwner,visibility,description,homepageUrl,hasIssuesEnabled,hasWikiEnabled
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to read repo metadata for $repo"
  }

  $meta = $json | ConvertFrom-Json

  $visibilitySwitch = switch ($meta.visibility) {
    "PUBLIC" { "--public" }
    "PRIVATE" { "--private" }
    "INTERNAL" { "--internal" }
    default { "--private" }
  }

  # Delete the repository and wait briefly for name availability.
  & $gh repo delete $repo --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to delete $repo"
  }

  $owner = $repo.Split("/")[0]
  $name = $repo.Split("/")[1]

  $createArgs = @("repo", "create", "$owner/$name", $visibilitySwitch)

  if ($meta.description) {
    $createArgs += @("--description", $meta.description)
  }

  if ($meta.homepageUrl) {
    $createArgs += @("--homepage", $meta.homepageUrl)
  }

  if (-not $meta.hasIssuesEnabled) {
    $createArgs += "--disable-issues"
  }

  if (-not $meta.hasWikiEnabled) {
    $createArgs += "--disable-wiki"
  }

  $created = $false
  for ($attempt = 1; $attempt -le 6; $attempt++) {
    try {
      & $gh @createArgs
      if ($LASTEXITCODE -eq 0) {
        $created = $true
        break
      }
    } catch {
    }

    Write-Host "Create retry $attempt for $repo..." -ForegroundColor Yellow
  }

  if (-not $created) {
    throw "Failed to recreate $repo after delete"
  }

  Write-Host "Reset complete (empty repo): $repo" -ForegroundColor Green
}

Write-Host "\nAll repositories were hard reset and recreated as empty remotes." -ForegroundColor Yellow
Write-Host "Next: manually clone each repo, commit, and push from your local project folders." -ForegroundColor Yellow
