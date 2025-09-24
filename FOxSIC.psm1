# Este es el archivo psm1 
Set-StrictMode -Version Latest

<#
.SYNOPSIS
Obtiene la ruta de reporte y crea la carpeta "Reportes" si no existe.
.PARAMETER BasePath
Ruta base donde crear la carpeta Reportes. Por defecto, el Escritorio del usuario.
.OUTPUTS
String con la ruta completa del archivo de reporte.
.EXAMPLE
PS> Get-ReportPath -BasePath "D:\Logs"
#>
function Get-ReportPath {
    [CmdletBinding()]
    param(
        [string]$BasePath #Ruta opcional donde crear la carpeta de reporteS
    )
    $root = if ([string]::IsNullOrWhiteSpace($BasePath)) {
        [Environment]::GetFolderPath('Desktop') #Este solo se usa cuando el basepath es nulo o vacio
    } else {
        $BasePath
    }
    $reportsDir = Join-Path $root 'Reportes'
    if (-not (Test-Path $reportsDir)) {
        New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
    }
    $fecha = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $baseName  = "Reporte_$fecha" -f $fecha
    return @{ Directory = $reportsDir; BaseName = $baseName }
}

<#
.SYNOPSIS
Guarda una colección de objetos en uno o varios formatos (Text, CSV, HTML, XML).
.PARAMETER Data
Colección de objetos que se exportarán.
.PARAMETER OutputInfo
Hashtable devuelta por Get-ReportPath con claves Directory y BaseName.
.PARAMETER Formats
Array de formatos a generar. Valores permitidos: Text, CSV, HTML, XML.
.EXAMPLE
PS> Save-ReportFormats -Data $objs -OutputInfo $info -Formats Text,CSV,HTML
#>
#Creacion de los Reportes en el formato especificadoS, le agrege que se pudiera crear de todos profe :>
function Save-ReportFormats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][Object[]]   $Data,
        [Parameter(Mandatory)][hashtable]   $OutputInfo,
        [Parameter(Mandatory)][string[]]    $Formats
    )

    foreach ($fmt in $Formats) {
        switch ($fmt.ToUpper()) {
            'TEXT' {
                $path = Join-Path $OutputInfo.Directory ("{0}.txt" -f $OutputInfo.BaseName)
                $Data | Out-File -FilePath $path -Encoding utf8
                Write-Verbose "Generado TXT → $path"
            }
            'CSV' {
                $path = Join-Path $OutputInfo.Directory ("{0}.csv" -f $OutputInfo.BaseName)
                $Data | Export-Csv -Path $path -NoTypeInformation
                Write-Verbose "Generado CSV → $path"
            }
            'HTML' {
                $path = Join-Path $OutputInfo.Directory ("{0}.html" -f $OutputInfo.BaseName)
                $Data |
                    ConvertTo-Html -Title $OutputInfo.BaseName -PreContent "<h1>$($OutputInfo.BaseName)</h1>" |
                    Out-File -FilePath $path -Encoding utf8
                Write-Verbose "Generado HTML → $path"
            }
            'XML' {
                $path = Join-Path $OutputInfo.Directory ("{0}.xml" -f $OutputInfo.BaseName)
                $Data | Export-Clixml -Path $path
                Write-Verbose "Generado XML → $path"
            }
            default {
                Write-Warning "Formato desconocido: $fmt"
            }
        }
    }
}

