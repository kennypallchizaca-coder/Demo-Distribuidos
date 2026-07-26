# Script de Ayuda y Verificación de Entorno (PowerShell - Windows)
# Para ejecutar en PowerShell: .\documentacion\scripts\verificar.ps1

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         VERIFICADOR AUTOMATICO DE DIAGNOSTICO            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificación del Puerto de la Aplicación Node.js (Reto 1)
Write-Host "[1/4] Verificando respuesta HTTP de la aplicacion..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 3 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "  [OK] La aplicacion responde correctamente en http://localhost:8080 (HTTP 200 OK)" -ForegroundColor Green
    } else {
        Write-Host "  [ALERTA] La aplicacion respondio con codigo: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR RETO 1] No hay respuesta en http://localhost:8080" -ForegroundColor Red
    Write-Host "  RECOMENDACION: Revisar si server.js escucha en 8080 y si Dockerfile contiene 'EXPOSE 8080'." -ForegroundColor Gray
}

Write-Host ""

# 2. Verificación de Manifiestos de Kubernetes (Reto 2)
Write-Host "[2/4] Verificando endpoints de Kubernetes..." -ForegroundColor Yellow
if (Get-Command "kubectl" -ErrorAction SilentlyContinue) {
    try {
        $endpoints = kubectl get endpoints web-service -o jsonpath='{.subsets[*].addresses[*].ip}' 2>$null
        if ($endpoints) {
            Write-Host "  [OK] Endpoints de Kubernetes poblados: $endpoints" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR RETO 2] El servicio 'web-service' no tiene Endpoints asociados (<none>)" -ForegroundColor Red
            Write-Host "  RECOMENDACION: Verificar que 'Service.spec.selector.app' sea 'webapp' e igual a 'template.metadata.labels.app'." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [INFO] No se pudo consultar el cluster de Kubernetes o no hay cluster activo." -ForegroundColor Gray
    }
} else {
    Write-Host "  [INFO] kubectl no esta instalado en este sistema." -ForegroundColor Gray
}

Write-Host ""

# 3. Verificación de Pruebas Automatizadas (Reto 3)
Write-Host "[3/4] Verificando ejecucion de pruebas automatizadas..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    try {
        $testResult = npm test 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Pruebas automatizadas (npm test) pasaron correctamente." -ForegroundColor Green
        } else {
            Write-Host "  [ALERTA RETO 3] Las pruebas fallaron (exit code $LASTEXITCODE)." -ForegroundColor Red
            Write-Host "  RECOMENDACION: Asegurar 'needs: build-test' en ci.yml para bloquear el despliegue cuando falle el test." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [ERROR] Ocurrio un fallo al ejecutar npm test." -ForegroundColor Red
    }
} else {
    Write-Host "  [INFO] No se encontro package.json en el directorio actual." -ForegroundColor Gray
}

Write-Host ""

# 4. Verificación de Réplicas y RollingUpdate (El Giro)
Write-Host "[4/4] Verificando configuracion de alta disponibilidad (El Giro)..." -ForegroundColor Yellow
if (Test-Path "k8s.yaml") {
    $content = Get-Content "k8s.yaml" -Raw
    if ($content -match "replicas:\s*([6-9]|\d{2,})") {
        Write-Host "  [OK] Replicas configuradas para alta disponibilidad (6 o mas)." -ForegroundColor Green
    } else {
        Write-Host "  [ALERTA EL GIRO] Replicas menores a 6. Para el giro de trafico masivo se recomiendan 6 replicas." -ForegroundColor Yellow
    }

    if ($content -match "maxUnavailable:\s*0") {
        Write-Host "  [OK] Estrategia RollingUpdate configurada con maxUnavailable: 0 (Zero-Downtime)." -ForegroundColor Green
    } else {
        Write-Host "  [ALERTA EL GIRO] Se recomienda incluir maxUnavailable: 0 en strategy.rollingUpdate." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Diagnostico finalizado." -ForegroundColor Cyan
