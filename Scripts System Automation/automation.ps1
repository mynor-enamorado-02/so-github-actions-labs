# SCRIPT DE AUTOMATIZACIÓN WINDOWS P
# ============================================

# Configuración
$LogFile = if ($env:LOG_FILE) { $env:LOG_FILE } else { "automation.log" }
$OutputDir = if ($env:OUTPUT_DIR) { $env:OUTPUT_DIR } else { "automation-output" }
$Timestamp = if ($env:TIMESTAMP) { $env:TIMESTAMP } else { Get-Date -Format "yyyyMMdd_HHmmss" }

# Función para logging
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Write-Host $logEntry
    $logEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Función para manejo de errores
function Handle-Error {
    param(
        [string]$Message,
        [int]$ExitCode = 1
    )
    
    Write-Log -Message "ERROR: $Message" -Level "ERROR"
    Write-Log -Message "Código de salida: $ExitCode" -Level "ERROR"
    exit $ExitCode
}

# Inicio del script
Write-Log "🚀 Iniciando script de automatización en Windows"
Write-Log "JOB_ID: $env:JOB_ID"
Write-Log "RUNNER_OS: $env:RUNNER_OS"
Write-Log "TIMESTAMP: $Timestamp"
Write-Log "Directorio de trabajo: $(Get-Location)"

# 1. Crear directorio de salida
Write-Log "📁 Creando directorio de salida: $OutputDir"
try {
    New-Item -ItemType Directory -Path $OutputDir -Force -ErrorAction Stop | Out-Null
} catch {
    Handle-Error "No se pudo crear el directorio $OutputDir" 2
}

# 2. Leer/Escribir archivos
Write-Log "📝 Leyendo y escribiendo archivos..."

# Crear archivo de configuración
$ConfigFile = "$OutputDir\config_${Timestamp}.txt"
Write-Log "Creando archivo de configuración: $ConfigFile"

@"
# Configuración del Sistema Windows
# Generado automáticamente el: $(Get-Date)

PROPIEDADES:
- JOB_ID: $env:JOB_ID
- SISTEMA: $env:RUNNER_OS
- TIMESTAMP: $Timestamp
- USUARIO: $env:USERNAME
- COMPUTADORA: $env:COMPUTERNAME
- WINDOWS: $( [System.Environment]::OSVersion.Version)

VARIABLES DE ENTORNO:
- API_TOKEN (longitud): $($env:API_TOKEN.Length) caracteres
- DB_PASSWORD (longitud): $($env:DB_PASSWORD.Length) caracteres
- GITHUB_WORKSPACE: $env:GITHUB_WORKSPACE
- RUNNER_TEMP: $env:RUNNER_TEMP
"@ | Out-File -FilePath $ConfigFile -Encoding UTF8

# Leer archivos del repositorio
Write-Log "Analizando estructura del repositorio..."
Get-ChildItem -Recurse -Depth 2 | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize | Out-File -FilePath "$OutputDir\repo_structure.txt"

# Buscar archivos de dependencias
$dependencyFiles = @("package.json", "requirements.txt", "pom.xml", "build.gradle", "Gemfile", "*.csproj", "*.vbproj")
$foundFiles = Get-ChildItem -Path . -Include $dependencyFiles -Recurse -ErrorAction SilentlyContinue

if ($foundFiles.Count -gt 0) {
    Write-Log "📦 Detectados archivos de dependencias"
    
    foreach ($file in $foundFiles) {
        $destination = "$OutputDir\$($file.Name)"
        Copy-Item -Path $file.FullName -Destination $destination -Force
        Write-Log "  Copiado: $($file.Name)"
    }
}

# 3. Gestionar permisos de archivos (Windows ACL)
Write-Log "🔐 Configurando permisos de archivos..."

try {
    # Intentar ajustar permisos (puede fallar sin permisos de admin)
    $acl = Get-Acl $ConfigFile
    $permission = "BUILTIN\Users", "Read", "Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $ConfigFile -AclObject $acl
    Write-Log "  Permisos ajustados para $ConfigFile"
} catch {
    Write-Log "  ⚠️  No se pudieron ajustar permisos (se requieren privilegios elevados)" -Level "WARNING"
}

# 4. Crear procesos en segundo plano
Write-Log "⚙️  Iniciando procesos en segundo plano..."

# Trabajo 1: Monitoreo del sistema
Write-Log "  Iniciando trabajo de monitoreo..."
$monitorJob = Start-Job -Name "SystemMonitor" -ScriptBlock {
    param($OutputPath)
    
    "Iniciando monitoreo del sistema..." | Out-File -FilePath "$OutputPath\monitor.log" -Append
    for ($i = 1; $i -le 5; $i++) {
        $mem = Get-CimInstance -ClassName Win32_OperatingSystem | 
               Select-Object @{Name="FreeMemoryMB"; Expression={[math]::Round($_.FreePhysicalMemory/1024, 2)}}
        
        "Check $i: $(Get-Date) - Memoria Libre: $($mem.FreeMemoryMB)MB" | 
            Out-File -FilePath "$OutputPath\monitor.log" -Append
        Start-Sleep -Seconds 2
    }
    "Monitoreo completado" | Out-File -FilePath "$OutputPath\monitor.log" -Append
} -ArgumentList $OutputDir

Write-Log "    Trabajo de monitoreo iniciado (ID: $($monitorJob.Id))"

