![Logo](./assets/images/logo.png)

# All Food

Aplicación móvil para la gestión de restaurante.

## Stack tecnológico

- Flutter
- Supabase

## Estado actual

Base funcional implementada:

- Inicialización de Supabase por variables de entorno
- Splash screen con animaciones + branding en rojo (logo e ícono personalizados)
- Inicio de sesión con validaciones
- Ingreso rápido por perfiles demo (dueño, supervisor, cocinero y cantinero)
- Registro de cliente registrado con foto de cámara, validaciones y estado pendiente de aprobación
- Registro de cliente anónimo con foto de cámara (perfil `cliente_anonimo`, estado `aprobado`)
- Lector QR/PDF417 de DNI para autocompletar datos en los formularios
- Alta de empleados (dueño/supervisor), incluyendo validaciones y carga de foto
- Gestión de clientes pendientes (aceptar/rechazar) para dueño/supervisor
- Home con accesos según rol
- Alta de productos (platos y bebidas) con validaciones e imágenes
- Alta de mesas + visualización/edición de mesas
- Cierre de sesión con feedback visual

## Integrantes

- Luciano Bordón
- Pio Acosta
- Adrián Lezcano

## Índice
* [Splash Screen](#splash-screen)
* [Inicio de Sesión](#inicio-de-sesión)
* [Registrarse](#registrarse)
* [Ingreso Anónimo](#ingreso-anónimo)
* [Accesos Rápidos](#accesos-rápidos)

## Comandos útiles

```bash
flutter pub get
flutter analyze
flutter run
```

## QR de entrada (lista de espera)

Para anotarse en la lista de espera, el cliente debe escanear el QR de entrada.

![QR de entrada]<img src="./assets/images/qrcode.png" width="200"/>

----
## QR Mesas
| Mesa | QR |
|------|----|
| Mesa 1 | <img src="./assets/images/qrMesas/qrMesa1.png" width=""/> |
| Mesa 2 | <img src="./assets/images/qrMesas/qrMesa2.png" width=""/> |
| Mesa 3 | <img src="./assets/images/qrMesas/qrMesa3.png" width=""/> |

# Pantallas de la aplicación

### Splash Screen
<br>
<img src="https://github.com/user-attachments/assets/e57449a8-908e-439f-8d35-cd25e1b530b5" width="250" />

### Inicio de Sesión
<br>
<img src="https://github.com/user-attachments/assets/af372118-965a-412a-827a-1cb9dca1f71a" width="250" />

### Registrarse
<br>
<img src="https://github.com/user-attachments/assets/f8d5505e-4518-4b5b-876a-149dcb907661" width="250" />

### Ingreso Anónimo
<br>
<img src="https://github.com/user-attachments/assets/2e492179-1eef-45c7-b8cf-ab1691aeb1af" width="250" />

### Accesos Rápidos
<br>
<img src="https://github.com/user-attachments/assets/b8028580-2d49-4c86-8c63-9b2b19328570" width="250" />

## Lista de tareas realizadas


| Período | Tarea(s) realizada(s) | Responsable(s) |
|---|---|---|
| 28/03/2026 | Base inicial del proyecto y primer deploy (home, login, registro). | Pio Acosta |
| 31/03/2026 - 06/04/2026 | Estructura por features, splash screen, branding (logo, colores) e ícono personalizado. | Adrian Lezcano, Pio Acosta, Luciano Bordón |
| 06/04/2026 - 07/04/2026 | Registro de usuario con foto y subida a Supabase (incluye spinner). | Adrian Lezcano |
| 09/04/2026 - 12/04/2026 | Alta de empleados (dueño/supervisor), modularización y unificación de formularios de productos/platos/bebidas. | Pio Acosta, Luciano Bordón |
| 10/04/2026 - 12/04/2026 | Gestión de clientes pendientes (aceptar/rechazar), scanner QR de registro y mejoras de UI en registro/login/alta empleado. | Adrian Lezcano, Pio Acosta |
| 11/04/2026 - 15/04/2026 | Gestión de mesas: crear, listar, editar y generación de QR por mesa. | Pio Acosta |
| 14/04/2026 - 17/04/2026 | Flujo de clientes: ingreso anónimo, lista de espera, asignación de mesa por metre y alta de cliente desde metre. | Pio Acosta, Adrian Lezcano |
| 14/04/2026 - 18/04/2026 | Carta de productos (staff y cliente), flujo inicial de pedidos y mejoras de UI/UX de carta y panel mozo. | Luciano Bordón, Pio Acosta |
| 16/04/2026 - 22/04/2026 | Consultas por chat entre cliente y mozo, realtime y mejoras de experiencia en home/carta. | Adrian Lezcano, Pio Acosta |
| 16/04/2026 - 24/04/2026 | Comunicación al cliente: correos de aprobación/rechazo y notificaciones push (registro, mesa, pedidos, pago). | Luciano Bordón |
| 17/04/2026 - 05/05/2026 | Encuestas, cuenta, juegos de descuento y cierre completo del ciclo pedido/mesa. | Pio Acosta, Adrian Lezcano |
| 25/04/2026 - 07/05/2026 | Pulido UX/UI transversal (registro/login/home, mozo/mesas, chat, juegos, flujo cliente). | Pio Acosta, Adrian Lezcano, Luciano Bordón |

# Qr de propinas

| Nivel       | Propina | QR |
|------------|--------|----|
| Excelente  | 20%    | <img src="./assets/images/qrPropina/20%25.png" width="250"/> |
| Muy Bueno  | 15%    | <img src="./assets/images/qrPropina/15%25.png" width="250"/> |
| Bueno      | 10%    | <img src="./assets/images/qrPropina/10%25.png" width="250"/> |
| Regular    | 5%     | <img src="./assets/images/qrPropina/5%25.png" width="250"/> |
| Malo       | 0%     | <img src="./assets/images/qrPropina/0%25.png" width="250"/> |
