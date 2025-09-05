#!/bin/bash

# Script para gestionar sitios web automáticamente
# Uso: ./manage-sites.sh [update|add|remove] [domain]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SITES_DIR="$PROJECT_DIR/sites"
NGINX_CONFIG_DIR="$PROJECT_DIR/config/nginx/sites"
APACHE_CONFIG_DIR="$PROJECT_DIR/config/apache"
NGINX_TEMPLATE="$PROJECT_DIR/config/nginx/site-template.conf.template"
APACHE_TEMPLATE="$PROJECT_DIR/config/apache/site-template.conf"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Web Manager - Gestor de Sitios Web${NC}"
    echo -e "Uso: $0 [comando] [dominio]"
    echo ""
    echo "Comandos disponibles:"
    echo -e "  ${GREEN}update${NC}     - Actualiza todas las configuraciones basándose en carpetas en sites/"
    echo -e "  ${GREEN}add${NC}        - Añade un nuevo sitio (requiere dominio)"
    echo -e "  ${GREEN}remove${NC}     - Elimina un sitio (requiere dominio)"
    echo -e "  ${GREEN}list${NC}       - Lista todos los sitios configurados"
    echo -e "  ${GREEN}restart${NC}    - Reinicia los servicios Docker"
    echo ""
    echo "Ejemplos:"
    echo "  $0 update"
    echo "  $0 add ejemplo.com"
    echo "  $0 remove ejemplo.com"
}

# Función para generar configuración de nginx
generate_nginx_config() {
    local domain=$1
    local output_file="$NGINX_CONFIG_DIR/${domain}.conf"
    
    if [[ ! -f "$NGINX_TEMPLATE" ]]; then
        echo -e "${RED}Error: Plantilla de nginx no encontrada: $NGINX_TEMPLATE${NC}"
        return 1
    fi
    
    # Crear directorio si no existe
    mkdir -p "$NGINX_CONFIG_DIR"
    
    # Generar configuración reemplazando {{DOMAIN}}
    sed "s/{{DOMAIN}}/$domain/g" "$NGINX_TEMPLATE" > "$output_file"
    
    echo -e "${GREEN}✓${NC} Configuración nginx generada: $output_file"
}

# Función para generar configuración de Apache
generate_apache_config() {
    local domain=$1
    local output_file="$APACHE_CONFIG_DIR/${domain}.conf"
    
    if [[ ! -f "$APACHE_TEMPLATE" ]]; then
        echo -e "${RED}Error: Plantilla de Apache no encontrada: $APACHE_TEMPLATE${NC}"
        return 1
    fi
    
    # Generar configuración reemplazando {{DOMAIN}}
    sed "s/{{DOMAIN}}/$domain/g" "$APACHE_TEMPLATE" > "$output_file"
    
    echo -e "${GREEN}✓${NC} Configuración Apache generada: $output_file"
}

# Función para crear estructura de sitio
create_site_structure() {
    local domain=$1
    local site_dir="$SITES_DIR/$domain"
    
    if [[ ! -d "$site_dir" ]]; then
        mkdir -p "$site_dir"
        
        # Crear archivo index.php de ejemplo
        cat > "$site_dir/index.php" << EOF
<?php
echo "<h1>Bienvenido a $domain</h1>";
echo "<p>Este sitio está funcionando correctamente.</p>";
echo "<p>Servidor: " . \$_SERVER['SERVER_NAME'] . "</p>";
echo "<p>Fecha: " . date('Y-m-d H:i:s') . "</p>";
phpinfo();
?>
EOF
        
        echo -e "${GREEN}✓${NC} Estructura de sitio creada: $site_dir"
    fi
}

