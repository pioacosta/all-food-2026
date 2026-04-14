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

## Comandos útiles

```bash
flutter pub get
flutter analyze
flutter run
```

## Lista de tareas realizadas

(1)

**Apellidos y nombres:** Acosta Abasto Pio.

**Módulos (objetivos) a desarrollar:**

1. Deploy inicial + base de registro, login y home. | Fecha de inicio de la tarea: 28/03/2026 | Fecha de finalización de la tarea: 28/03/2026
2. Actualización de colores principales (azul -> rojo). Agregar logo e incluirlo en el splash | Fecha de inicio de la tarea: 06/04/2026 | Fecha de finalización de la tarea: 06/04/2026.
3. Ingreso rápido a la pantalla de ingreso (para dueño) y alerta al cerrar sesión. | Fecha de inicio de la tarea: 06/04/2026 | Fecha de finalización de la tarea: 06/04/2026.
4. Creación de la función "alta de empleados" para roles de dueño y supervisor. | Fecha de inicio de la tarea: 10/04/2026 | Fecha de finalización de la tarea: 10/04/2026
5. Actualización del spinner con logo y círculo de carga. | Fecha de inicio de la tarea: 10/04/2026 | Fecha de finalización de la tarea: 10/04/2026
6. Corrección de UI para pantallas de alta de empleados, inicio de sesión y registro. Ahora ocupa mejor los espacios y se eliminó el scroll horizontal. | Fecha de inicio de la tarea: 11/04/2026 | Fecha de finalización de la tarea: 11/04/2026
7. Crear mesas, verlas y editarlas. | Fecha de inicio de la tarea: 11/04/2026 | Fecha de finalización de la tarea: 11/04/2026
8. Ingreso como cliente anónimo. | Fecha de inicio de la tarea: 11/04/2026 | Fecha de finalización de la tarea: 11/04/2026

---

(2)

**Apellidos y nombres:** Lezcano Adrian.

**Módulos (objetivos) a desarrollar:**

1. Splash screen con sus respectivas animaciones (logo a modificar). | Fecha de inicio de la tarea: 31/03/2026 | Fecha de finalización de la tarea: 01/04/2026
2. Implementación de registro cliente con todos sus respectivos datos pendiente de aprobación. | Fecha de inicio de la tarea: 06/04/2026 | Fecha de finalización de la tarea: 07/04/2026
3. Funcionalidad "aceptar/rechazar clientes pendientes" para roles de dueño y supervisor. | Fecha de inicio de la tarea: 10/04/2026 | Fecha de finalización de la tarea: 10/04/2026

---

(3)

**Apellidos y nombres:** Bordón Luciano.

**Módulos (objetivos) a desarrollar:**

1. Icono de la aplicación personalizado. | Fecha de inicio de la tarea: 06/04/2026 | Fecha de finalización de la tarea: 06/04/2026
2. Modularización y alta de producto (alta de platos y bebidas con validación de datos e imágenes). | Fecha de inicio de la tarea: 09/04/2026 | Fecha de finalización de la tarea: 12/04/2026
