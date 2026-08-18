<#
.SYNOPSIS
    Creates the Northwind retail schema and demo data in a Dataverse environment.

.DESCRIPTION
    Provisions the eleven tables the skills reference, plus demo data chosen so that
    every skill lands on a real decision rather than a healthy board.

    Idempotent - existing tables and rows are detected and left alone, so it is safe
    to re-run.

.PARAMETER OrgUrl
    Target environment, e.g. https://orgXXXXXXXX.crm.dynamics.com

.PARAMETER Prefix
    Publisher prefix without the underscore. Must match the skills.

.PARAMETER SchemaOnly
    Create tables without seeding data.

.PARAMETER DataOnly
    Seed data into tables that already exist.

.EXAMPLE
    .\Deploy-RetailSchema.ps1 -OrgUrl https://orgXXXXXXXX.crm.dynamics.com

.NOTES
    Requires Azure CLI (az login) with rights to the environment.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $OrgUrl,

    [ValidatePattern('^[a-z][a-z0-9]{1,7}$')]
    [string] $Prefix = 'nwr',

    [switch] $SchemaOnly,
    [switch] $DataOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$OrgUrl = $OrgUrl.TrimEnd('/')
$api = "$OrgUrl/api/data/v9.2"

Write-Host ''
Write-Host "Target: $OrgUrl" -ForegroundColor Cyan
Write-Host "Prefix: ${Prefix}_" -ForegroundColor Cyan
Write-Host ''

# --- Auth -------------------------------------------------------------------

$token = & az account get-access-token --resource $OrgUrl --query accessToken -o tsv 2>$null
if (-not $token) { throw "Could not get a token for $OrgUrl. Run 'az login' first." }

$headers = @{
    Authorization          = "Bearer $token"
    'OData-MaxVersion'     = '4.0'
    'OData-Version'        = '4.0'
    Accept                 = 'application/json'
    'Content-Type'         = 'application/json; charset=utf-8'
    'MSCRM.SuppressDuplicateDetection' = 'false'
}

function Invoke-Dv {
    param(
        [Parameter(Mandatory)][string] $Method,
        [Parameter(Mandatory)][string] $Path,
        $Body,
        [hashtable] $ExtraHeaders
    )

    $h = $headers.Clone()
    if ($ExtraHeaders) { foreach ($k in $ExtraHeaders.Keys) { $h[$k] = $ExtraHeaders[$k] } }

    $uri = if ($Path -match '^https?://') { $Path } else { "$api/$Path" }
    $json = if ($null -ne $Body) { $Body | ConvertTo-Json -Depth 30 -Compress } else { $null }

    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $h -Body $json
}

function Test-TableExists {
    param([string] $LogicalName)
    try {
        Invoke-Dv -Method Get -Path "EntityDefinitions(LogicalName='$LogicalName')?`$select=LogicalName" | Out-Null
        return $true
    }
    catch { return $false }
}

# --- Schema definition ------------------------------------------------------
# Kept declarative so the shape is readable and the script stays short.

$tables = @(
    @{ Name = 'store';         Display = 'Store';          Plural = 'Stores';          Primary = 'Name' },
    @{ Name = 'product';       Display = 'Product';        Plural = 'Products';        Primary = 'Name' },
    @{ Name = 'supplier';      Display = 'Supplier';       Plural = 'Suppliers';       Primary = 'Name' },
    @{ Name = 'inventory';     Display = 'Inventory';      Plural = 'Inventory';       Primary = 'Name' },
    @{ Name = 'purchaseorder'; Display = 'Purchase Order'; Plural = 'Purchase Orders'; Primary = 'Name' },
    @{ Name = 'employee';      Display = 'Employee';       Plural = 'Employees';       Primary = 'Name' },
    @{ Name = 'leaverequest';  Display = 'Leave Request';  Plural = 'Leave Requests';  Primary = 'Name' },
    @{ Name = 'itticket';      Display = 'IT Ticket';      Plural = 'IT Tickets';      Primary = 'Name' },
    @{ Name = 'ordertxn';      Display = 'Order';          Plural = 'Orders';          Primary = 'Name' },
    @{ Name = 'customer';      Display = 'Customer';       Plural = 'Customers';       Primary = 'Name' },
    @{ Name = 'warrantyclaim'; Display = 'Warranty Claim'; Plural = 'Warranty Claims'; Primary = 'Name' }
)

