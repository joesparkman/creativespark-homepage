param(
  [Parameter(Mandatory = $true)]
  [string]$BucketName,

  [string]$Region = "us-east-2",

  [int]$PlaceholderCount = 8,

  [string]$Prefix = "placeholders",

  [switch]$PublicRead
)

$ErrorActionPreference = "Stop"
if ($null -ne (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue)) {
  $PSNativeCommandUseErrorActionPreference = $false
}

function Invoke-Aws {
  param([string[]]$AwsArgs)
  & aws @AwsArgs
  if ($LASTEXITCODE -ne 0) {
    throw "AWS CLI command failed: aws $($AwsArgs -join ' ')"
  }
}

function Test-BucketExists {
  param([string]$Name, [string]$BucketRegion)
  & aws s3api head-bucket --bucket $Name --region $BucketRegion 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function New-SvgPlaceholder {
  param(
    [int]$Index,
    [string]$FilePath
  )

  $palettes = @(
    @{A="#0b1738"; B="#060b1b"; C="#60a5fa"},
    @{A="#172554"; B="#111827"; C="#22d3ee"},
    @{A="#0f172a"; B="#1e293b"; C="#34d399"},
    @{A="#1f2937"; B="#0f172a"; C="#f59e0b"},
    @{A="#111827"; B="#0b1020"; C="#a78bfa"}
  )

  $p = $palettes[($Index - 1) % $palettes.Count]
  $label = "Placeholder {0:d2}" -f $Index

  $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 630" role="img" aria-label="$label">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="$($p.A)"/>
      <stop offset="100%" stop-color="$($p.B)"/>
    </linearGradient>
    <linearGradient id="line" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="transparent"/>
      <stop offset="50%" stop-color="rgba(255,255,255,0.38)"/>
      <stop offset="100%" stop-color="transparent"/>
    </linearGradient>
  </defs>

  <rect width="1200" height="630" fill="url(#bg)"/>

  <g opacity="0.22">
    <rect x="84" y="80" width="1032" height="470" rx="22" fill="none" stroke="$($p.C)" stroke-width="2"/>
    <rect x="120" y="118" width="960" height="60" rx="12" fill="rgba(255,255,255,0.06)"/>
    <rect x="120" y="206" width="600" height="24" rx="8" fill="rgba(255,255,255,0.1)"/>
    <rect x="120" y="248" width="760" height="24" rx="8" fill="rgba(255,255,255,0.08)"/>
    <rect x="120" y="290" width="680" height="24" rx="8" fill="rgba(255,255,255,0.08)"/>
    <rect x="120" y="384" width="250" height="56" rx="12" fill="rgba(255,255,255,0.08)"/>
  </g>

  <rect x="0" y="314" width="1200" height="2" fill="url(#line)"/>

  <text x="84" y="583" fill="$($p.C)" font-family="Segoe UI, Arial, sans-serif" font-size="38" font-weight="700" letter-spacing="1.6">$label</text>
</svg>
"@

  [System.IO.File]::WriteAllText($FilePath, $svg, (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host "Validating AWS credentials..."
Invoke-Aws -AwsArgs @("sts", "get-caller-identity") | Out-Null

$exists = Test-BucketExists -Name $BucketName -BucketRegion $Region
if (-not $exists) {
  Write-Host "Creating bucket: $BucketName in $Region"
  if ($Region -eq "us-east-1") {
    Invoke-Aws -AwsArgs @("s3api", "create-bucket", "--bucket", $BucketName, "--region", $Region) | Out-Null
  } else {
    Invoke-Aws -AwsArgs @("s3api", "create-bucket", "--bucket", $BucketName, "--region", $Region, "--create-bucket-configuration", "LocationConstraint=$Region") | Out-Null
  }
} else {
  Write-Host "Bucket already exists and is accessible: $BucketName"
}

if ($PublicRead) {
  Write-Host "Configuring public read access for prefix '$Prefix/'"
  Invoke-Aws -AwsArgs @("s3api", "put-public-access-block", "--bucket", $BucketName, "--public-access-block-configuration", "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false") | Out-Null

  $policy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicReadPlaceholders",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::$BucketName/$Prefix/*"]
    }
  ]
}
"@

  $policyPath = Join-Path $env:TEMP ("bucket-policy-" + [guid]::NewGuid().ToString() + ".json")
  [System.IO.File]::WriteAllText($policyPath, $policy, (New-Object System.Text.UTF8Encoding($false)))
  Invoke-Aws -AwsArgs @("s3api", "put-bucket-policy", "--bucket", $BucketName, "--policy", (Get-Content $policyPath -Raw)) | Out-Null
  Remove-Item $policyPath -ErrorAction SilentlyContinue
}

$tempDir = Join-Path $env:TEMP ("placeholders-" + [guid]::NewGuid().ToString())
New-Item -Path $tempDir -ItemType Directory | Out-Null

try {
  $urls = @()
  for ($i = 1; $i -le $PlaceholderCount; $i++) {
    $fileName = "placeholder-{0:d2}.svg" -f $i
    $localPath = Join-Path $tempDir $fileName
    $objectKey = "$Prefix/$fileName"

    New-SvgPlaceholder -Index $i -FilePath $localPath

    $cpArgs = @("s3", "cp", $localPath, "s3://$BucketName/$objectKey", "--region", $Region, "--content-type", "image/svg+xml")
    if ($PublicRead) {
      $cpArgs += @("--acl", "public-read")
    }

    Invoke-Aws -AwsArgs $cpArgs | Out-Null

    $url = "https://$BucketName.s3.$Region.amazonaws.com/$objectKey"
    $urls += $url
    Write-Host "Uploaded: $objectKey"
  }

  Write-Host ""
  Write-Host "Done. Placeholder image URLs:"
  $urls | ForEach-Object { Write-Host $_ }
}
finally {
  Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
