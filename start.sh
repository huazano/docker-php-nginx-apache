#!/bin/bash

# Script de inicio rápido para Web Manager

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Iniciando Web Manager...${NC}"

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker no está instalado. Por favor, instala Docker primero.${NC}"
    exit 1
fi

# Verificar si Docker Compose está disponible
if ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker Compose no está disponible. Por favor, instala Docker Compose primero.${NC}"
    exit 1
fi

# Crear directorios necesarios si no existen
mkdir -p sites config/nginx/sites config/apache logs/nginx logs/apache

# Iniciar servicios
echo -e "${BLUE}📦 Iniciando contenedores Docker...${NC}"
docker compose up -d

# Esperar un momento para que los servicios se inicien
sleep 3

# Mostrar estado
echo -e "${GREEN}✅ Web Manager iniciado correctamente${NC}"
echo ""
echo -e "${BLUE}📋 Comandos útiles:${NC}"
echo -e "  • Añadir sitio:     ${YELLOW}./scripts/manage-sites.sh add ejemplo.com${NC}"
echo -e "  • Actualizar sitios: ${YELLOW}./scripts/manage-sites.sh update${NC}"
echo -e "  • Listar sitios:     ${YELLOW}./scripts/manage-sites.sh list${NC}"
echo -e "  • Ver ayuda:         ${YELLOW}./scripts/manage-sites.sh help${NC}"
echo ""
echo -e "${BLUE}🌐 Para probar, añade una entrada en /etc/hosts:${NC}"
echo -e "  ${YELLOW}127.0.0.1 ejemplo.com${NC}"
echo ""
echo -e "${BLUE}📁 Coloca tus sitios web en la carpeta: ${YELLOW}sites/${NC}"