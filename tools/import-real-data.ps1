# import-real-data.ps1
# Transforms the JacTec-handoff CSVs into a real data.js for Rental Wrangler.
# - Maps every CSV row to the exact object shape app.js / cascade.js expect.
# - Splits customer "name" into firstName / lastName / company.
# - Infers industry from company/email/name keywords (conservative; blank when unsure).
# - Title-cases ALL-CAPS names so marketing first-names read nicely.
# ASCII-only on purpose (PowerShell 5.1 mangles non-ASCII source). Output JSON
# auto-escapes any non-ASCII to \uXXXX, so the generated file stays ASCII-clean.

$ErrorActionPreference = 'Stop'
$dataDir = Join-Path $PSScriptRoot '..\JacTec-handoff\data'
$outFile = Join-Path $PSScriptRoot '..\data.generated.js'

# ---------- helpers ----------
$ti = (Get-Culture).TextInfo
function SmartCase([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  $s = $s.Trim()
  if ($s -cne $s.ToUpper()) { return $s }   # already has lowercase -> leave brand/casing alone
  return $ti.ToTitleCase($s.ToLower())       # all-caps -> Title Case
}
# For person names: title-case every word that is all-lower or all-upper, but
# PRESERVE words with intentional internal capitals (McDaniel, DeShawn, O'Brien).
function SmartCaseName([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  $words = $s.Trim() -split '\s+'
  $out = foreach ($w in $words) {
    if ($w -eq '') { continue }
    if ($w -ceq $w.ToUpper() -or $w -ceq $w.ToLower()) { $ti.ToTitleCase($w.ToLower()) }
    else { $w }   # has internal capital -> keep as styled
  }
  return ($out -join ' ')
}
function NumOr0($v) {
  if ($null -eq $v) { return 0 }
  $t = ([string]$v).Trim()
  if ($t -eq '') { return 0 }
  $d = 0.0
  if ([double]::TryParse($t, [ref]$d)) { return $d }
  return 0
}
function NumOrNull($v) {
  if ($null -eq $v) { return $null }
  $t = ([string]$v).Trim()
  if ($t -eq '') { return $null }
  $d = 0.0
  if ([double]::TryParse($t, [ref]$d)) { return $d }
  return $null
}
function Clean([string]$s) { if ($null -eq $s) { return '' } return $s.Trim() }
function YesBool($v) { return ((Clean $v) -ieq 'Yes') }

$companyKw = 'services|service|\bllc\b|l\.l\.c|\binc\b|incorporated|\bcorp\b|company|\bco\b|group|management|construction|concrete|equipment|enterprises|solutions|contractor|contractors|builders|welding|electric|electrical|plumbing|roofing|industrial|industries|fabrication|trucking|transport|hauling|logistics|properties|property|realty|investments|\brentals\b|farms|ranch|systems|resources|consulting|maintenance|mechanical|utilities|energy|oilfield|pipeline|painting|landscaping'
function LooksLikeCompany([string]$s) {
  if ($s -match $companyKw) { return $true }
  if (($s -split '\s+' | Where-Object { $_ -ne '' }).Count -ge 3) { return $true }
  return $false
}
function LooksLikePerson([string]$s) {
  $wc = ($s -split '\s+' | Where-Object { $_ -ne '' }).Count
  return ($wc -ge 1 -and $wc -le 3 -and ($s -notmatch $companyKw))
}

function InferIndustry([string]$company, [string]$email, [string]$name) {
  $dom = ''
  if ($email -match '@(.+)$') {
    $dom = $matches[1].ToLower()
    if ($dom -match 'gmail|yahoo|hotmail|icloud|outlook|aol|comcast|att\.net|live\.com|msn') { $dom = '' }
  }
  $hay = (("$company $name $dom").ToLower())
  if ($hay -match 'concrete') { return 'Concrete' }
  if ($hay -match 'pipeline|oilfield|petroleum|drilling|\boil\b') { return 'Oil & Gas' }
  if ($hay -match 'weld') { return 'Welding' }
  if ($hay -match 'electric') { return 'Electrical' }
  if ($hay -match 'plumb') { return 'Plumbing' }
  if ($hay -match 'roof') { return 'Roofing' }
  if ($hay -match 'paint|coating') { return 'Painting' }
  if ($hay -match 'landscap|\blawn\b|tree service|grading|dirt work') { return 'Landscaping' }
  if ($hay -match 'trucking|hauling|logistics|\btransport') { return 'Trucking' }
  if ($hay -match 'thermal|fabricat|machine shop|\bsteel\b|manufactur|industrial') { return 'Industrial' }
  if ($hay -match 'construction|builders|contracting|contractor|\bhomes\b|remodel|framing|foundation') { return 'Construction' }
  if ($hay -match 'property|properties|realty|real estate|investments') { return 'Real Estate' }
  if ($hay -match '\bgames\b|events|entertainment|production') { return 'Entertainment' }
  if ($hay -match '\bfarm|\branch\b|cattle|\bag\b') { return 'Agriculture' }
  return ''
}

# Parse "name" + company column -> firstName / lastName / company
function ParseName([string]$rawName, [string]$companyCol) {
  $raw = Clean $rawName
  $company = Clean $companyCol
  $base = $raw
  $paren = ''
  $m = [regex]::Match($raw, '^(.*?)\s*\(([^)]*)\)\s*$')
  if ($m.Success) {
    $base = $m.Groups[1].Value.Trim()
    $paren = $m.Groups[2].Value.Trim()
  }
  if ($paren -ne '') {
    if ($company -eq '') {
      if ((LooksLikeCompany $base) -and (LooksLikePerson $paren)) {
        $company = $base; $base = $paren           # "ACME CONSTRUCTION (John Doe)" -> company ACME, person John Doe
      } else {
        $company = $paren                          # "John Doe (Acme LLC)" -> company Acme LLC
      }
    } else {
      if ((LooksLikePerson $paren) -and ((LooksLikeCompany $base) -or ($base -ieq $company))) {
        $base = $paren                             # company already known; paren is the contact person
      }
    }
  }
  $base = ($base -replace '\s+', ' ').Trim().Trim(',').Trim()
  $first = ''; $last = ''
  if ($base -ne '') {
    $parts = $base -split '\s+'
    $first = $parts[0]
    if ($parts.Count -gt 1) { $last = ($parts[1..($parts.Count - 1)] -join ' ') }
  }
  return [pscustomobject]@{
    firstName = SmartCaseName $first
    lastName  = SmartCaseName $last
    company   = SmartCase $company
  }
}

# ---------- categories ----------
$categories = @()
Import-Csv (Join-Path $dataDir 'categories.csv') | ForEach-Object {
  $categories += [ordered]@{
    categoryId = Clean $_.categoryId; name = Clean $_.name
    memberDaily = NumOr0 $_.memberDaily; rate1Day = NumOr0 $_.rate1Day; rate7Day = NumOr0 $_.rate7Day
    rate4Wk = NumOr0 $_.rate4Wk; weekend = NumOr0 $_.weekend; msrp = NumOr0 $_.msrp
    askPrice = NumOr0 $_.askPrice; bottomDollar = NumOr0 $_.bottomDollar
    fuelType = Clean $_.fuelType; description = Clean $_.description; specs = Clean $_.specs
  }
}

# ---------- units ----------
# Serviced-today baseline: mark every recurring service complete at the unit's
# current hours so the Shop starts fresh (no real service-completion history in
# the export). Real service needs accrue from current hours forward. The 10 task
# IDs mirror SERVICE_TASKS in service-countdown.js.
$svcTaskIds = @('svc-safety','svc-grease','svc-oil','svc-belt','svc-air','svc-tire','svc-battery','svc-fuel','svc-annual','svc-hydraulic')
$units = @()
Import-Csv (Join-Path $dataDir 'units.csv') | ForEach-Object {
  $ch = NumOr0 $_.currentHours
  $svc = [ordered]@{}
  foreach ($t in $svcTaskIds) { $svc[$t] = $ch }
  $units += [ordered]@{
    unitId = Clean $_.unitId; name = Clean $_.name; categoryId = Clean $_.categoryId
    assignedMechanic = Clean $_.assignedMechanic; currentHours = $ch
    inspectionStatus = Clean $_.inspectionStatus; fleetStatus = Clean $_.fleetStatus
    purchaseHours = $ch; serviceCompletions = $svc
  }
}

# ---------- customers ----------
$customers = @()
$inferredCount = 0
Import-Csv (Join-Path $dataDir 'customers.csv') | ForEach-Object {
  $pn = ParseName $_.name $_.company
  $email = Clean $_.email
  $industryCsv = Clean $_.industry
  $industry = $industryCsv
  if ($industry -eq '' -or $industry -in @('Business','Non-Business','New Customer')) { $industry = '' }
  if ($industry -eq '') { $industry = InferIndustry $pn.company $email $_.name }
  if ($industry -ne '') { $inferredCount++ }
  $acct = Clean $_.accountType; if ($acct -eq '') { $acct = 'Non-Business' }
  $pay = Clean $_.payStatus;    if ($pay -eq '')  { $pay = 'New Customer' }
  $customers += [ordered]@{
    customerId = Clean $_.customerId
    firstName = $pn.firstName; lastName = $pn.lastName
    name = (("$($pn.firstName) $($pn.lastName)").Trim())
    company = $pn.company
    phone = Clean $_.phone; email = $email; address = ''
    accountType = $acct; payStatus = $pay; industry = $industry
    requiresPO = (YesBool $_.requiresPO); accountNotes = Clean $_.accountNotes
    stripeId = ''
    _digest = [ordered]@{ totalPaid = 0; visits = 0; years = 0; avgFrequencyDays = 0; activePct = 0; firstInvoice = ''; lastInvoice = '' }
  }
}

# ---------- rentals ----------
# Drop empty-shell "Quote" rows: these are CRM contact notes mis-filed as rentals
# (no unit, category, dates, delivery, or PO). Keeps only rows with real rental data.
$rentals = @()
$droppedRentals = 0
Import-Csv (Join-Path $dataDir 'rentals.csv') | ForEach-Object {
  $unitId = Clean $_.unitId; if ($unitId -eq '') { $unitId = $null }
  $catId  = Clean $_.categoryId; if ($catId -eq '') { $catId = $null }
  $isJunk = ((Clean $_.status) -ieq 'Quote') -and ($null -eq $unitId) -and ($null -eq $catId) -and `
            ((Clean $_.startDate) -eq '') -and ((Clean $_.endDate) -eq '') -and `
            ((Clean $_.deliveryAddress) -eq '') -and ((Clean $_.po) -eq '')
  if ($isJunk) { $droppedRentals++; return }
  $rentals += [ordered]@{
    rentalId = Clean $_.rentalId; customerId = Clean $_.customerId
    unitId = $unitId; legacyUnitName = Clean $_.legacyUnitName; categoryId = $catId
    rentalName = Clean $_.rentalName; startDate = Clean $_.startDate; endDate = Clean $_.endDate
    startTime = Clean $_.startTime; status = Clean $_.status; transportType = Clean $_.transportType
    deliveryAddress = Clean $_.deliveryAddress; po = Clean $_.po
    invoiceId = $null; startHours = $null; returnHours = $null
    refunded = (YesBool $_.refunded); notes = ''
  }
}

# ---------- work orders ----------
$workOrders = @()
Import-Csv (Join-Path $dataDir 'work_orders.csv') | ForEach-Object {
  $workOrders += [ordered]@{
    woId = Clean $_.woId; unitId = Clean $_.unitId; customerId = $null
    woReport = Clean $_.woReport; woType = Clean $_.woType; description = Clean $_.description
    estCost = NumOr0 $_.estCost; phase = Clean $_.phase; billCustomer = (Clean $_.billCustomer)
    date = Clean $_.date; eta = Clean $_.eta; unitHoursAtCreation = NumOrNull $_.unitHoursAtCreation
    assignedMechanic = Clean $_.assignedMechanic; laborHours = NumOr0 $_.laborHours
    lineItems = '__EMPTY_ARR__'
  }
}

# ---------- vendors ----------
$vendors = @()
Import-Csv (Join-Path $dataDir 'vendors.csv') | ForEach-Object {
  $vendors += [ordered]@{
    vendorId = Clean $_.vendorId; name = Clean $_.name; phone = Clean $_.phone; email = Clean $_.email
    address = Clean $_.address; website = Clean $_.website; primaryContact = Clean $_.primaryContact
    salesTaxExempt = (YesBool $_.salesTaxExempt); vendorType = Clean $_.vendorType
  }
}

# ---------- parts ----------
$parts = @()
Import-Csv (Join-Path $dataDir 'parts.csv') | ForEach-Object {
  $st = Clean $_.status; if ($st -eq '') { $st = 'Catalog' }
  $parts += [ordered]@{
    partId = Clean $_.partId; name = Clean $_.name; status = $st
    priceEach = NumOr0 $_.priceEach; qtyOnHand = NumOr0 $_.qtyOnHand
    website = Clean $_.website; orderEmail = Clean $_.orderEmail; productNumber = Clean $_.productNumber
    vendorId = ''; imageUrl = Clean $_.imageUrl; notes = Clean $_.notes
  }
}

# ---------- company files ----------
$companyFiles = @()
Import-Csv (Join-Path $dataDir 'company_files.csv') | ForEach-Object {
  $companyFiles += [ordered]@{
    fileId = Clean $_.fileId; name = Clean $_.name; group = Clean $_.group
    type = Clean $_.type; reviewByDate = Clean $_.reviewByDate; link = Clean $_.link
  }
}

# ---------- emit ----------
function ToJson($arr) {
  if ($null -eq $arr -or @($arr).Count -eq 0) { return '[]' }
  return (@($arr) | ConvertTo-Json -Depth 12)
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('/**')
[void]$sb.AppendLine(' * data.js - Rental Wrangler REAL data (generated by tools/import-real-data.ps1).')
[void]$sb.AppendLine(' * Source: JacTec-handoff CSV export. Do not hand-edit; re-run the script instead.')
[void]$sb.AppendLine(' * Invoices / inspections / expenses start empty (created in-app). _digest seeded to zero.')
[void]$sb.AppendLine(' */')
[void]$sb.AppendLine('export const DATA = {')
[void]$sb.AppendLine('  categories: ' + (ToJson $categories) + ',')
[void]$sb.AppendLine('  units: ' + (ToJson $units) + ',')
[void]$sb.AppendLine('  customers: ' + (ToJson $customers) + ',')
[void]$sb.AppendLine('  invoices: [],')
[void]$sb.AppendLine('  rentals: ' + (ToJson $rentals) + ',')
[void]$sb.AppendLine('  workOrders: ' + (ToJson $workOrders) + ',')
[void]$sb.AppendLine('  inspections: [],')
[void]$sb.AppendLine('  vendors: ' + (ToJson $vendors) + ',')
[void]$sb.AppendLine('  parts: ' + (ToJson $parts) + ',')
[void]$sb.AppendLine('  companyFiles: ' + (ToJson $companyFiles) + ',')
[void]$sb.AppendLine('  expenses: [],')
[void]$sb.AppendLine('};')
[void]$sb.AppendLine('export default DATA;')

$text = $sb.ToString()
$text = $text -replace '"__EMPTY_ARR__"', '[]'
$text = $text -replace '"__EMPTY_OBJ__"', '{}'

$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outFile, $text, $enc)

Write-Host ("categories : " + $categories.Count)
Write-Host ("units      : " + $units.Count)
Write-Host ("customers  : " + $customers.Count + " (industry inferred for " + $inferredCount + ")")
Write-Host ("rentals    : " + $rentals.Count + " (dropped " + $droppedRentals + " junk Quote shells)")
Write-Host ("workOrders : " + $workOrders.Count)
Write-Host ("vendors    : " + $vendors.Count)
Write-Host ("parts      : " + $parts.Count)
Write-Host ("companyFiles: " + $companyFiles.Count)
Write-Host ("wrote: " + $outFile)
