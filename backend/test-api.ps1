param(
  [string]$BaseUrl = "http://127.0.0.1:8000"
)

function Write-Section($title) {
  Write-Host "`n=== $title ===" -ForegroundColor Cyan
}

function Invoke-And-Print($url) {
  try {
    $r = Invoke-WebRequest $url -ErrorAction Stop
    Write-Host ("STATUS: {0}" -f $r.StatusCode)
    if ($r.Headers['Link']) { Write-Host ("LINK: {0}" -f $r.Headers['Link']) }
    $j = $r.Content | ConvertFrom-Json
    if ($j -is [array]) { $j = $j[0] }
    if ($j.count -ne $null) { Write-Host ("COUNT: {0}" -f $j.count) }
    if ($j.total -ne $null) { Write-Host ("TOTAL: {0}" -f $j.total) }
    return $r
  } catch {
    $status = $_.Exception.Response.StatusCode.value__
    $body = $_.ErrorDetails.Message
    Write-Warning ("HTTP Error {0} -> {1}" -f $status, $body)
    return $null
  }
}

Write-Section "Players page 1 (limit=3, offset=0, order_by=team_abbreviation,jersey_number asc,desc)"
$u1 = "$BaseUrl/api/players?limit=3&offset=0&order_by=team_abbreviation,jersey_number&order_dir=asc,desc"
$r1 = Invoke-And-Print $u1

Write-Section "Players page 2 (limit=3, offset=3, same ordering)"
$u2 = "$BaseUrl/api/players?limit=3&offset=3&order_by=team_abbreviation,jersey_number&order_dir=asc,desc"
$r2 = Invoke-And-Print $u2

Write-Section "Validation 400: not enough directions (order_by has 2 cols, order_dir has 1)"
try {
  Invoke-WebRequest "$BaseUrl/api/players?order_by=name,jersey_number&order_dir=asc" -ErrorAction Stop | Out-Null
  Write-Warning "Expected 400 but got 2xx"
} catch {
  Write-Host ("STATUS: {0}" -f $_.Exception.Response.StatusCode.value__)
  Write-Host ("BODY: {0}" -f $_.ErrorDetails.Message)
}

Write-Section "Validation 400: unsupported order column"
try {
  Invoke-WebRequest "$BaseUrl/api/players?order_by=foo&order_dir=asc" -ErrorAction Stop | Out-Null
  Write-Warning "Expected 400 but got 2xx"
} catch {
  Write-Host ("STATUS: {0}" -f $_.Exception.Response.StatusCode.value__)
  Write-Host ("BODY: {0}" -f $_.ErrorDetails.Message)
}

Write-Section "Teams rosters paged (team_limit=5, team_offset=0, order_by=abbreviation,full_name asc,desc)"
$utr = "$BaseUrl/api/teams/rosters/paged?team_limit=5&team_offset=0&order_by=abbreviation,full_name&order_dir=asc,desc"
try {
  $tr = Invoke-WebRequest $utr -ErrorAction Stop
  Write-Host ("STATUS: {0}" -f $tr.StatusCode)
  if ($tr.Headers['Link']) { Write-Host ("LINK: {0}" -f $tr.Headers['Link']) }
  $tj = $tr.Content | ConvertFrom-Json
  Write-Host ("TEAMS_COUNT: {0}" -f $tj.teams_count)
  Write-Host ("TEAMS_TOTAL: {0}" -f $tj.teams_total)
} catch {
  Write-Warning ("HTTP Error {0} -> {1}" -f $_.Exception.Response.StatusCode.value__, $_.ErrorDetails.Message)
}

Write-Section "Players paged limit cap (limit=2000 -> expect 500)"
try {
  $pr = Invoke-WebRequest "$BaseUrl/api/players/paged?limit=2000&offset=0" -ErrorAction Stop
  $pj = $pr.Content | ConvertFrom-Json
  Write-Host ("LIMIT: {0}" -f $pj.limit)
} catch {
  Write-Warning ("HTTP Error {0} -> {1}" -f $_.Exception.Response.StatusCode.value__, $_.ErrorDetails.Message)
}

Write-Section "Export CSV (Bulls)"
try {
  $csvPath = Join-Path (Get-Location) "players_chi.csv"
  Invoke-RestMethod "$BaseUrl/api/players/export?format=csv&team=CHI" -OutFile $csvPath -ErrorAction Stop
  Write-Host ("CSV saved: {0}" -f $csvPath)
} catch {
  Write-Warning ("Export CSV error {0} -> {1}" -f $_.Exception.Response.StatusCode.value__, $_.ErrorDetails.Message)
}

Write-Section "Export XLSX (Guards sorted by name)"
try {
  $xlsxPath = Join-Path (Get-Location) "guards.xlsx"
  Invoke-RestMethod "$BaseUrl/api/players/export?format=xlsx&position=G&order_by=name" -OutFile $xlsxPath -ErrorAction Stop
  Write-Host ("XLSX saved: {0}" -f $xlsxPath)
} catch {
  Write-Warning ("Export XLSX error {0} -> {1}" -f $_.Exception.Response.StatusCode.value__, $_.ErrorDetails.Message)
}

Write-Host "`nAll tests executed." -ForegroundColor Green
