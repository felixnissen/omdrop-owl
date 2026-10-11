#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Pretty
)

$ErrorActionPreference = 'Stop'

function Invoke-NetshText {
    param([Parameter(Mandatory)][string[]]$Arguments)

    try {
        $output = & netsh @Arguments 2>&1
        [pscustomobject]@{
            ok   = ($LASTEXITCODE -eq 0)
            text = ($output -join "`n").Trim()
        }
    }
    catch {
        [pscustomobject]@{
            ok    = $false
            text  = ''
            error = $_.Exception.Message
        }
    }
}

function Get-DriverInfo {
    param([string]$InstanceId)

    if (-not $InstanceId) { return $null }

    try {
        $escaped = $InstanceId.Replace("'", "''")
        $driver = Get-CimInstance Win32_PnPSignedDriver -Filter "DeviceID='$escaped'" -ErrorAction Stop
        if (-not $driver) { return $null }

        [ordered]@{
            provider = $driver.DriverProviderName
            version  = $driver.DriverVersion
            date     = if ($driver.DriverDate) { ([datetime]$driver.DriverDate).ToString('o') } else { $null }
            inf      = $driver.InfName
        }
    }
    catch {
        [ordered]@{ error = $_.Exception.Message }
    }
}

$os = Get-CimInstance Win32_OperatingSystem

$wifiAdapters = @(
    Get-NetAdapter -Physical -ErrorAction Stop |
        Where-Object {
            $_.NdisPhysicalMedium -eq 9 -or
            $_.InterfaceDescription -match 'Wireless|Wi-Fi|802\.11'
        } |
        ForEach-Object {
            $pnp = $null
            try {
                $pnp = Get-PnpDevice -Class Net -InstanceId $_.PnPDeviceID -ErrorAction Stop
            } catch { }

            [ordered]@{
                name                  = $_.Name
                interfaceDescription  = $_.InterfaceDescription
                status                = [string]$_.Status
                macAddress            = $_.MacAddress
                linkSpeed             = $_.LinkSpeed
                interfaceGuid         = [string]$_.InterfaceGuid
                ifIndex               = $_.ifIndex
                pnpInstanceId         = $_.PnPDeviceID
                pnpFriendlyName       = if ($pnp) { $pnp.FriendlyName } else { $null }
                driver                = Get-DriverInfo -InstanceId $_.PnPDeviceID
            }
        }
)

$interfaces = Invoke-NetshText -Arguments @('wlan', 'show', 'interfaces')
$drivers = Invoke-NetshText -Arguments @('wlan', 'show', 'drivers')

$result = [ordered]@{
    schemaVersion = 1
    probe = [ordered]@{
        name      = 'omdrop-windows-capability-probe'
        readOnly  = $true
        timestamp = (Get-Date).ToUniversalTime().ToString('o')
    }
    system = [ordered]@{
        computerName = $env:COMPUTERNAME
        caption      = $os.Caption
        version      = $os.Version
        buildNumber  = $os.BuildNumber
        architecture = $os.OSArchitecture
    }
    adapters = $wifiAdapters
    nativeWlan = [ordered]@{
        interfaces = $interfaces
        drivers    = $drivers
    }
    assessment = [ordered]@{
        stage = 'inventory'
        note  = 'Inventory only. This probe does not claim monitor mode, frame injection, AWDL, or AirDrop support.'
    }
}

$json = $result | ConvertTo-Json -Depth 8 -Compress:(-not $Pretty)
Write-Output $json
