#!/bin/bash
# Script de Ayuda y Verificación de Entorno (Bash - Linux / macOS)
# Para ejecutar en Bash: bash ./documentacion/scripts/verificar.sh

echo "=========================================================="
echo "         VERIFICADOR AUTOMATICO DE DIAGNOSTICO            "
echo "=========================================================="
echo ""

# 1. Verificación del Puerto de la Aplicación (Reto 1)
echo "[1/4] Verificando respuesta HTTP de la aplicacion..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "  [OK] La aplicacion responde correctamente en http://localhost:8080 (HTTP 200 OK)"
else
    echo "  [ERROR RETO 1] No hay respuesta en http://localhost:8080"
    echo "  RECOMENDACION: Revisar si server.js escucha en 8080 y si Dockerfile contiene 'EXPOSE 8080'."
fi

echo ""

# 2. Verificación de Endpoints de Kubernetes (Reto 2)
echo "[2/4] Verificando endpoints de Kubernetes..."
if command -v kubectl &> /dev/null; then
    ENDPOINTS=$(kubectl get endpoints web-service -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
    if [ -n "$ENDPOINTS" ]; then
        echo "  [OK] Endpoints de Kubernetes poblados: $ENDPOINTS"
    else
        echo "  [ERROR RETO 2] El servicio 'web-service' no tiene Endpoints asociados (<none>)"
        echo "  RECOMENDACION: Verificar que 'Service.spec.selector.app' sea 'webapp' e igual a 'template.metadata.labels.app'."
    fi
else
    echo "  [INFO] kubectl no esta instalado en este sistema."
fi

echo ""

# 3. Verificación de Pruebas Automatizadas (Reto 3)
echo "[3/4] Verificando ejecucion de pruebas automatizadas..."
if [ -f "package.json" ]; then
    if npm test &> /dev/null; then
        echo "  [OK] Pruebas automatizadas (npm test) pasaron correctamente."
    else
        echo "  [ALERTA RETO 3] Las pruebas fallaron."
        echo "  RECOMENDACION: Asegurar 'needs: build-test' en ci.yml para bloquear el despliegue cuando falle el test."
    fi
fi

echo ""

# 4. Verificación de Réplicas y RollingUpdate (El Giro)
echo "[4/4] Verificando configuracion de alta disponibilidad (El Giro)..."
if [ -f "k8s.yaml" ]; then
    if grep -q "replicas: 6" k8s.yaml; then
        echo "  [OK] Replicas configuradas para alta disponibilidad (6)."
    else
        echo "  [ALERTA EL GIRO] Se recomiendan 6 replicas en k8s.yaml para absorber el triple de trafico."
    fi

    if grep -q "maxUnavailable: 0" k8s.yaml; then
        echo "  [OK] Estrategia RollingUpdate configurada con maxUnavailable: 0 (Zero-Downtime)."
    else
        echo "  [ALERTA EL GIRO] Se recomienda incluir maxUnavailable: 0 en strategy.rollingUpdate."
    fi
fi

echo ""
echo "=========================================================="
echo "Diagnostico finalizado."
