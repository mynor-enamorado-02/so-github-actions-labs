# SCRIPT DE AUTOMATIZACIÓN LINUX
# ============================================

# Configuración
LOG_FILE="${LOG_FILE:-automation.log}"
OUTPUT_DIR="${OUTPUT_DIR:-automation-output}"
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d_%H%M%S)}"

# Función para logging
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Función para manejo de errores
handle_error() {
    local message="$1"
    local exit_code="${2:-1}"
    log "ERROR: $message (Código: $exit_code)"
    exit $exit_code
}

# Inicio del script
log "🚀 Iniciando script de automatización en Linux"
log "JOB_ID: $JOB_ID"
log "RUNNER_OS: $RUNNER_OS"
log "TIMESTAMP: $TIMESTAMP"
log "Directorio de trabajo: $(pwd)"

# 1. Crear directorio de salida
log "📁 Creando directorio de salida: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR" || handle_error "No se pudo crear el directorio $OUTPUT_DIR" 2

# 2. Leer/Escribir archivos
log "📝 Leyendo y escribiendo archivos..."

# Crear archivo de configuración
CONFIG_FILE="$OUTPUT_DIR/config_${TIMESTAMP}.txt"
log "Creando archivo de configuración: $CONFIG_FILE"

cat > "$CONFIG_FILE" << EOF
# Configuración del Sistema
# Generado automáticamente el: $(date)

PROPIEDADES:
- JOB_ID: $JOB_ID
- SISTEMA: $RUNNER_OS
- TIMESTAMP: $TIMESTAMP
- USUARIO: $(whoami)
- HOSTNAME: $(hostname)
- KERNEL: $(uname -r)

