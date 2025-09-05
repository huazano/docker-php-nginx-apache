<?php
/**
 * Configuración personalizada de phpMyAdmin para resolver problemas con proxy
 */

// Configuración para trabajar detrás de un proxy
$cfg['PmaAbsoluteUri'] = 'http://phpmyadmin.local/';

// Configuración de cookies para trabajar con proxy
$cfg['blowfish_secret'] = 'phpMyAdminSecretKey123456789012345678901234567890';
$cfg['SessionSavePath'] = '/tmp';
$cfg['CheckConfigurationPermissions'] = false;

// Configuración del servidor MySQL
$cfg['Servers'][1]['host'] = 'mysql';
$cfg['Servers'][1]['port'] = '3306';
$cfg['Servers'][1]['auth_type'] = 'cookie';
$cfg['Servers'][1]['user'] = '';
$cfg['Servers'][1]['password'] = '';
$cfg['Servers'][1]['AllowNoPassword'] = false;

// Configuraciones adicionales para mejorar la compatibilidad
$cfg['DefaultLang'] = 'en';
$cfg['ServerDefault'] = 1;
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';

// Configuración para evitar problemas de cookies
$cfg['LoginCookieValidity'] = 1440;
$cfg['LoginCookieStore'] = 0;
$cfg['LoginCookieDeleteAll'] = true;

// Configuración de seguridad
$cfg['ForceSSL'] = false;
$cfg['TrustedProxies'] = array('nginx');

?>