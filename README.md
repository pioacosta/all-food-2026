![Logo](./assets/images/logo.png)

# All Food

Aplicación móvil para la gestión de restaurante.

## Stack tecnológico

- Flutter
- Supabase

## Integrantes

- Luciano Bordón
- Pio Acosta
- Adrián Lezcano

## Índice

* [QR de entrada (lista de espera)](#qr-de-entrada-lista-de-espera)
* [QR Mesas](#qr-mesas)

* [Pantallas de la aplicación](#pantallas-de-la-aplicación)
  * [Splash Screen](#splash-screen)
  * [Inicio de Sesión](#inicio-de-sesión)
  * [Registrarse](#registrarse)
  * [Ingreso Anónimo](#ingreso-anónimo)
  * [Accesos Rápidos](#accesos-rápidos)

* [Cliente Registrado](#cliente-registrado)
  * [Inicio del flujo de cliente registrado](#inicio-del-flujo-de-cliente-registrado)
  * [QR de entrada escaneado con éxito](#qr-de-entrada-escaneado-con-éxito)
  * [Gráficos de encuestas](#gráficos-de-encuestas)
  * [Solicitud de mesa enviada](#solicitud-de-mesa-enviada)
  * [Mesa asignada](#mesa-asignada)
  * [Mesa validada estado: Sin pedido](#mesa-validada-estado-sin-pedido)
  * [Carta de productos](#carta-de-productos)
  * [Detalle del producto](#detalle-del-producto)
  * [Slide de imágenes del producto](#slide-de-imagenes-del-producto)
  * [Chat de consultas al mozo](#chat-de-consultas-al-mozo)
  * [Enviar pedido al mozo](#enviar-pedido-al-mozo)
  * [Mesa validada estado: Pedido confirmado por mozo](#mesa-validada-estado--pedido-confirmado-por-mozo)
  * [Juegos y descuentos](#juegos-y-descuentos)
  * [Juego: Adiviná el número](#juego-adiviná-el-numero)
  * [Juego: Comidas y Bombas](#juego-comidas-y-bombas)
  * [Juego: Snake](#juego-snake)
  * [Sala de juegos con 20 porciento de descuento aplicado](#sala-de-juegos-con-20-porciento-de-descuento-aplicado)
  * [Mesa validada estado: Recibido](#mesa-validada-estado-recibido)
  * [Completar encuesta](#completar-encuesta)
  * [Cuenta solicitada y QR de propina BUENA escaneado](#cuenta-solicitada-y-qr-de-propina-buena-escaneado)
  * [Pago pendiente de confirmación, pago confirmado y mesa liberada](#pago-pediente-de-confirmación-pago-confirmado-y-mesa-liberada)

* [STAFF](#staff)

  * [Dueño / Supervisor](#dueño--supervisor)
    * [Home Dueño](#home-dueño)
    * [Home Supervisor](#home-supervisor)
    * [Alta de empleados](#alta-de-empleados)
    * [Alta de mesa](#alta-de-mesa)
    * [Clientes pendientes](#clientes-pendientes)

  * [Metre](#metre)
    * [Home Metre](#home-metre)
    * [Ver y editar mesas](#ver-y-editar-mesas)
    * [Asignar mesa](#asignar-mesa)
    * [Asignar mesa - confirmación](#asignar-mesa---confirmación)
    * [Alta de clientes](#alta-de-clientes)

  * [Mozo](#mozo)
    * [Home Mozo](#home-mozo)
    * [Consultas de clientes](#consultas-de-clientes)
    * [Chat mozo-cliente](#chat-mozo-cliente)
    * [Gestión de pedidos pendientes](#gestión-de-pedidos-pendientes)
    * [Detalle del pedido](#detalle-del-pedido)
    * [Gestión de pedidos listos](#gestión-de-pedidos-listos)
    * [Gestión de pagos](#gestión-de-pagos)
    * [Detalle de cuenta](#detalle-de-cuenta)

  * [Cocinero](#cocinero)
    * [Home Cocinero](#home-cocinero)
    * [Listado de pedidos - Cocina](#listado-de-pedidos---cocina)
    * [Alta de productos](#alta-de-productos)

  * [Cantinero](#cantinero)
    * [Home Cantinero](#home-cantinero)
    * [Listado de pedidos - Bar](#listado-de-pedidos---bar)

* [Lista de tareas realizadas](#lista-de-tareas-realizadas)
* [QR de propinas](#qr-de-propinas)

## Comandos útiles

```bash
flutter pub get
flutter analyze
flutter run
```

## QR de entrada (lista de espera)

Para anotarse en la lista de espera, el cliente debe escanear el QR de entrada.

<img src="./assets/images/qrcode.png" alt="QR de entrada" width="200"/>

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

# Cliente Registrado

### Inicio del flujo de cliente registrado
<img src="https://github.com/user-attachments/assets/4f58db0a-f7f7-4643-84c5-41a51e44ac44" width="250" />

### QR de entrada escaneado con éxito
<br>
<img src="https://github.com/user-attachments/assets/05b7ebe1-6ed5-44a3-9f34-e9b437ff01d1" width="250" />

### Gráficos de encuestas
<br>
<img src="https://github.com/user-attachments/assets/0420fff9-a8d3-4c31-adc7-7b739302ebe1" width="250" />
<br>
<img src="https://github.com/user-attachments/assets/48017a70-4cf1-482d-8b5f-05a3eb4c7e67" width="250" />
<br>
<img src="https://github.com/user-attachments/assets/ced4f967-2070-4ca3-b76a-e29d8069921d" width="250" />
<br>

### Solicitud de mesa enviada
<br>
<img src="https://github.com/user-attachments/assets/82a3774c-6705-4d28-81df-303b2cbdbdc2" width="250" />

### Mesa asignada
<br>
<img src="https://github.com/user-attachments/assets/3c14dd46-0608-4a90-9646-c133e0221902" width="250" />

### Mesa validada estado: Sin pedido
<br>
<img src="https://github.com/user-attachments/assets/b271f6e2-be39-4402-ad49-f083de307922" width="250" />

### Carta de productos
<br>
<img src="https://github.com/user-attachments/assets/7aaca026-5cf1-421c-8f80-7bb8ff6cfc97" width="250" />

### Detalle del producto
<br>
<img src="https://github.com/user-attachments/assets/bbd9635d-b01c-440c-a624-20ce4051bb62" width="250" />

### Slide de imagenes del producto
<br>
<img src="https://github.com/user-attachments/assets/4837c321-6f0c-453a-b10a-eaaee488ebd8" width="250" />

### Chat de consultas al mozo
<br>
<img src="https://github.com/user-attachments/assets/4e9bd2f1-5352-4264-a894-33e33b12df25" width="250" />

### Enviar pedido al mozo 
<br>
<img src="https://github.com/user-attachments/assets/97ccec42-40de-4116-a2a3-1a42efdc1992" width="250" />

### Mesa validada estado : Pedido confirmado por mozo
<br>
<img src="https://github.com/user-attachments/assets/50bd8614-43fd-41fd-9ab8-889c6f795359" width="250" />

### Juegos y descuentos
<br>
<img src="https://github.com/user-attachments/assets/46a81587-db55-4f72-9b72-e494cc083add" width="250" />

### Juego: Adiviná el numero
<br>
Modal de explicación
<br>
<img src="https://github.com/user-attachments/assets/53350a20-0c5e-4a8a-a054-6b375be2c014" width="250"/>
<br>
Juego:
<br>
<img src="https://github.com/user-attachments/assets/85e53e63-a32f-4abf-87bc-b2921d7cf748" width="250" />

### Juego: Comidas y Bombas
<br>
Modal de explicación
<br>
<img src="https://github.com/user-attachments/assets/388bb867-5bb1-4b2f-8a5e-586358a2e372" width="250"/>
<br>
Juego:
<br>
<img src="https://github.com/user-attachments/assets/8bd598b9-bb5d-4cb3-8b34-cbe435abec86" width="250"/>

### Juego: Snake
<br>
Modale de explicación
<br>
<img src="https://github.com/user-attachments/assets/fcf07c0c-a5d0-4c5f-8aa2-ece1e9be6a68" width="250"/>
<br>
Juego:
<br>
<img src="https://github.com/user-attachments/assets/0d7a7f14-626e-4e31-8b60-8c0e990b5bde" width="250"/>

### Sala de juegos con 20 porciento de descuento aplicado
<br>
<img src="https://github.com/user-attachments/assets/8947f8cf-9c5d-4e0d-a659-50b265670a52" width="250" />

### Mesa validada estado: Recibido 
<br>
<img src="https://github.com/user-attachments/assets/763fb1ac-afa9-4736-8a8a-2de737c71c39" width="250"/>

### Completar encuesta
<br>
<img src="https://github.com/user-attachments/assets/ac0c17d8-a84d-4587-b918-1c48de41501b" width="250" />

### Cuenta solicitada y QR de propina BUENA escaneado
<br>
<img src="https://github.com/user-attachments/assets/286c6f1a-3067-42c9-a93a-8cadcfd3135f" width="250"/>

### Pago pediente de confirmación, pago confirmado y mesa liberada
<br>
<img src="https://github.com/user-attachments/assets/7b92f7f3-aa9b-4ee7-b51b-3fb6a0559036" width="250" />
<br>
<img src="https://github.com/user-attachments/assets/a821c912-eef8-45ea-ab30-05b90ccfc13e" width="250" />
<br>
[⬆ Volver al índice](#índice)

# STAFF

## Dueño / Supervisor

### Home Dueño
<br>
<img src="https://github.com/user-attachments/assets/41538a8a-a46c-475b-bb16-5bf416956ff5" width="250" />

### Home Supervisor
<br>
<img src="https://github.com/user-attachments/assets/50abc53c-f28c-43a6-b118-9567dfaacc91" width="250" />

### Alta de empleados
<br>
<img src="https://github.com/user-attachments/assets/a2daa151-9b55-4adb-93b7-e443a542fcdc" width="250" />

### Alta de mesa
<br>
<img src="https://github.com/user-attachments/assets/7a5582d6-01a1-4be2-8329-6dc9717af4b8" width="250" />

### Clientes pendientes
<br>
<img src="https://github.com/user-attachments/assets/9b87aeed-7f7f-423c-8610-b0eb8a7bccc8" width="250" />
<br>
<br>
[⬆ Volver al índice](#índice)

---

## Metre

### Home Metre
<br>
<img src="https://github.com/user-attachments/assets/1386f4ab-9477-4a21-b2ce-f80008b9ef2b" width="250" />

### Ver y editar mesas
(Dueño y Supervisor también pueden acceder)
<br>
<img src="https://github.com/user-attachments/assets/7fe0d0b3-2256-4950-b37b-1c1ebd60d4fe" width="250" />

### Asignar mesa
<br>
<img src="https://github.com/user-attachments/assets/2c5bf12c-2064-40a0-ae0b-71a4b4c8375f" width="250" />

### Asignar mesa - confirmación
<br>
<img src="https://github.com/user-attachments/assets/11a22b8d-0574-403b-a352-1f4ddf04903a" width="250" />

### Alta de clientes
<br>
<img src="https://github.com/user-attachments/assets/409226e0-7f56-4e7f-96cb-e7826f0fc63e" width="250" />
<br>
[⬆ Volver al índice](#índice)

---

## Mozo

### Home Mozo
<br>
<img src="https://github.com/user-attachments/assets/f17bd87e-df28-4e32-9e14-363b31a293dd" width="250" />

### Consultas de clientes
<br>
<img src="https://github.com/user-attachments/assets/05eb1f95-96a2-4bd4-9c00-0b8c02abe5a0" width="250" />

### Chat mozo-cliente
<br>
<img src="https://github.com/user-attachments/assets/929fa1d3-879a-48dc-9c8c-4960b8ae4cb1" width="250" />

### Gestión de pedidos pendientes
<br>
<img src="https://github.com/user-attachments/assets/593d3832-fe04-402e-bd5a-62ccef20e6e7" width="250" />

### Detalle del pedido
<br>
<img src="https://github.com/user-attachments/assets/254cb322-ff5b-4794-b218-e80fd82f2da1" width="250" />

### Gestión de pedidos listos
<br>
<img src="https://github.com/user-attachments/assets/be04b6ef-a205-4d14-b756-436c8999a47b" width="250" />

### Gestión de pagos
<br>
<img src="https://github.com/user-attachments/assets/9541db4a-ce71-47eb-a979-37f62e501e68" width="250" />

### Detalle de cuenta
<br>
<img src="https://github.com/user-attachments/assets/0d0884aa-1e7d-4e8f-a80f-b20300724d95" width="250" />
<br>
[⬆ Volver al índice](#índice)

---

## Cocinero

### Home Cocinero
<br>
<img src="https://github.com/user-attachments/assets/4299318c-0870-4b8a-ad42-e4527d0c4c43" width="250" />

### Listado de pedidos - Cocina
<br>
<img src="https://github.com/user-attachments/assets/81777ad8-33ad-40c4-8441-36db3c387106" width="250" />

### Alta de productos
(Compartido con Cantinero)
<br>
<img src="https://github.com/user-attachments/assets/87bcf2a9-45cb-417a-98af-63a8ba3f1810" width="250" />
<br>
[⬆ Volver al índice](#índice)

---

## Cantinero

### Home Cantinero
<br>
<img src="https://github.com/user-attachments/assets/9ea4cb85-658b-44f1-8901-0ea97e9862e5" width="250" />

### Listado de pedidos - Bar
<br>
<img src="https://github.com/user-attachments/assets/f8d0b9f4-4405-4182-8a4c-c8c56af01928" width="250" />
<br>
[⬆ Volver al índice](#índice)

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
