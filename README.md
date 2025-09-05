# Web Manager - Gestor de Sitios Web

Un sistema de gestión de sitios web similar a Plesk que utiliza nginx como proxy reverso y Apache para servir contenido PHP dinámico, aprovechando lo mejor de ambos mundos.

## 🚀 Características

- **Nginx como Proxy Reverso**: Maneja archivos estáticos de forma eficiente
- **Apache + PHP-FPM**: Procesa contenido PHP dinámico de manera óptima
- **Gestión Automática**: Script que genera configuraciones automáticamente
- **Múltiples Sitios**: Soporte para múltiples dominios en un solo servidor
- **Fácil de Usar**: Comandos simples para gestionar sitios

## 📋 Requisitos

- Docker
- Docker Compose
- Sistema Linux/macOS (o WSL en Windows)

## 🛠️ Instalación

1. **Clonar o descargar el proyecto**:
   ```bash
   git clone <tu-repositorio>
   cd docker-php-nginx-apache
   ```

2. **Hacer ejecutables los scripts** (si es necesario):
   ```bash
   chmod +x start.sh scripts/manage-sites.sh
   ```

3. **Iniciar el sistema**:
   ```bash
   ./start.sh
   ```

## 📖 Uso

### Comandos Principales

```bash
# Ver ayuda
./scripts/manage-sites.sh help

# Añadir un nuevo sitio
./scripts/manage-sites.sh add ejemplo.com

# Actualizar todas las configuraciones
./scripts/manage-sites.sh update

# Listar sitios configurados
./scripts/manage-sites.sh list

# Eliminar un sitio
./scripts/manage-sites.sh remove ejemplo.com

# Reiniciar servicios
./scripts/manage-sites.sh restart
```

### Flujo de Trabajo Típico

1. **Añadir un nuevo sitio**:
   ```bash
   ./scripts/manage-sites.sh add midominio.com
   ```

2. **Subir archivos del sitio**:
   - Coloca los archivos de tu sitio web en `sites/midominio.com/`
   - El sistema creará automáticamente un `index.php` de ejemplo

3. **Configurar DNS local** (para pruebas):
   ```bash
   echo "127.0.0.1 midominio.com" | sudo tee -a /etc/hosts
   ```

4. **Acceder al sitio**:
   - Abre tu navegador y ve a `http://midominio.com`

## 📁 Estructura del Proyecto

```
docker-php-nginx-apache/
├── sites/                          # Directorio de sitios web
│   └── ejemplo.com/               # Cada sitio en su carpeta
│       └── index.php
├── config/
│   ├── nginx/
│   │   ├── default.conf           # Configuración principal nginx
│   │   ├── site-template.conf     # Plantilla para sitios
│   │   └── sites/                 # Configuraciones generadas
│   └── apache/
│       └── site-template.conf     # Plantilla Apache
├── scripts/
│   └── manage-sites.sh            # Script principal de gestión
├── logs/                          # Logs de nginx y apache
├── docker-compose.yml             # Configuración Docker
├── start.sh                       # Script de inicio rápido
└── README.md                      # Esta documentación
```

## 🔧 Configuración Avanzada

### Personalizar Plantillas

Puedes modificar las plantillas en:
- `config/nginx/site-template.conf` - Para configuración de nginx
- `config/apache/site-template.conf` - Para configuración de Apache

Después de modificar las plantillas, ejecuta:
```bash
./scripts/manage-sites.sh update
./scripts/manage-sites.sh restart
```

### Variables de Plantilla

Las plantillas utilizan la variable `{{DOMAIN}}` que se reemplaza automáticamente por el nombre del dominio.

### Logs

Los logs se almacenan en:
- `logs/nginx/` - Logs de nginx
- `logs/apache/` - Logs de Apache

## 🌐 Arquitectura

```
Cliente → Nginx (Puerto 80) → Apache (Puerto interno) → PHP-FPM
```

- **Nginx**: Recibe todas las peticiones, sirve archivos estáticos directamente
- **Apache**: Procesa PHP y contenido dinámico
- **PHP-FPM**: Motor PHP optimizado para alto rendimiento

## 🔍 Solución de Problemas

### El sitio no carga
1. Verifica que los servicios estén ejecutándose:
   ```bash
   docker-compose ps
   ```

2. Revisa los logs:
   ```bash
   docker-compose logs nginx
   docker-compose logs apache
   ```

3. Verifica la configuración DNS:
   ```bash
   ping midominio.com
   ```

### Reiniciar completamente
```bash
docker-compose down
docker-compose up -d
```

### Ver logs en tiempo real
```bash
docker-compose logs -f
```

## 📝 Ejemplos

### Sitio PHP Simple

Crea `sites/ejemplo.com/index.php`:
```php
<?php
echo "<h1>Mi Sitio Web</h1>";
echo "<p>Servidor: " . $_SERVER['SERVER_NAME'] . "</p>";
?>
```

### Sitio con WordPress

1. Descarga WordPress en `sites/miwordpress.com/`
2. Añade el sitio: `./scripts/manage-sites.sh add miwordpress.com`
3. Configura la base de datos según necesites

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

## 🆘 Soporte

Si tienes problemas o preguntas:
1. Revisa la documentación
2. Busca en los issues existentes
3. Crea un nuevo issue con detalles del problema

---

**¡Disfruta gestionando tus sitios web de manera fácil y eficiente!** 🎉