VARIABLES DE ENTORNO:
- API_TOKEN (longitud): ${#API_TOKEN} caracteres
- DB_PASSWORD (longitud): ${#DB_PASSWORD} caracteres
- GITHUB_WORKSPACE: $GITHUB_WORKSPACE
- RUNNER_TEMP: $RUNNER_TEMP
EOF

# Leer archivos del repositorio
log "Analizando estructura del repositorio..."
ls -la > "$OUTPUT_DIR/repo_structure.txt"

if [ -f "package.json" ] || [ -f "requirements.txt" ] || [ -f "pom.xml" ]; then
    log "📦 Detectados archivos de dependencias"
    
    # Buscar archivos de dependencias
    for file in package.json requirements.txt pom.xml build.gradle Gemfile; do
        if [ -f "$file" ]; then
            cp "$file" "$OUTPUT_DIR/"
            log "  Copiado: $file"
        fi
    done
fi

# 3. Gestionar permisos de archivos
log "🔐 Ajustando permisos de archivos..."

# Archivo de configuración: rw-r--r--
chmod 644 "$CONFIG_FILE" && log "  Permisos ajustados para $CONFIG_FILE"

# Directorio de salida: rwxr-xr-x
chmod 755 "$OUTPUT_DIR" && log "  Permisos ajustados para $OUTPUT_DIR"

# Crear script ejecutable de ejemplo
SCRIPT_FILE="$OUTPUT_DIR/ejemplo_ejecutable.sh"
cat > "$SCRIPT_FILE" << 'EOF'
#!/bin/bash
# Script de ejemplo ejecutable
echo "Hola desde el script ejecutable!"
echo "Fecha: $(date)"
echo "Usuario: $(whoami)"
EOF

chmod +x "$SCRIPT_FILE" && log "  Script ejecutable creado: $SCRIPT_FILE"

# 4. Crear procesos en segundo plano
log "⚙️  Iniciando procesos en segundo plano..."

# Proceso 1: Monitoreo del sistema
log "  Iniciando proceso de monitoreo..."
nohup bash -c "
    echo 'Iniciando monitoreo del sistema...' >> '$OUTPUT_DIR/monitor.log'
    for i in {1..5}; do
        echo 'Check $i: $(date) - Memoria: $(free -m | awk '/^Mem:/{print \$3\"MB\"}')' >> '$OUTPUT_DIR/monitor.log'
        sleep 2
    done
    echo 'Monitoreo completado' >> '$OUTPUT_DIR/monitor.log'
" > /dev/null 2>&1 &
MONITOR_PID=$!
log "    Proceso de monitoreo iniciado (PID: $MONITOR_PID)"

# Proceso 2: Generación de reporte
log "  Iniciando generación de reporte..."
(
    sleep 3
    echo "=== REPORTE DEL SISTEMA ===" > "$OUTPUT_DIR/system_report.txt"
    echo "Generado: $(date)" >> "$OUTPUT_DIR/system_report.txt"
    echo "---" >> "$OUTPUT_DIR/system_report.txt"
    echo "Uptime: $(uptime)" >> "$OUTPUT_DIR/system_report.txt"
    echo "Memoria: $(free -h | awk '/^Mem:/{print \$3\" / \"\$2}')" >> "$OUTPUT_DIR/system_report.txt"
    echo "Disco: $(df -h . | tail -1)" >> "$OUTPUT_DIR/system_report.txt"
    echo "CPU: $(nproc) núcleos" >> "$OUTPUT_DIR/system_report.txt"
) &
REPORT_PID=$!
log "    Generación de reporte iniciada (PID: $REPORT_PID)"

# 5. Usar variables de entorno y secretos
log "🔑 Procesando variables de entorno y secretos..."

ENV_REPORT="$OUTPUT_DIR/environment_report.txt"
{
    echo "=== INFORME DE VARIABLES DE ENTORNO ==="
    echo "Generado: $(date)"
    echo ""
    echo "VARIABLES DEL WORKFLOW:"
    echo "----------------------"
    echo "JOB_ID: $JOB_ID"
    echo "RUNNER_OS: $RUNNER_OS"
    echo "TIMESTAMP: $TIMESTAMP"
    echo "OUTPUT_DIR: $OUTPUT_DIR"
    echo ""
    echo "VARIABLES DE GITHUB:"
    echo "-------------------"
    echo "GITHUB_WORKFLOW: $GITHUB_WORKFLOW"
    echo "GITHUB_RUN_ID: $GITHUB_RUN_ID"
    echo "GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
    echo "GITHUB_REF: $GITHUB_REF"
    echo ""
    echo "SECRETOS (información de longitud):"
    echo "----------------------------------"
    echo "API_TOKEN: ${#API_TOKEN} caracteres"
    echo "DB_PASSWORD: ${#DB_PASSWORD} caracteres"
    echo ""
    echo "VARIABLES DEL SISTEMA:"
    echo "---------------------"
    echo "PATH: $PATH"
    echo "HOME: $HOME"
    echo "USER: $USER"
    echo "SHELL: $SHELL"
} > "$ENV_REPORT"

# 6. Generar archivo de resultados final
log "📊 Generando archivo de resultados..."

RESULTS_FILE="$OUTPUT_DIR/results_${TIMESTAMP}.json"
cat > "$RESULTS_FILE" << EOF
{
    "status": "success",
    "timestamp": "$(date -Iseconds)",
    "platform": "linux",
    "job_id": "$JOB_ID",
    "statistics": {
        "files_created": $(find "$OUTPUT_DIR" -type f | wc -l),
        "directories_created": 1,
        "processes_started": 2,
        "total_size_bytes": $(du -sb "$OUTPUT_DIR" | cut -f1)
    },
    "files": [
        "$(basename "$CONFIG_FILE")",
        "$(basename "$SCRIPT_FILE")",
        "$(basename "$ENV_REPORT")",
        "$(basename "$RESULTS_FILE")",
        "monitor.log",
        "system_report.txt",
        "repo_structure.txt"
    ],
    "processes": {
        "monitor_pid": $MONITOR_PID,
        "report_pid": $REPORT_PID
    },
    "environment": {
        "runner_os": "$RUNNER_OS",
        "github_workflow": "$GITHUB_WORKFLOW",
        "github_repository": "$GITHUB_REPOSITORY"
    }
}
EOF

# Esperar a que terminen los procesos background
log "⏳ Esperando a que terminen los procesos background..."
wait $MONITOR_PID 2>/dev/null || true
wait $REPORT_PID 2>/dev/null || true

# 7. Verificación final
log "✅ Verificando resultados..."

echo "=== RESUMEN DE EJECUCIÓN ===" >> "$LOG_FILE"
echo "Archivos generados en $OUTPUT_DIR:" >> "$LOG_FILE"
find "$OUTPUT_DIR" -type f -exec basename {} \; | sort >> "$LOG_FILE"

echo "" >> "$LOG_FILE"
echo "Contenido de los archivos:" >> "$LOG_FILE"
for file in "$OUTPUT_DIR"/*.txt "$OUTPUT_DIR"/*.json; do
    if [ -f "$file" ]; then
        echo "--- $(basename "$file") ---" >> "$LOG_FILE"
        head -5 "$file" >> "$LOG_FILE"
    fi
done

# Mostrar información final
log "========================================="
log "✅ AUTOMATIZACIÓN COMPLETADA EXITOSAMENTE"
log "📁 Output generado en: $OUTPUT_DIR/"
log "📄 Log guardado en: $LOG_FILE"
log "🕐 Duración: $SECONDS segundos"
log "========================================="

exit 0
