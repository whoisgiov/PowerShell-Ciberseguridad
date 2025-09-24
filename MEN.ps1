# MEN.ps1
param()

Set-StrictMode -Version Latest

# Determina la carpeta del script y carga el módulo
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleFile = Join-Path $ScriptDir 'FOxSIC.psm1'
if (-not (Test-Path $ModuleFile)) {
    Write-Error "No encontré el módulo en la ruta: $ModuleFile"
    exit 1
}
Import-Module -Force $ModuleFile -ErrorAction Stop
#Es el mení en sí
function Show-Menu {
    Clear-Host
    Write-Host '                                                                                                               
                                                                                                               
                                                                                                               
                                                                                                               
                                                                                                               
                                                                                                               
                   ..=+-...                                                       ...:=+-..                    
                   .%@@@@@*:...                                               ....=%@@@@@=.                    
                   -@@@@@@@@@*:..                                           ...-%@@@@@@@@#.                    
                  .+@@@%-#@@@@@%-..                                       ...+@@@@@@+=@@@@:.                   
                 ..%@@@@=..-%@@@@%=...                                  ..:*@@@@@*:..#@@@@-.                   
                 .:%@@@@@%:..-*@@@@%-..                               ...+@@@@%+:..+%@@@@@+.                   
                 .-@@@@@@@@+...-#@@@@*:..   ........  ............  ...-%@@@%+...:#@@@@@@@#.                   
                 .-@@@@=@@@@#:...=#@@@%=..:=*##%%%@@@@@@@@@%%%##*+-:..*@@@@*:...=%@@@#*@@@%..                  
                 .=@@@%.:#@@@#-...:+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-....+@@@@+.=@@@%.                   
                 .=@@@%...*@@@%-....-%@@@@@@%*++=-----:-----==+*#%@@@@@@*.. ..+@@@@=..=@@@%.                   
                 .=@@@%....+@@@%-....:=+=-........  ...............:-++-. ...+@@@%-...=@@@%.                   
                ..-@@@@....-%@@@#:.   .....                         ....  ..=@@@@*:...+@@@#.                   
                 .:%@@@-:+%@@@@@*:.                                       ..-%@@@@@#=:#@@@+.                   
                 ..#@@@@@@@@@#+:...                                        ...-*%@@@@@@@@@:.                   
               ....+@@@@@@%+:..                                            ......-*@@@@@@%:....                
            ....:+@@@@@@*:...                                                   ....-#@@@@@%-....              
           ...-#@@@@@#-..                                                           ...+%@@@@@+:...            
       ....:+@@@@@%=...                                                               ...:#@@@@@%=....         
       ..-%@@@@@#:..                                                                      ..-%@@@@@*:.         
    ..:*@@@@@%=...                                                                         ...:+@@@@@%=..      
  ..=%@@@@@*:....                                                                         .......-#@@@@@#:..   
 .:@@@@@@@@@@@@%#+=:..                   .-##-                 .+#*..                   ..:=*#%@@@@@@@@@@@*..  
 ..%@@@@@@@@@@@@@@@@@@%#+:.             ..%@@@..             ..=@@@+.             ..:+#%@@@@@@@@@@@@@@@@@@+..  
 ..:#@@@%+::--=+#%@@@@@@@@@%*=:..       ..:++:               ...-+=..         ..=*%@@@@@@@@@%#+=--::+@@@@+...  
 ....+@@@@+........::-+#@@@@@@@%*-.                            ...        ..-*%@@@@@@@#+=::.......:+@@@@+..    
    ..=@@@@#-............:=+%@@@@@@#=..                               ...=#@@@@@@%*=:............-#@@@%=...    
   ....-#@@@%+:..............:=*@@@@@@#-...                         ..-#@@@@@@#=:..............:*@@@@*:..      
    .....=%@@@#:.................-*%@@@@%+:.                     ..:+@@@@@%*-................:+@@@@%=..'
    Write-Host ' 
____   ____    ___  ____   __ __    ___  ____   ____  ___     ___        ____      _____   ___   __ __   _____
|    \ |    |  /  _]|    \ |  |  |  /  _]|    \ |    ||   \   /   \      /    |    |     | /   \ |  |  | / ___/
|  o  ) |  |  /  [_ |  _  ||  |  | /  [_ |  _  | |  | |    \ |     |    |  o  |    |   __||     ||  |  |(   \_ 
|     | |  | |    _]|  |  ||  |  ||    _]|  |  | |  | |  D  ||  O  |    |     |    |  |_  |  O  ||_   _| \__  |
|  O  | |  | |   [_ |  |  ||  :  ||   [_ |  |  | |  | |     ||     |    |  _  |    |   _] |     ||     | /  \ |
|     | |  | |     ||  |  | \   / |     ||  |  | |  | |     ||     |    |  |  |    |  |   |     ||  |  | \    |
|_____||____||_____||__|__|  \_/  |_____||__|__||____||_____| \___/     |__|__|    |__|    \___/ |__|__|  \___|  BY GIOVANNI :)' -ForegroundColor Red
    Write-Host '=== MENU ===' -ForegroundColor Red
    Write-Host '1) Reporte de Eventos'
    Write-Host '2) Reporte Procesos -> Red'
    Write-Host '3) Reporte Reputacion IP'
    Write-Host '0) Salir'
} 
#EL MENU PRINCIPAL

while ($true) {
    Show-Menu
    $choice = Read-Host 'Selecciona porfavor una opcion'

    switch ($choice) {
        '1' {
            # Crea el reporte de Eventos de get-events 
            $days     = Read-Host 'Ultimos cuantos dias? (Por default analiza los ultimos 7 días)'
            if (-not [int]::TryParse($days, [ref]$null)) { $days = 7 }
            $fmts     = Read-Host 'Especifique el tipo de archivo en el que requiere el reporte: CSV, Text, HTML, XML <---Debe escribirlo tal cual esta aquí '
            $fmtArray = $fmts.Split(',') | ForEach-Object { $_.Trim() }
            $paths    = New-EventReport -StartTime (Get-Date).AddDays(-$days) -Formats $fmtArray
            Write-Host "EL archivo fue creado:`n$($paths -join "`n")"
        }
        '2' {
            # Reporte Procesos de Red
            $fmts     = 'Especifique el tipo de archivo en el que requiere el reporte: CSV, Text, HTML, XML <---Debe escribirlo tal cual esta aquí '
            $fmtArray = $fmts.Split(',') | ForEach-Object { $_.Trim() }
            $paths    = New-ProcessNetworkReport -Formats $fmtArray
            Write-Host "EL archivo fue creado:`n$($paths -join "`n")"
        }
        '3' {
            # Reportede  Reputacion IP
            $apiKey   = Read-Host 'API Key AbuseIPDB'
            $fmts     = Read-Host 'Especifique el tipo de archivo en el que requiere el reporte: CSV, Text, HTML, XML <---Debe escribirlo tal cual esta aquí '
            $fmtArray = $fmts.Split(',') | ForEach-Object { $_.Trim() }
            $netData  = Get-ProcessNetworkData
            $paths    = New-IPReputationReport -ApiKey $apiKey -NetworkData $netData -Formats $fmtArray
            Write-Host "`EL archivo fue creado:`n$($paths -join "`n")"
        }
        '0' {
            Write-Host 'Saliendo...' -ForegroundColor Yellow
            break
        }
        Default {
            Write-Host 'La opción que escribio es invalida, intentalp de nuevo.' -ForegroundColor Red
        }
    } 

    if ($choice -ne '0') {
        Read-Host "`nPresiona Enter para continuar..."
    }
}