<#
.SYNOPSIS
Devuelve el hashtable de categorías de eventos y sus IDs.
.OUTPUTS
Hashtable con categorías como claves y arrays de IDs como valores.
.EXAMPLE
PS> Get-EventCategories
#>
function Get-EventCategories {
    [OutputType([hashtable])]
    param()
    @{
        "Seguridad - Inicios de sesión"     = @(4624,4625,4647,4672,4768,4769,4771,4776)
        "Seguridad - Cuentas y privilegios" = @(4720,4722,4723,4725,4726,4732,4733,4670)
        "Seguridad - Recursos y políticas"  = @(1102,4674,4902,4907,4908)
        "Sistema"                           = @(6005,6006,7031,7034,7045)
        "Aplicaciones y Procesos"           = @(4688,4689)
    }
}
#TODOS LOS IDS LOS INVESTIGUE Y FUERON LOS QUE PENSE QUE SERIAN DE IMPORTANCIA.
<#
.SYNOPSIS
Genera un reporte de eventos de Security/System en texto, CSV, HTML o XML.
.PARAMETER BasePath
Ruta base donde crear carpeta Reportes; si no se especifica, usa Escritorio.
.PARAMETER Categories
Hashtable de categorías e IDs; si no se proporciona, usa Get-EventCategories.
.PARAMETER StartTime
Fecha mínima para filtrar eventos (DateTime).
.PARAMETER EndTime
Fecha máxima para filtrar eventos (DateTime).
.PARAMETER Formats
Formatos de salida: Text, CSV, HTML, XML. Por defecto Text.
.OUTPUTS
String[] con las rutas de los archivos generados.
.EXAMPLE
PS> New-EventReport -StartTime (Get-Date).AddDays(-7) -Formats Text,CSV
#>
function New-EventReport {
    [CmdletBinding()]
    param(
        [string]   $BasePath,
        [hashtable]$Categories  = $(Get-EventCategories),
        [datetime] $StartTime,
        [datetime] $EndTime,
        [string[]] $Formats     = @('Text')
    )

    # Prepara la ruta base
    $outInfo = Get-ReportPath -BasePath $BasePath
    $allEvents = @()

    foreach ($cat in $Categories.Keys) {
        $log = if ($cat -like 'Sistema*') { 'System' } else { 'Security' }
        $filter = @{ LogName = $log; Id = $Categories[$cat] }
        if ($PSBoundParameters.ContainsKey('StartTime')) { $filter.StartTime = $StartTime }
        if ($PSBoundParameters.ContainsKey('EndTime'))   { $filter.EndTime   = $EndTime }

        $evts = Get-WinEvent -FilterHashtable $filter -ErrorAction SilentlyContinue
        $evts | ForEach-Object {
            $allEvents += [PSCustomObject]@{
                Category     = $cat
                TimeCreated  = $_.TimeCreated
                Id           = $_.Id
                ProviderName = $_.ProviderName
                Message      = ($_.Message -split "`n")[0]
            }
        }
    }

    Save-ReportFormats -Data $allEvents -OutputInfo $outInfo -Formats $Formats
    return Get-ChildItem -Path $outInfo.Directory -Filter "$($outInfo.BaseName).*" |
           Select-Object -ExpandProperty FullName
}

<#
.SYNOPSIS
Enumera procesos con ruta y conexiones TCP establecidas.
.OUTPUTS
PSCustomObject[] con ProcessId, ProcessName, Path, LocalAddress, LocalPort, RemoteAddress, RemotePort.
.EXAMPLE
PS> Get-ProcessNetworkData
#>
function Get-ProcessNetworkData {
    [OutputType([PSCustomObject[]])]
    param()

    $procs = Get-Process | Where-Object Path | Select-Object Id, ProcessName, Path
    $conns = Get-NetTCPConnection -State Established |
             Select-Object @{Name='ProcessId';Expression={$_.OwningProcess}},
                           LocalAddress,LocalPort,RemoteAddress,RemotePort

    foreach ($c in $conns) {
        $p = $procs | Where-Object Id -EQ $c.ProcessId
        if ($p) {
            [PSCustomObject]@{
                ProcessId     = $c.ProcessId
                ProcessName   = $p.ProcessName
                Path          = $p.Path
                LocalAddress  = $c.LocalAddress
                LocalPort     = $c.LocalPort
                RemoteAddress = $c.RemoteAddress
                RemotePort    = $c.RemotePort
            }
        }
    }
}

<#
.SYNOPSIS
Filtra procesos cuya firma no es válida o corren fuera de carpetas de sistema.
.PARAMETER NetworkData
Colección de objetos devueltos por Get-ProcessNetworkData.
.OUTPUTS
PSCustomObject[] con procesos sospechosos.
.EXAMPLE
PS> Get-SuspiciousProcesses -NetworkData $data
#>
function Get-SuspiciousProcesses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject[]]$NetworkData
    )
    $NetworkData | Where-Object {
        $sig = Get-AuthenticodeSignature -FilePath $_.Path
        ($sig.Status -ne 'Valid') -or
        ($_.Path -notmatch '^(?:[A-Za-z]:\\Windows|[A-Za-z]:\\Program Files)')
    }
}