# Columns per table. Choice fields carry their option labels so the agent can render
# labels rather than raw values.
$columns = @{
    store = @(
        @{ n = 'suburb';   t = 'String';  d = 'Suburb' },
        @{ n = 'isactive'; t = 'Boolean'; d = 'Is Active' }
    )
    product = @(
        @{ n = 'sku';      t = 'String'; d = 'SKU' },
        @{ n = 'category'; t = 'String'; d = 'Category' },
        @{ n = 'price';    t = 'Money';  d = 'Price' }
    )
    supplier = @(
        @{ n = 'rating';         t = 'Decimal'; d = 'Rating' },
        @{ n = 'contractexpiry'; t = 'DateOnly'; d = 'Contract Expiry' },
        @{ n = 'status';         t = 'Picklist'; d = 'Status';
           o = @('Active', 'Under Review', 'Suspended') }
    )
    inventory = @(
        @{ n = 'quantityonhand';   t = 'Integer'; d = 'Quantity On Hand' },
        @{ n = 'quantityreserved'; t = 'Integer'; d = 'Quantity Reserved' },
        @{ n = 'reorderlevel';     t = 'Integer'; d = 'Reorder Level' },
        @{ n = 'nextdeliverydate'; t = 'DateOnly'; d = 'Next Delivery Date' },
        @{ n = 'stockstatus';      t = 'Picklist'; d = 'Stock Status';
           o = @('In Stock', 'Low Stock', 'Out of Stock') }
    )
    purchaseorder = @(
        @{ n = 'quantity';       t = 'Integer'; d = 'Quantity' },
        @{ n = 'expectedarrival'; t = 'DateOnly'; d = 'Expected Arrival' },
        @{ n = 'postatus';       t = 'Picklist'; d = 'PO Status';
           o = @('Ordered', 'In Production', 'Shipped', 'Partially Received', 'Delayed', 'Received') }
    )
    employee = @(
        @{ n = 'role';  t = 'String'; d = 'Role' },
        @{ n = 'email'; t = 'String'; d = 'Email' }
    )
    leaverequest = @(
        @{ n = 'startdate'; t = 'DateOnly'; d = 'Start Date' },
        @{ n = 'enddate';   t = 'DateOnly'; d = 'End Date' },
        @{ n = 'status';    t = 'Picklist'; d = 'Status';
           o = @('Requested', 'Approved', 'Declined') }
    )
    itticket = @(
        @{ n = 'subject';      t = 'String'; d = 'Subject' },
        @{ n = 'sladuedate';   t = 'DateTime'; d = 'SLA Due Date' },
        @{ n = 'assignedto';   t = 'String'; d = 'Assigned To' },
        @{ n = 'priority';     t = 'Picklist'; d = 'Priority';
           o = @('P1', 'P2', 'P3', 'P4') },
        @{ n = 'ticketstatus'; t = 'Picklist'; d = 'Ticket Status';
           o = @('New', 'Assigned', 'In Progress', 'Resolved', 'Closed') }
    )
    ordertxn = @(
        @{ n = 'ordernumber';   t = 'String'; d = 'Order Number' },
        @{ n = 'deliverynotes'; t = 'Memo';   d = 'Delivery Notes' },
        @{ n = 'status';        t = 'Picklist'; d = 'Status';
           o = @('Placed', 'In Transit', 'Delivered', 'Delayed') }
    )
    customer = @(
        @{ n = 'email'; t = 'String'; d = 'Email' }
    )
    warrantyclaim = @(
        @{ n = 'claimnumber'; t = 'String'; d = 'Claim Number' },
        @{ n = 'status';      t = 'Picklist'; d = 'Status';
           o = @('Lodged', 'Assessing', 'Approved', 'Declined') }
    )
}

