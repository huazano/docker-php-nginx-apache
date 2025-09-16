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
    echo -e "Uso: $0 [comando] [dominio] [opciones]"
    echo ""
    echo "Comandos disponibles:"
    echo -e "  ${GREEN}update${NC}     - Actualiza todas las configuraciones basándose en carpetas en sites/"
    echo -e "  ${GREEN}add${NC}        - Añade un nuevo sitio (requiere dominio)"
    echo -e "  ${GREEN}remove${NC}     - Elimina un sitio (requiere dominio)"
    echo -e "  ${GREEN}list${NC}       - Lista todos los sitios configurados"
    echo -e "  ${GREEN}restart${NC}    - Reinicia los servicios Docker"
    echo ""
    echo "Opciones para 'add':"
    echo -e "  ${YELLOW}--wordpress${NC} - Instala WordPress automáticamente en el sitio"
    echo -e "  ${YELLOW}--copy-from SITIO${NC} - Crea enlaces simbólicos de plugins desde otro sitio"
    echo ""
    echo "Ejemplos:"
    echo "  $0 update"
    echo "  $0 add ejemplo.com"
    echo "  $0 add ejemplo.com --wordpress"
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
    local install_wordpress=$2
    local site_dir="$SITES_DIR/$domain"
    
    if [[ ! -d "$site_dir" ]]; then
        mkdir -p "$site_dir"
        
        if [[ "$install_wordpress" == "true" ]]; then
            install_wordpress_site "$domain" "$site_dir"
        else
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
        fi
        
        echo -e "${GREEN}✓${NC} Estructura de sitio creada: $site_dir"
    fi
}

# Función para instalar WordPress en un sitio
install_wordpress_site() {
    local domain=$1
    local site_dir=$2
    local wordpress_zip="$PROJECT_DIR/wordpress.zip"
    
    if [[ ! -f "$wordpress_zip" ]]; then
        echo -e "${RED}Error: No se encontró el archivo WordPress en: $wordpress_zip${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Instalando WordPress en $domain...${NC}"
    
    # Descomprimir WordPress en el directorio del sitio
    cd "$site_dir"
    unzip -q "$wordpress_zip"
    
    # Mover archivos de WordPress desde la carpeta wordpress/ al directorio raíz del sitio
    if [[ -d "wordpress" ]]; then
        mv wordpress/* .
        mv wordpress/.[^.]* . 2>/dev/null || true  # Mover archivos ocultos si existen
        rmdir wordpress
        
        # Limpiar plugins y temas no deseados de WordPress (ANTES de cambiar permisos)
        echo -e "${YELLOW}Limpiando plugins y temas innecesarios...${NC}"
        
        # Eliminar plugins no deseados
        rm -rf "$site_dir/wp-content/plugins/akismet" 2>/dev/null || true
        rm -f "$site_dir/wp-content/plugins/hello.php" 2>/dev/null || true
        
        # Eliminar temas no deseados
        rm -rf "$site_dir/wp-content/themes/twentytwentyfour" 2>/dev/null || true
        rm -rf "$site_dir/wp-content/themes/twentytwentythree" 2>/dev/null || true
        
        echo -e "${GREEN}✓${NC} Plugins y temas innecesarios eliminados"
        
        # Crear .htaccess para WordPress
        cat > "$site_dir/.htaccess" << 'EOF'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF
        
        # Establecer permisos correctos para WordPress
        echo -e "${YELLOW}Configurando permisos para Docker (www-data)...${NC}"
        
        # Cambiar propietario a www-data (33:33) para que PHP pueda escribir
        sudo chown -R 33:33 "$site_dir"
        
        # Establecer permisos: directorios 755, archivos 644
        find "$site_dir" -type d -exec chmod 755 {} \;
        find "$site_dir" -type f -exec chmod 644 {} \;
        
        # wp-content necesita permisos de escritura adicionales
        chmod 775 "$site_dir/wp-content"
        chmod 775 "$site_dir/wp-content/themes" 2>/dev/null || true
        chmod 775 "$site_dir/wp-content/plugins" 2>/dev/null || true
        chmod 775 "$site_dir/wp-content/uploads" 2>/dev/null || true
        
        # Crear directorio uploads si no existe
        mkdir -p "$site_dir/wp-content/uploads"
        chmod 775 "$site_dir/wp-content/uploads"
        chown 33:33 "$site_dir/wp-content/uploads"
        
        # Enlazar plugin bahez desde wgp.wp.local
        local base_site="$SITES_DIR/wgp.wp.local"
        if [[ -d "$base_site/wp-content/plugins/bahez" ]]; then
            echo -e "${YELLOW}Enlazando plugin bahez desde wgp.wp.local...${NC}"
            sudo ln -sf "../../../wgp.wp.local/wp-content/plugins/bahez" "$site_dir/wp-content/plugins/bahez"
            echo -e "${GREEN}✓${NC} Plugin bahez enlazado simbólicamente"
        fi
        
        echo -e "${GREEN}✓${NC} WordPress instalado en $domain"
        echo -e "${GREEN}✓${NC} .htaccess creado automáticamente"
        echo -e "${GREEN}✓${NC} Permisos configurados para Docker (www-data)"
    else
        echo -e "${RED}Error: No se pudo descomprimir WordPress correctamente${NC}"
        return 1
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
    local install_wordpress="false"
    
    # Verificar opciones adicionales
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            --wordpress)
                install_wordpress="true"
                shift
                ;;
            *)
                echo -e "${RED}Error: Opción desconocida: $1${NC}"
                return 1
                ;;
        esac
    done
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Error: Debe especificar un dominio${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Añadiendo sitio: $domain${NC}"
    if [[ "$install_wordpress" == "true" ]]; then
        echo -e "${BLUE}Con instalación de WordPress${NC}"
    fi
    
    create_site_structure "$domain" "$install_wordpress"
    generate_nginx_config "$domain"
    generate_apache_config "$domain"
    
    # Habilitar el sitio en Apache
    echo -e "${YELLOW}Habilitando sitio en Apache...${NC}"
    docker exec web-manager-apache a2ensite "$domain" > /dev/null 2>&1
    docker exec web-manager-apache service apache2 reload > /dev/null 2>&1
    
    echo -e "${GREEN}✓ Sitio $domain añadido correctamente${NC}"
    if [[ "$install_wordpress" == "true" ]]; then
        echo -e "${GREEN}✓ WordPress instalado en $domain${NC}"
    fi
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
        shift
        add_site "$@"
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