<#
.SYNOPSIS
Genera un reporte correlacionando procesos con conexiones de red.
.PARAMETER BasePath
Ruta base para crear carpeta Reportes.
.PARAMETER Formats
Formatos de salida: Text, CSV, HTML, XML. Por defecto Text.
.OUTPUTS
String[] con rutas de los archivos generados.
.EXAMPLE
PS> New-ProcessNetworkReport -Formats Text,HTML
#>
function New-ProcessNetworkReport {
    [CmdletBinding()]
    param(
        [string[]] $Formats  = @('Text'),
        [string]   $BasePath
    )

    $outInfo = Get-ReportPath -BasePath $BasePath
    $data    = Get-ProcessNetworkData
    $formatted = $data | ForEach-Object {
        [PSCustomObject]@{
            ProcessId     = $_.ProcessId
            ProcessName   = $_.ProcessName
            Path          = $_.Path
            LocalAddress  = $_.LocalAddress
            LocalPort     = $_.LocalPort
            RemoteAddress = $_.RemoteAddress
            RemotePort    = $_.RemotePort
        }
    }

    # Adjunta columna de sospechosida
    $sus = Get-SuspiciousProcesses -NetworkData $data
    $formatted | ForEach-Object {
        $_ | Add-Member -NotePropertyName IsSuspicious `
             -NotePropertyValue ($sus.ProcessId -contains $_.ProcessId) -PassThru
    } | Out-Null

    Save-ReportFormats -Data $formatted -OutputInfo $outInfo -Formats $Formats
    return Get-ChildItem -Path $outInfo.Directory -Filter "$($outInfo.BaseName).*" |
           Select-Object -ExpandProperty FullName
}

<#
.SYNOPSIS
Extrae direcciones IP remotas únicas de datos de red.
.PARAMETER NetworkData
Colección de objetos de Get-ProcessNetworkData.
.OUTPUTS
String[] con IPs únicas.
.EXAMPLE
PS> Get-RemoteIPs -NetworkData $data
#>
function Get-RemoteIPs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject[]]$NetworkData
    )
    $NetworkData |
        Select-Object -ExpandProperty RemoteAddress |
        Where-Object { $_ -and $_ -ne '0.0.0.0' } |
        Sort-Object -Unique
}

<#
.SYNOPSIS
Consulta AbuseIPDB para obtener reputación de una IP.
.PARAMETER ApiKey
Clave API de AbuseIPDB.
.PARAMETER IPAddress
Dirección IPv4 a consultar.
.OUTPUTS
PSCustomObject con AbuseConfidenceScore, CountryCode, Domain, UsageType.
.EXAMPLE
PS> Invoke-IPReputationQuery -ApiKey 'abc' -IPAddress '1.2.3.4'
#>
function Invoke-IPReputationQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiKey,
        [Parameter(Mandatory)][string]$IPAddress
    )
    $uri     = "https://api.abuseipdb.com/api/v2/check?ipAddress=$IPAddress&maxAgeInDays=90"
    $headers = @{ Key = $ApiKey; Accept = 'application/json' }

    try {
        $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
        return [PSCustomObject]@{
            IPAddress            = $IPAddress
            AbuseConfidenceScore = $resp.data.abuseConfidenceScore
            CountryCode          = $resp.data.countryCode
            Domain               = $resp.data.domain
            UsageType            = $resp.data.usageType
        }
    }
    catch {
        Write-Warning ("Error consultando {0}: {1}" -f $IPAddress, $_)
        return [PSCustomObject]@{
            IPAddress            = $IPAddress
            AbuseConfidenceScore = -1
            CountryCode          = ''
            Domain               = ''
            UsageType            = ''
        }
    }
}

<#
.SYNOPSIS
Genera un reporte de reputación de IPs usando AbuseIPDB.
.PARAMETER ApiKey
Clave API de AbuseIPDB.
.PARAMETER NetworkData
Datos de red de Get-ProcessNetworkData.
.PARAMETER Formats
Formatos de salida: Text, CSV, HTML, XML. Por defecto Text.
.PARAMETER BasePath
Ruta base para crear carpeta Reportes.
.OUTPUTS
String[] con rutas de archivos generados.
.EXAMPLE
PS> New-IPReputationReport -ApiKey 'abc' -NetworkData $data -Formats CSV,HTML
#>
function New-IPReputationReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]       $ApiKey,
        [Parameter(Mandatory)][PSCustomObject[]]$NetworkData,
        [string[]]                           $Formats = @('Text'),
        [string]                             $BasePath
    )

    $outInfo = Get-ReportPath -BasePath $BasePath
    $ips     = Get-RemoteIPs -NetworkData $NetworkData
    $results = @()

    foreach ($ip in $ips) {
        $results += Invoke-IPReputationQuery -ApiKey $ApiKey -IPAddress $ip
    }

    Save-ReportFormats -Data $results -OutputInfo $outInfo -Formats $Formats
    return Get-ChildItem -Path $outInfo.Directory -Filter "$($outInfo.BaseName).*" |
           Select-Object -ExpandProperty FullName
}

# Exportar funciones públicas
Export-ModuleMember -Function `
    Get-ReportPath, Save-ReportFormats, Get-EventCategories, New-EventReport, `
    Get-ProcessNetworkData, Get-SuspiciousProcesses, New-ProcessNetworkReport, `
    Get-RemoteIPs, Invoke-IPReputationQuery, New-IPReputationReport