# Función para actualizar todas las configuraciones
update_all_sites() {
    echo -e "${BLUE}Actualizando configuraciones de todos los sitios...${NC}"
    
    if [[ ! -d "$SITES_DIR" ]]; then
        echo -e "${YELLOW}Directorio sites no existe, creándolo...${NC}"
        mkdir -p "$SITES_DIR"
        return 0
    fi
    
    local count=0
    for site_dir in "$SITES_DIR"/*/; do
        if [[ -d "$site_dir" ]]; then
            local domain=$(basename "$site_dir")
            echo -e "${YELLOW}Procesando sitio: $domain${NC}"
            
            generate_nginx_config "$domain"
            generate_apache_config "$domain"
            
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No se encontraron sitios en $SITES_DIR${NC}"
    else
        echo -e "${GREEN}✓ $count sitios procesados correctamente${NC}"
    fi
}

# Función para añadir un nuevo sitio
add_site() {
    local domain=$1
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Error: Debe especificar un dominio${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Añadiendo sitio: $domain${NC}"
    
    create_site_structure "$domain"
    generate_nginx_config "$domain"
    generate_apache_config "$domain"
    
    # Habilitar el sitio en Apache
    echo -e "${YELLOW}Habilitando sitio en Apache...${NC}"
    docker exec web-manager-apache a2ensite "$domain" > /dev/null 2>&1
    docker exec web-manager-apache service apache2 reload > /dev/null 2>&1
    
    echo -e "${GREEN}✓ Sitio $domain añadido correctamente${NC}"
    echo -e "${YELLOW}Recuerda reiniciar los servicios con: $0 restart${NC}"
}

# Función para eliminar un sitio
remove_site() {
    local domain=$1
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Error: Debe especificar un dominio${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Eliminando sitio: $domain${NC}"
    
    # Deshabilitar el sitio en Apache
    echo -e "${YELLOW}Deshabilitando sitio en Apache...${NC}"
    docker exec web-manager-apache a2dissite "$domain" > /dev/null 2>&1
    docker exec web-manager-apache service apache2 reload > /dev/null 2>&1
    
    # Eliminar configuraciones
    rm -f "$NGINX_CONFIG_DIR/${domain}.conf"
    rm -f "$APACHE_CONFIG_DIR/${domain}.conf"
    
    echo -e "${GREEN}✓ Configuraciones de $domain eliminadas${NC}"
    echo -e "${YELLOW}Nota: Los archivos del sitio en sites/$domain no se han eliminado${NC}"
    echo -e "${YELLOW}Recuerda reiniciar los servicios con: $0 restart${NC}"
}

# Función para listar sitios
list_sites() {
    echo -e "${BLUE}Sitios configurados:${NC}"
    
    if [[ ! -d "$SITES_DIR" ]]; then
        echo -e "${YELLOW}No hay sitios configurados${NC}"
        return 0
    fi
    
    local count=0
    for site_dir in "$SITES_DIR"/*/; do
        if [[ -d "$site_dir" ]]; then
            local domain=$(basename "$site_dir")
            local nginx_config="$NGINX_CONFIG_DIR/${domain}.conf"
            local apache_config="$APACHE_CONFIG_DIR/${domain}.conf"
            
            echo -n "  • $domain"
            
            if [[ -f "$nginx_config" && -f "$apache_config" ]]; then
                echo -e " ${GREEN}[Configurado]${NC}"
            else
                echo -e " ${RED}[Sin configurar]${NC}"
            fi
            
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No hay sitios en el directorio sites/${NC}"
    fi
}

# Función para reiniciar servicios
restart_services() {
    echo -e "${BLUE}Reiniciando servicios Docker...${NC}"
    
    cd "$PROJECT_DIR"
    
    if docker compose ps >/dev/null 2>&1; then
        docker compose restart
        echo -e "${GREEN}✓ Servicios reiniciados${NC}"
    else
        echo -e "${YELLOW}Los servicios no están ejecutándose. Iniciando...${NC}"
        docker compose up -d
        echo -e "${GREEN}✓ Servicios iniciados${NC}"
    fi
}

# Script principal
case "$1" in
    "update")
        update_all_sites
        ;;
    "add")
        add_site "$2"
        ;;
    "remove")
        remove_site "$2"
        ;;
    "list")
        list_sites
        ;;
    "restart")
        restart_services
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        echo -e "${RED}Comando no reconocido: $1${NC}"
        show_help
        exit 1
        ;;
esac