function New-AttributeBody {
    param([hashtable] $Col, [string] $SchemaName, [string] $Display)

    $base = @{
        SchemaName    = $SchemaName
        DisplayName   = @{ LocalizedLabels = @(@{ Label = $Display; LanguageCode = 1033; '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel' }); '@odata.type' = 'Microsoft.Dynamics.CRM.Label' }
        RequiredLevel = @{ Value = 'None' }
    }

    switch ($Col.t) {
        'String'   { $base['@odata.type'] = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'; $base.MaxLength = 200; $base.FormatName = @{ Value = 'Text' } }
        'Memo'     { $base['@odata.type'] = 'Microsoft.Dynamics.CRM.MemoAttributeMetadata'; $base.MaxLength = 2000 }
        'Integer'  { $base['@odata.type'] = 'Microsoft.Dynamics.CRM.IntegerAttributeMetadata'; $base.MinValue = -100000; $base.MaxValue = 1000000 }
        'Decimal'  { $base['@odata.type'] = 'Microsoft.Dynamics.CRM.DecimalAttributeMetadata'; $base.MinValue = 0; $base.MaxValue = 100; $base.Precision = 1 }
        'Money'    { $base['@odata.type'] = 'Microsoft.Dynamics.CRM.MoneyAttributeMetadata'; $base.MinValue = 0; $base.MaxValue = 1000000; $base.Precision = 2; $base.PrecisionSource = 2 }
        'Boolean'  {
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.BooleanAttributeMetadata'
            $base.DefaultValue = $false
            $base.OptionSet = @{
                '@odata.type' = 'Microsoft.Dynamics.CRM.BooleanOptionSetMetadata'
                TrueOption    = @{ Value = 1; Label = @{ LocalizedLabels = @(@{ Label = 'Yes'; LanguageCode = 1033; '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel' }); '@odata.type' = 'Microsoft.Dynamics.CRM.Label' } }
                FalseOption   = @{ Value = 0; Label = @{ LocalizedLabels = @(@{ Label = 'No'; LanguageCode = 1033; '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel' }); '@odata.type' = 'Microsoft.Dynamics.CRM.Label' } }
            }
        }
        'DateOnly' { $base['@odata.type'] = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'; $base.Format = 'DateOnly'; $base.DateTimeBehavior = @{ Value = 'DateOnly' } }
        'DateTime' { $base['@odata.type'] = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'; $base.Format = 'DateAndTime'; $base.DateTimeBehavior = @{ Value = 'UserLocal' } }
        'Picklist' {
            $base['@odata.type'] = 'Microsoft.Dynamics.CRM.PicklistAttributeMetadata'
            $options = @()
            $value = 100000000
            foreach ($label in $Col.o) {
                $options += @{
                    Value = $value
                    Label = @{ LocalizedLabels = @(@{ Label = $label; LanguageCode = 1033; '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel' }); '@odata.type' = 'Microsoft.Dynamics.CRM.Label' }
                }
                $value++
            }
            $base.OptionSet = @{
                '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
                IsGlobal      = $false
                OptionSetType = 'Picklist'
                Options       = $options
            }
        }
    }

    return $base
}

# --- Create tables ----------------------------------------------------------

if (-not $DataOnly) {

    Write-Host 'Creating tables...' -ForegroundColor Cyan

    foreach ($t in $tables) {
        $logical = "${Prefix}_$($t.Name)"

        if (Test-TableExists -LogicalName $logical) {
            Write-Host "  $logical already exists" -ForegroundColor DarkGray
        }
        else {
            $body = @{
                '@odata.type'         = 'Microsoft.Dynamics.CRM.EntityMetadata'
                SchemaName            = "${Prefix}_$($t.Name)"
                DisplayName           = @{ LocalizedLabels = @(@{ Label = $t.Display; LanguageCode = 1033; '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel' }); '@odata.type' = 'Microsoft.Dynamics.CRM.Label' }
                DisplayCollectionName = @{ LocalizedLabels = @(@{ Label = $t.Plural; LanguageCode = 1033; '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel' }); '@odata.type' = 'Microsoft.Dynamics.CRM.Label' }
                OwnershipType         = 'UserOwned'
                HasActivities         = $false
                HasNotes              = $false
                IsActivity            = $false
                Attributes            = @(
                    @{
                        '@odata.type' = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
                        SchemaName    = "${Prefix}_name"
                        DisplayName   = @{ LocalizedLabels = @(@{ Label = $t.Primary; LanguageCode = 1033; '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel' }); '@odata.type' = 'Microsoft.Dynamics.CRM.Label' }
                        MaxLength     = 200
                        IsPrimaryName = $true
                        RequiredLevel = @{ Value = 'ApplicationRequired' }
                    }
                )
            }

            Invoke-Dv -Method Post -Path 'EntityDefinitions' -Body $body | Out-Null
            Write-Host "  created $logical" -ForegroundColor Green
        }

        # Columns.
        if ($columns.ContainsKey($t.Name)) {
            $existing = (Invoke-Dv -Method Get -Path "EntityDefinitions(LogicalName='$logical')/Attributes?`$select=LogicalName").value.LogicalName

            foreach ($col in $columns[$t.Name]) {
                $colLogical = "${Prefix}_$($col.n)"
                if ($existing -contains $colLogical) { continue }

                $attrBody = New-AttributeBody -Col $col -SchemaName $colLogical -Display $col.d
                try {
                    Invoke-Dv -Method Post -Path "EntityDefinitions(LogicalName='$logical')/Attributes" -Body $attrBody | Out-Null
                    Write-Host "    + $colLogical" -ForegroundColor DarkGreen
                }
                catch {
                    Write-Warning "    ! $colLogical - $($_.Exception.Message)"
                }
            }
        }
    }

    Write-Host ''
    Write-Host 'Publishing customisations...' -ForegroundColor Cyan
    Invoke-Dv -Method Post -Path 'PublishAllXml' -Body @{} | Out-Null
    Write-Host '  published' -ForegroundColor Green
}

if ($SchemaOnly) {
    Write-Host ''
    Write-Host 'Schema created. Re-run with -DataOnly to seed demo data.' -ForegroundColor Cyan
    Write-Host ''
    return
}

# --- Seed data --------------------------------------------------------------
# Chosen so each skill lands on a decision. Healthy data demonstrates nothing,
# because every skill correctly reports "nothing urgent".

Write-Host ''
Write-Host 'Seeding demo data...' -ForegroundColor Cyan

$today = Get-Date

function New-Row {
    param([string] $Set, [hashtable] $Fields, [string] $MatchOn = "${Prefix}_name")

    $name = $Fields[$MatchOn]
    $filter = "$MatchOn eq '$($name -replace "'","''")'"

    $found = (Invoke-Dv -Method Get -Path "$Set`?`$select=$MatchOn&`$filter=$filter").value
    if ($found -and $found.Count -gt 0) {
        return $found[0]."$($Set.TrimEnd('s'))id"
    }

    $resp = Invoke-Dv -Method Post -Path $Set -Body $Fields -ExtraHeaders @{ Prefer = 'return=representation' }
    return $resp
}

# Stores
$storeNames = @(
    @{ n = 'Northgate';      s = 'Northgate' },
    @{ n = 'Riverside';      s = 'Riverside' },
    @{ n = 'Westfield Park'; s = 'Westfield Park' }
)
$stores = @{}
foreach ($s in $storeNames) {
    $r = New-Row -Set "${Prefix}_stores" -Fields @{ "${Prefix}_name" = $s.n; "${Prefix}_suburb" = $s.s; "${Prefix}_isactive" = $true }
    $stores[$s.n] = $r."${Prefix}_storeid"
    Write-Host "  store: $($s.n)" -ForegroundColor DarkGray
}

# Products
$productDefs = @(
    @{ n = '65-inch 4K OLED television'; sku = 'TV-OLED-65'; c = 'Television'; p = 3299 },
    @{ n = 'Artisan espresso machine';   sku = 'CO-ESP-100'; c = 'Coffee';     p = 899 },
    @{ n = 'Cordless vacuum';            sku = 'VC-CORD-22'; c = 'Floorcare';  p = 649 }
)
$products = @{}
foreach ($p in $productDefs) {
    $r = New-Row -Set "${Prefix}_products" -Fields @{ "${Prefix}_name" = $p.n; "${Prefix}_sku" = $p.sku; "${Prefix}_category" = $p.c; "${Prefix}_price" = $p.p }
    $products[$p.n] = $r."${Prefix}_productid"
    Write-Host "  product: $($p.n)" -ForegroundColor DarkGray
}

# Suppliers - one deliberately in trouble, to drive supplier-risk-review
$supplierDefs = @(
    @{ n = 'Halberd Appliances'; rating = 2.6; status = 100000002; expiry = $today.AddDays(12) },
    @{ n = 'Meridian Electronics'; rating = 4.4; status = 100000000; expiry = $today.AddMonths(14) }
)
$suppliers = @{}
foreach ($s in $supplierDefs) {
    $r = New-Row -Set "${Prefix}_suppliers" -Fields @{
        "${Prefix}_name"           = $s.n
        "${Prefix}_rating"         = $s.rating
        "${Prefix}_status"         = $s.status
        "${Prefix}_contractexpiry" = $s.expiry.ToString('yyyy-MM-dd')
    }
    $suppliers[$s.n] = $r."${Prefix}_supplierid"
    Write-Host "  supplier: $($s.n)" -ForegroundColor DarkGray
}

# Inventory - the numbers matter:
#   Northgate has 0 of the TV, Riverside has 7 on hand / 2 reserved = 5 available
#     -> drives stock-transfer-request
#   Westfield Park espresso machine at 3 on hand / 1 reserved, reorder at 4
#     -> drives weekly-replenishment-plan
#   One row has on hand < reserved, which is a data error, not negative stock
$inventoryDefs = @(
    @{ store = 'Northgate';      product = '65-inch 4K OLED television'; onhand = 0; reserved = 0; reorder = 2; status = 100000002 },
    @{ store = 'Riverside';      product = '65-inch 4K OLED television'; onhand = 7; reserved = 2; reorder = 2; status = 100000000 },
    @{ store = 'Westfield Park'; product = 'Artisan espresso machine';   onhand = 3; reserved = 1; reorder = 4; status = 100000001 },
    @{ store = 'Northgate';      product = 'Cordless vacuum';            onhand = 2; reserved = 5; reorder = 3; status = 100000001 }
)
foreach ($i in $inventoryDefs) {
    $label = "$($i.store) - $($i.product)"
    New-Row -Set "${Prefix}_inventories" -Fields @{
        "${Prefix}_name"             = $label
        "${Prefix}_quantityonhand"   = $i.onhand
        "${Prefix}_quantityreserved" = $i.reserved
        "${Prefix}_reorderlevel"     = $i.reorder
        "${Prefix}_stockstatus"      = $i.status
    } | Out-Null
    Write-Host "  inventory: $label ($($i.onhand) on hand / $($i.reserved) reserved)" -ForegroundColor DarkGray
}

# Purchase orders - one delayed, which must NOT count as cover
$poDefs = @(
    @{ n = 'PO-9017'; qty = 6; status = 100000004; arrival = $today.AddDays(9) },
    @{ n = 'PO-9022'; qty = 4; status = 100000002; arrival = $today.AddDays(3) }
)
foreach ($p in $poDefs) {
    New-Row -Set "${Prefix}_purchaseorders" -Fields @{
        "${Prefix}_name"            = $p.n
        "${Prefix}_quantity"        = $p.qty
        "${Prefix}_postatus"        = $p.status
        "${Prefix}_expectedarrival" = $p.arrival.ToString('yyyy-MM-dd')
    } | Out-Null
    Write-Host "  purchase order: $($p.n)" -ForegroundColor DarkGray
}

# Employees
$employeeDefs = @(
    @{ n = 'Alex Morgan'; role = 'Store Manager';    email = 'alex.morgan@example.com' },
    @{ n = 'Sam Rivera';  role = 'Sales Consultant'; email = 'sam.rivera@example.com' },
    @{ n = 'Jo Chen';     role = 'Sales Consultant'; email = 'jo.chen@example.com' }
)
foreach ($e in $employeeDefs) {
    New-Row -Set "${Prefix}_employees" -Fields @{
        "${Prefix}_name"  = $e.n
        "${Prefix}_role"  = $e.role
        "${Prefix}_email" = $e.email
    } | Out-Null
    Write-Host "  employee: $($e.n)" -ForegroundColor DarkGray
}

# Leave - approved and covering today, so the briefing roster section is meaningful
New-Row -Set "${Prefix}_leaverequests" -Fields @{
    "${Prefix}_name"      = 'LR-4410'
    "${Prefix}_startdate" = $today.AddDays(-2).ToString('yyyy-MM-dd')
    "${Prefix}_enddate"   = $today.AddDays(3).ToString('yyyy-MM-dd')
    "${Prefix}_status"    = 100000001
} | Out-Null
Write-Host '  leave: LR-4410 (approved, covers today)' -ForegroundColor DarkGray

# IT tickets - an unassigned P1 due today is the thing every briefing must surface
$ticketDefs = @(
    @{ n = 'INC-64212'; subj = 'Point of sale terminals unresponsive'; pri = 100000000; status = 100000000; assigned = ''; due = $today.AddHours(4) },
    @{ n = 'INC-64230'; subj = 'Label printer offline';                pri = 100000002; status = 100000002; assigned = 'Jo Chen'; due = $today.AddDays(2) }
)
foreach ($t in $ticketDefs) {
    New-Row -Set "${Prefix}_ittickets" -Fields @{
        "${Prefix}_name"         = $t.n
        "${Prefix}_subject"      = $t.subj
        "${Prefix}_priority"     = $t.pri
        "${Prefix}_ticketstatus" = $t.status
        "${Prefix}_assignedto"   = $t.assigned
        "${Prefix}_sladuedate"   = $t.due.ToString('yyyy-MM-ddTHH:mm:ssZ')
    } | Out-Null
    Write-Host "  ticket: $($t.n)" -ForegroundColor DarkGray
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host ''
Write-Host 'Demo hooks now in the data:' -ForegroundColor Cyan
Write-Host '  "Morning briefing for Northgate"        -> INC-64212, P1, unassigned, SLA today'
Write-Host '  "Customer wants the 65-inch OLED at Northgate" -> 0 there, 5 available at Riverside'
Write-Host '  "What should Westfield Park reorder?"   -> espresso machine, 2 available, reorder at 4'
Write-Host '  "How is Halberd Appliances performing?" -> 2.6/5, Suspended, contract expires soon'
Write-Host ''
