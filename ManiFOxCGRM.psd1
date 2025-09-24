@{
    Modulo            = 'FOxSIC.psm1'
    ModuleVersion     = '1.0'
    GUID              = 'e4a6b8ea-5f2c-4bb4-834e-2b3e9c8a12d7'
    Author            = 'Giovanni'
    Copyright         = '(c) 2025 Giovanni. All rights reserved.'
    Description       = 'Módulo FOxSIC para automatizar análisis forense: eventos de Windows, procesos, red y reputación de IPs.'

    FunctionsToExport = @(
        'Get-ReportPath'
        'Save-ReportFormats'
        'Get-EventCategories'
        'New-EventReport'
        'Get-ProcessNetworkData'
        'Get-SuspiciousProcesses'
        'New-ProcessNetworkReport'
        'Get-RemoteIPs'
        'Invoke-IPReputationQuery'
        'New-IPReputationReport'
    )

    CmdletsToExport    = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    RequiredModules    = @()
    NestedModules      = @()
    RequiredAssemblies = @()

    # Archivos incluidos al instalar el módulo
    FileList = @(
        'FOxSIC.psm1'
        'FOxSIC.psd1'
    )

    PrivateData = @{
        PSData = @{
            Tags        = @('Forensics','Security','Eventos','Network','AbuseIPDB')
            ReleaseNotes= 'Versión inicial: cubre análisis de eventos, procesos, red y reputación de IPs.'
        }
    }
}
