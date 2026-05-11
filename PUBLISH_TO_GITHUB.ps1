# ============================================================
#  IB World Religions -- Publish to GitHub Pages
#  Run with: .\PUBLISH_TO_GITHUB.ps1
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  IB World Religions -- GitHub Publisher" -ForegroundColor Yellow
Write-Host "  ======================================" -ForegroundColor DarkYellow
Write-Host ""

# -- STEP 1: Collect credentials -----------------------------

Write-Host "  You need a GitHub Personal Access Token." -ForegroundColor Cyan
Write-Host "  Create one at: https://github.com/settings/tokens/new" -ForegroundColor White
Write-Host ""
Write-Host "  Settings when creating the token:" -ForegroundColor Cyan
Write-Host "    - Token name: ib-world-religions" -ForegroundColor Gray
Write-Host "    - Expiration: 90 days" -ForegroundColor Gray
Write-Host "    - Scopes: tick [repo]" -ForegroundColor Gray
Write-Host ""

$username   = Read-Host "  Enter your GitHub username"
$tokenSecure = Read-Host "  Paste your Personal Access Token" -AsSecureString
$tokenPlain  = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenSecure))
$repoName   = "ib-world-religions"

Write-Host ""
Write-Host "  -> Creating GitHub repository '$repoName'..." -ForegroundColor Green

# -- STEP 2: Create the GitHub repo via API ------------------

$headers = @{
  Authorization = "token $tokenPlain"
  Accept        = "application/vnd.github+json"
}

$bodyObj = @{
  name        = $repoName
  description = "IB World Religions interactive study guides - Paper 1 and Paper 2"
  private     = $false
  auto_init   = $false
}
$body = $bodyObj | ConvertTo-Json

try {
  $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
    -Method Post -Headers $headers -Body $body -ContentType "application/json"
  Write-Host "  OK Repository created: $($response.html_url)" -ForegroundColor Green
} catch {
  $raw = $_.ErrorDetails.Message
  if ($raw -like "*already exists*") {
    Write-Host "  OK Repository already exists -- continuing." -ForegroundColor Yellow
  } else {
    Write-Host "  ERROR: $raw" -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
  }
}

# -- STEP 3: Init git and push -------------------------------

$folder = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $folder

Write-Host "  -> Setting up git in: $folder" -ForegroundColor Green

git config --global user.email "teamobsidianai2026@gmail.com"
git config --global user.name  "Group Leader"
git config --global init.defaultBranch main

if (Test-Path ".git") { Remove-Item -Recurse -Force ".git" }

git init
git add .
git commit -m "Initial commit: IB World Religions study suite"

$remote = "https://${username}:${tokenPlain}@github.com/${username}/${repoName}.git"
git remote add origin $remote
git push -u origin main

Write-Host "  OK Code pushed to GitHub!" -ForegroundColor Green

# -- STEP 4: Enable GitHub Pages -----------------------------

Write-Host "  -> Enabling GitHub Pages..." -ForegroundColor Green
Start-Sleep -Seconds 4

$pagesBodyObj = @{ source = @{ branch = "main"; path = "/" } }
$pagesBody = $pagesBodyObj | ConvertTo-Json

try {
  Invoke-RestMethod -Uri "https://api.github.com/repos/$username/$repoName/pages" `
    -Method Post -Headers $headers -Body $pagesBody -ContentType "application/json" | Out-Null
  Write-Host "  OK GitHub Pages enabled!" -ForegroundColor Green
} catch {
  Write-Host "  NOTE: Enable Pages manually at:" -ForegroundColor Yellow
  Write-Host "  https://github.com/$username/$repoName/settings/pages" -ForegroundColor White
  Write-Host "  Source -> Deploy from branch -> main -> / (root) -> Save" -ForegroundColor Gray
}

# -- DONE ----------------------------------------------------

Write-Host ""
Write-Host "  ============================================" -ForegroundColor DarkYellow
Write-Host "  ALL DONE! Site will be live in about 60 sec" -ForegroundColor Yellow
Write-Host "  ============================================" -ForegroundColor DarkYellow
Write-Host ""
Write-Host "  Repo: https://github.com/$username/$repoName" -ForegroundColor Cyan
Write-Host "  Live: https://$username.github.io/$repoName" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Bookmark that second link -- that is your study site!" -ForegroundColor White
Write-Host ""
Read-Host "  Press Enter to close"