# 5. Usar variables de entorno y secretos
Write-Log "🔑 Procesando variables de entorno y secretos..."

$EnvReport = "$OutputDir\environment_report.txt"
@"
=== INFORME DE VARIABLES DE ENTORNO WINDOWS ===
Generado: $(Get-Date)

VARIABLES DEL WORKFLOW:
----------------------
JOB_ID: $env:JOB_ID
RUNNER_OS: $env:RUNNER_OS
TIMESTAMP: $Timestamp
OUTPUT_DIR: $OutputDir

VARIABLES DE GITHUB:
-------------------
GITHUB_WORKFLOW: $env:GITHUB_WORKFLOW
GITHUB_RUN_ID: $env:GITHUB_RUN_ID
GITHUB_REPOSITORY: $env:GITHUB_REPOSITORY
GITHUB_REF: $env:GITHUB_REF

SECRETOS (información de longitud):
----------------------------------
API_TOKEN: $($env:API_TOKEN.Length) caracteres
DB_PASSWORD: $($env:DB_PASSWORD.Length) caracteres

VARIABLES DEL SISTEMA WINDOWS:
------------------------------
OS: $([System.Environment]::OSVersion.VersionString)
ComputerName: $env:COMPUTERNAME
UserName: $env:USERNAME
UserDomain: $env:USERDOMAIN
ProcessorCount: $env:NUMBER_OF_PROCESSORS
SystemDrive: $env:SystemDrive
Temp: $env:TEMP
Path: $env:PATH
"@ | Out-File -FilePath $EnvReport -Encoding UTF8

# 6. Generar archivo de resultados final
Write-Log "📊 Generando archivo de resultados..."

$ResultsFile = "$OutputDir\results_${Timestamp}.json"
$fileCount = (Get-ChildItem -Path $OutputDir -File -Recurse).Count
$totalSize = (Get-ChildItem -Path $OutputDir -Recurse | Measure-Object -Property Length -Sum).Sum

@"
{
    "status": "success",
    "timestamp": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')",
    "platform": "windows",
    "job_id": "$env:JOB_ID",
    "statistics": {
        "files_created": $fileCount,
        "directories_created": 1,
        "jobs_started": 1,
        "total_size_bytes": $totalSize
    },
    "files": [
        "$(Split-Path $ConfigFile -Leaf)",
        "$(Split-Path $EnvReport -Leaf)",
        "$(Split-Path $ResultsFile -Leaf)",
        "monitor.log",
        "repo_structure.txt"
    ],
    "jobs": {
        "monitor_job_id": $($monitorJob.Id)
    },
    "environment": {
        "runner_os": "$env:RUNNER_OS",
        "github_workflow": "$env:GITHUB_WORKFLOW",
        "github_repository": "$env:GITHUB_REPOSITORY",
        "windows_version": "$([System.Environment]::OSVersion.Version)"
    }
}
"@ | Out-File -FilePath $ResultsFile -Encoding UTF8

# 7. Esperar y recibir resultados de los jobs
Write-Log "⏳ Esperando a que terminen los trabajos background..."

# Esperar máximo 10 segundos
$maxWaitTime = 10
$startTime = Get-Date

while ((Get-Date) - $startTime).TotalSeconds -lt $maxWaitTime -and (Get-Job -State Running).Count -gt 0) {
    Write-Log "  Esperando trabajos... ($([math]::Round((Get-Date - $startTime).TotalSeconds))s)"
    Start-Sleep -Seconds 1
}

# Recibir resultados
$runningJobs = Get-Job -State Running
if ($runningJobs.Count -gt 0) {
    Write-Log "  ⚠️  Algunos trabajos aún están ejecutándose (fuerzan detención)" -Level "WARNING"
    $runningJobs | Stop-Job -PassThru | Remove-Job -Force
}

# Recibir resultados de trabajos completados
Get-Job -State Completed | Receive-Job -ErrorAction SilentlyContinue

# Limpiar trabajos
Get-Job | Remove-Job -Force

# 8. Verificación final
Write-Log "✅ Verificando resultados..."

"=== RESUMEN DE EJECUCIÓN ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
"Archivos generados en $OutputDir:" | Out-File -FilePath $LogFile -Append -Encoding UTF8
Get-ChildItem -Path $OutputDir -File | Select-Object -ExpandProperty Name | Sort-Object | 
    Out-File -FilePath $LogFile -Append -Encoding UTF8

"" | Out-File -FilePath $LogFile -Append -Encoding UTF8
"Contenido de los archivos principales:" | Out-File -FilePath $LogFile -Append -Encoding UTF8
Get-ChildItem -Path $OutputDir -Filter *.txt | ForEach-Object {
    "--- $($_.Name) ---" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Get-Content -Path $_.FullName -TotalCount 5 | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Mostrar información final
Write-Log "========================================="
Write-Log "✅ AUTOMATIZACIÓN COMPLETADA EXITOSAMENTE"
Write-Log "📁 Output generado en: $OutputDir\"
Write-Log "📄 Log guardado en: $LogFile"
Write-Log "🕐 Duración: $($ElapsedTime = (Get-Date) - (Get-Date).AddSeconds(-$SECONDS); '{0:N1}' -f $ElapsedTime.TotalSeconds) segundos"
Write-Log "========================================="

exit 0
