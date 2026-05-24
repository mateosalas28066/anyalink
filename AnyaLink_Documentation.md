# AnyaLink IoT Platform
## Documentación Técnica del Proyecto

---

**Autor:** Mateo Salas  
**Fecha:** Noviembre 2025
**Versión:** 1.0

---

## Tabla de Contenidos

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Descripción del Proyecto](#2-descripción-del-proyecto)
3. [Arquitectura del Sistema](#3-arquitectura-del-sistema)
4. [Stack Tecnológico](#4-stack-tecnológico)
5. [Modelo de Datos](#5-modelo-de-datos)
6. [Autenticación y Seguridad](#6-autenticación-y-seguridad)
7. [Características Principales](#7-características-principales)
8. [Flujos de Trabajo](#8-flujos-de-trabajo)
9. [Integración y Comunicación](#9-integración-y-comunicación)
10. [Metodología de Desarrollo](#10-metodología-de-desarrollo)
11. [Despliegue e Infraestructura](#11-despliegue-e-infraestructura)
12. [Conclusiones y Trabajo Futuro](#12-conclusiones-y-trabajo-futuro)

---

## 1. Resumen Ejecutivo

**AnyaLink** es una plataforma integral de gestión y control de dispositivos IoT que permite a usuarios administrar dispositivos remotos a través de una aplicación móvil desarrollada en Flutter, respaldada por Supabase como Backend-as-a-Service (BaaS) y Node-RED como motor de automatización.

### Objetivos del Proyecto

- Proporcionar una interfaz móvil intuitiva para control remoto de dispositivos IoT
- Implementar un sistema robusto de control de acceso basado en roles (RBAC)
- Facilitar la automatización mediante rutinas programables por el usuario
- Garantizar la seguridad y trazabilidad mediante registro de actividades
- Ofrecer una experiencia de usuario moderna con soporte para modo oscuro

### Alcance

El sistema soporta múltiples tipos de dispositivos IoT incluyendo luces, pantallas LCD, dispensadores y cámaras, con capacidad para gestionar asignaciones de dispositivos, solicitudes de acceso, y automatizaciones personalizadas.

---

## 2. Descripción del Proyecto

### 2.1 Problemática

La gestión de dispositivos IoT en entornos domésticos o institucionales presenta desafíos relacionados con:

- **Control de Acceso:** Necesidad de restringir el acceso a dispositivos según roles de usuario
- **Automatización:** Requerimiento de programar acciones automáticas sin conocimientos técnicos avanzados
- **Trazabilidad:** Importancia de registrar quién realizó cada acción y cuándo
- **Concurrencia:** Prevención de conflictos cuando múltiples usuarios intentan controlar el mismo dispositivo

### 2.2 Solución Propuesta

AnyaLink implementa una arquitectura de tres capas (Cliente - Servidor - Dispositivos) que:

1. **Capa de Presentación (Flutter):** Aplicación móvil con interfaz responsive y moderna
2. **Capa de Lógica de Negocio (Supabase + Node-RED):** Backend serverless con automatización
3. **Capa de Dispositivos (ESP32 + MQTT):** Microcontroladores conectados vía protocolo MQTT

### 2.3 Beneficiarios

- **Administradores:** Control total sobre dispositivos, usuarios y permisos
- **Usuarios Invitados:** Acceso controlado a dispositivos asignados
- **Desarrolladores IoT:** Marco extensible para agregar nuevos tipos de dispositivos

---

## 3. Arquitectura del Sistema

### 3.1 Arquitectura General

El sistema sigue un patrón de arquitectura **Cliente-Servidor con Mensajería Asíncrona**:

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                      │
│                    (Flutter Mobile App)                       │
│  - UI/UX Material 3                                          │
│  - Gestión de Estado (Riverpod)                              │
│  - Autenticación Local                                       │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS/REST
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  CAPA DE BACKEND (Supabase)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ PostgreSQL   │  │ Auth Service │  │   Realtime   │      │
│  │  Database    │  │   (GoTrue)   │  │  Websockets  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌────────────────────────────────────────────────┐         │
│  │     Row-Level Security (RLS) Policies          │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────────┬──────────────────────────────────┘
                           │ Polling/Webhooks
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              CAPA DE AUTOMATIZACIÓN (Node-RED)               │
│  - Flujos de Trabajo Visuales                               │
│  - Integración Supabase                                      │
│  - Lógica de Rutinas                                         │
└──────────────────────────┬──────────────────────────────────┘
                           │ MQTT Protocol
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  MQTT BROKER (Mosquitto)                     │
│  - Pub/Sub Messaging                                         │
│  - QoS Management                                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│               CAPA DE DISPOSITIVOS (ESP32)                   │
│  - Microcontroladores                                        │
│  - Sensores y Actuadores                                     │
│  - MQTT Client                                               │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Patrones de Diseño Implementados

#### 3.2.1 Repository Pattern
Abstracción de la capa de datos mediante repositorios que encapsulan la lógica de acceso a Supabase:
- `DeviceRepository`: Gestión de dispositivos
- `RequestRepository`: Solicitudes de acceso
- `RoutinesRepository`: Automatizaciones
- `ActivityLogsRepository`: Auditoría

#### 3.2.2 Provider Pattern
Gestión de estado global reactivo mediante Riverpod:
- Estado de autenticación
- Estado de dispositivos
- Estado de tema (dark mode)
- Caché de datos

#### 3.2.3 Observer Pattern
Actualización en tiempo real mediante:
- Supabase Realtime (WebSockets)
- Polling como fallback

### 3.3 Decisiones Arquitectónicas Clave

| Decisión | Justificación |
|----------|---------------|
| **Backend Serverless (Supabase)** | Reduce costos operativos, escalabilidad automática, menor tiempo de desarrollo |
| **Flutter para Mobile** | Código compartido iOS/Android, rendimiento nativo, ecosistema maduro |
| **Node-RED para Automatización** | Desarrollo visual, fácil integración con MQTT, amplia comunidad |
| **MQTT como Protocolo IoT** | Bajo consumo, ideal para dispositivos con recursos limitados, pub/sub nativo |
| **PostgreSQL como BD** | Robustez, ACID, soporte nativo de JSON, consultas complejas |

---

## 4. Stack Tecnológico

### 4.1 Frontend (Aplicación Móvil)

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Flutter** | 3.0+ | Framework UI multiplataforma |
| **Dart** | 3.0+ | Lenguaje de programación |
| **Riverpod** | 2.x | Gestión de estado reactivo |
| **Supabase Flutter SDK** | - | Cliente Supabase |
| **Geolocator** | - | Servicios de ubicación |
| **SharedPreferences** | - | Almacenamiento local persistente |

**Características de la Implementación Frontend:**
- Arquitectura limpia separando presentación, dominio e infraestructura
- Widgets reutilizables con diseño atómico
- Theming dinámico (Material 3)
- Gestión de rutas mediante Navigator 2.0

### 4.2 Backend (Supabase)

| Componente | Tecnología | Función |
|------------|------------|---------|
| **Base de Datos** | PostgreSQL 15 | Almacenamiento principal |
| **Autenticación** | GoTrue | Gestión de usuarios |
| **API REST** | PostgREST | API automática sobre PostgreSQL |
| **Realtime** | Phoenix Channels | Actualizaciones en tiempo real |
| **Storage** | S3-compatible | Almacenamiento de archivos (futuro) |

**Características del Backend:**
- Row-Level Security (RLS) para seguridad a nivel de fila
- Funciones PostgreSQL para lógica de negocio compleja
- Triggers para sincronización de datos
- Índices optimizados para consultas frecuentes

### 4.3 Automatización y Middleware

| Tecnología | Versión | Uso |
|------------|---------|-----|
| **Node-RED** | 3.x | Motor de automatización |
| **MQTT Broker** | Mosquitto 2.x | Mensajería IoT |
| **HTTP Request Nodes** | - | Integración con Supabase |

### 4.4 Dispositivos IoT

| Componente | Especificación |
|------------|----------------|
| **Microcontrolador** | ESP32 (WiFi + Bluetooth) |
| **Protocolo** | MQTT v3.1.1 |
| **Bibliotecas** | PubSubClient, WiFi |

---

## 5. Modelo de Datos

### 5.1 Diagrama Entidad-Relación

```
┌──────────────┐         ┌──────────────┐
│   auth.users │◄────────│   profiles   │
└──────────────┘         │              │
                         │ - id         │
                         │ - role       │
                         │ - email      │
                         └──────┬───────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
            ┌───────▼──────┐        ┌──────▼─────────┐
            │user_devices  │        │device_requests │
            │              │        │                │
            │- user_id     │        │- user_id       │
            │- device_id   │        │- status        │
            └──────┬───────┘        │- target_device │
                   │                └────────────────┘
                   │
            ┌──────▼──────┐
            │   devices   │
            │             │
            │- id         │
            │- alias      │
            │- type       │
            │- state      │
            │- message    │
            │- locked_by  │
            └──────┬──────┘
                   │
        ┌──────────┴──────────┐
        │                     │
┌───────▼──────┐      ┌───────▼─────────┐
│   routines   │      │  activity_logs  │
│              │      │                 │
│- device_id   │      │- device_id      │
│- user_id     │      │- user_id        │
│- action_type │      │- action_type    │
│- interval    │      │- action_value   │
│- enabled     │      │- source         │
└──────────────┘      │- created_at     │
                      └─────────────────┘
```

### 5.2 Descripción de Entidades Principales

#### 5.2.1 Profiles
Extiende la tabla de autenticación con información adicional del usuario.

**Atributos:**
- `id` (PK, UUID): Identificador único vinculado a auth.users
- `role` (TEXT): Rol del usuario ('admin' | 'guest')
- `email` (TEXT): Email sincronizado desde auth.users
- `created_at` (TIMESTAMPTZ): Fecha de creación

**RLS Policies:**
- Los usuarios solo pueden leer su propio perfil
- Los administradores pueden leer todos los perfiles

#### 5.2.2 Devices
Registro de todos los dispositivos IoT en el sistema.

**Atributos:**
- `id` (PK, UUID): Identificador único del dispositivo
- `alias` (TEXT, UNIQUE): Nombre amigable
- `type` (TEXT): Tipo de dispositivo ('light', 'screen', 'dispenser', 'camera')
- `state` (BOOLEAN): Estado ON/OFF
- `message` (TEXT): Mensaje para pantallas LCD
- `locked_by` (UUID, FK): Usuario que bloqueó el dispositivo (concurrencia)
- `locked_at` (TIMESTAMPTZ): Momento del bloqueo
- `updated_at` (TIMESTAMPTZ): Última actualización

**Índices:**
- Índice único en `alias`
- Índice en `type` para consultas filtradas

#### 5.2.3 User_Devices
Relación muchos-a-muchos entre usuarios y dispositivos asignados.

**Atributos:**
- `user_id` (FK → profiles.id)
- `device_id` (FK → devices.id)
- `assigned_at` (TIMESTAMPTZ)

**Constraint:** PRIMARY KEY (user_id, device_id)

#### 5.2.4 Device_Requests
Solicitudes de acceso a dispositivos por parte de invitados.

**Atributos:**
- `id` (PK, UUID)
- `user_id` (FK → profiles.id)
- `device_type` (TEXT): Tipo de dispositivo solicitado
- `target_device_id` (UUID, FK → devices.id, NULLABLE): Dispositivo específico (opcional)
- `status` (TEXT): Estado ('pending', 'accepted', 'rejected')
- `reason` (TEXT): Motivo opcional
- `created_at` (TIMESTAMPTZ)

#### 5.2.5 Routines
Automatizaciones definidas por usuarios.

**Atributos:**
- `id` (PK, UUID)
- `user_id` (FK → profiles.id)
- `device_id` (FK → devices.id)
- `action_type` (TEXT): 'set_state' | 'set_message'
- `action_payload` (TEXT): Valor de la acción
- `interval_seconds` (INTEGER): Intervalo de ejecución
- `enabled` (BOOLEAN): Activo/Inactivo
- `last_run_at` (TIMESTAMPTZ): Última ejecución
- `expires_at` (TIMESTAMPTZ): Expiración automática
- `created_at` (TIMESTAMPTZ)

**Lógica de Negocio:**
- Las rutinas expiran automáticamente después de 1 hora (configurable)
- Node-RED verifica `NOW() - last_run_at >= interval_seconds` antes de ejecutar

#### 5.2.6 Activity_Logs
Registro de auditoría de todas las acciones sobre dispositivos.

**Atributos:**
- `id` (PK, UUID)
- `user_id` (FK → profiles.id, NULLABLE): Usuario que realizó la acción (NULL si es sistema)
- `device_id` (FK → devices.id)
- `action_type` (TEXT): 'state_change' | 'message_update'
- `action_value` (TEXT): Valor resultante
- `source` (TEXT): Origen ('user', 'routine', 'system')
- `created_at` (TIMESTAMPTZ)

**Índices de Performance:**
- Índice descendente en `created_at` para consultas recientes
- Índice en `device_id` para filtrado

---

## 6. Autenticación y Seguridad

### 6.1 Sistema de Autenticación

**Proveedor:** Supabase Auth (GoTrue)

**Métodos Soportados:**
- Email/Contraseña (implementado)
- Proveedores OAuth (Google, GitHub - futuro)
- Magic Links (futuro)

**Flujo de Autenticación:**
1. Usuario ingresa credenciales en SignInPage
2. Flutter SDK envía credenciales a Supabase Auth
3. Supabase valida y retorna JWT (JSON Web Token)
4. Token se almacena localmente y se incluye en headers de requests
5. AuthGate redirige según estado de sesión

### 6.2 Control de Acceso Basado en Roles (RBAC)

#### 6.2.1 Definición de Roles

| Rol | Permisos | Restricciones |
|-----|----------|---------------|
| **Admin** | - CRUD completo en devices<br>- Aprobar/rechazar requests<br>- Ver todos los activity_logs<br>- Asignar dispositivos a usuarios<br>- Gestionar todas las rutinas | Ninguna |
| **Guest** | - Leer dispositivos asignados<br>- Controlar dispositivos asignados<br>- Crear routines propias<br>- Solicitar acceso a dispositivos | - No puede ver dispositivos no asignados<br>- No puede acceder a Analytics<br>- No puede modificar asignaciones |

#### 6.2.2 Implementación de RLS

**Row-Level Security** en PostgreSQL garantiza seguridad a nivel de base de datos.

**Ejemplo de Política:**
- **Tabla:** `devices`
- **Política:** "Guests can only read assigned devices"
- **Condición SQL:** `EXISTS (SELECT 1 FROM user_devices WHERE user_id = auth.uid() AND device_id = devices.id)`

**Función Helper:**
```sql
is_admin() → Retorna TRUE si el usuario actual tiene role='admin'
```

Esta función se usa en múltiples políticas para simplificar la lógica.

### 6.3 Seguridad en Comunicaciones

| Capa | Medida de Seguridad |
|------|---------------------|
| **App ↔ Supabase** | HTTPS/TLS 1.3 |
| **Node-RED ↔ Supabase** | Service Role Key (solo backend) |
| **Node-RED ↔ MQTT** | Username/Password |
| **App ↔ Usuario** | Almacenamiento seguro de tokens (Flutter Secure Storage) |

### 6.4 Prevención de Concurrencia

Para evitar que múltiples usuarios controlen el mismo dispositivo simultáneamente:

**Mecanismo de Bloqueo (Lock):**
1. Al intentar controlar un dispositivo, verificar `locked_by`
2. Si está bloqueado por otro usuario y no ha pasado el timeout (5 min), denegar
3. Si está libre o expiró, adquirir lock (`locked_by = user_id`, `locked_at = NOW()`)
4. Ejecutar acción
5. Liberar lock

**Implementado a nivel de:**
- RLS policies (validación en BD)
- Lógica de aplicación (UX)

---

## 7. Características Principales

### 7.1 Gestión de Dispositivos

**Funcionalidades:**
- Visualización en tiempo real del estado de dispositivos
- Control ON/OFF mediante toggles
- Envío de mensajes a pantallas LCD
- Clasificación por tipo de dispositivo

**Tipos de Dispositivos Soportados:**
1. **Light (Luz):** Toggle simple ON/OFF
2. **Screen (Pantalla LCD):** Entrada de texto para mostrar mensajes
3. **Dispenser:** Control de activación
4. **Camera:** Visualización futura de stream

**Interfaz de Usuario:**
- Cards responsivas con diseño Material 3
- Iconos dinámicos según tipo y estado
- Indicadores visuales de estado (On/Off pills)
- Soporte para dark mode

### 7.2 Sistema de Solicitudes (Request System)

**Problema Resuelto:**
Los usuarios Guest no tienen dispositivos asignados por defecto.

**Flujo de Solicitud:**
1. Guest presiona "Request Device Access" (FAB persistente)
2. Selecciona tipo de dispositivo o dispositivo específico
3. Opcionalmente añade motivo de solicitud
4. Request se crea con `status='pending'`
5. Admin recibe notificación (implementación futura)
6. Admin revisa solicitudes en Admin Dashboard
7. Admin aprueba (asigna dispositivo) o rechaza
8. Guest recibe acceso inmediato tras aprobación

**Ventajas:**
- Proceso de onboarding controlado
- Trazabilidad de asignaciones
- Flexibilidad para solicitar dispositivo específico

### 7.3 Automatización Mediante Rutinas

**Concepto:**
Permite a usuarios crear acciones programadas sin necesidad de código.

**Configuración de Rutina:**
- **Dispositivo:** Qué dispositivo controlar
- **Tipo de Acción:** set_state (ON/OFF) o set_message (texto)
- **Valor:** Estado booleano o string de mensaje
- **Intervalo:** Cada cuántos segundos ejecutar (5-60s)
- **Expiración:** Auto-desactivación después de 1 hora

**Ciclo de Vida:**
1. Usuario crea rutina desde app
2. Rutina se guarda en BD con `enabled=true`
3. Node-RED polling detecta rutinas activas
4. Node-RED verifica si `NOW() - last_run_at >= interval_seconds`
5. Si cumple, ejecuta acción y actualiza `last_run_at`
6. Si pasó `expires_at`, Node-RED podría desactivar (o simplemente ignorar)

**Gestión:**
- Toggle ON/OFF para pausar rutinas
- Swipe-to-delete para eliminar
- Listado cronológico en RoutinesPage

### 7.4 Analytics y Auditoría

**Objetivo:**
Rastrear todas las acciones sobre dispositivos para auditoría y análisis.

**Información Registrada:**
- Quién ejecutó la acción (usuario o sistema)
- Sobre qué dispositivo
- Qué tipo de acción (cambio de estado, mensaje)
- Valor resultante
- Timestamp preciso
- Fuente (usuario manual, rutina, sistema)

**Visualización (Admin Only):**
- Lista cronológica en AnalysisPage
- Iconos según tipo de acción
- Colores según estado (verde ON, gris OFF, azul mensaje)
- Filtrado y búsqueda (futuro)

**Log Automático:**
Cada vez que se ejecuta `setStateById()` o `setMessageById()`, se inserta automáticamente un registro en `activity_logs`.

### 7.5 Interfaz de Usuario Adaptativa

**Dark Mode:**
- Toggle en Settings → Dark Mode
- Persistencia mediante SharedPreferences
- Adaptación automática de colores:
  - Fondo de cards: `#2D2D2D` (oscuro) vs `#FFFFFF` (claro)
  - Texto: `#FFFFFF` (oscuro) vs `#000000` (claro)
  - Bordes y sombras ajustados

**Responsive Design:**
- ConstrainedBox para limitar ancho máximo (880px)
- Grids adaptativos (1 o 2 columnas según ancho)
- SafeArea para notches y bordes de pantalla

---

## 8. Flujos de Trabajo

### 8.1 Flujo de Registro y Onboarding (Guest)

```
1. Usuario abre app
   ↓
2. SignInPage → "Create Account"
   ↓
3. Ingresa email y contraseña
   ↓
4. Supabase Auth crea usuario en auth.users
   ↓
5. Trigger SQL crea perfil en profiles (role='guest' por defecto)
   ↓
6. AuthGate detecta sesión → Redirige a AppShell (HomePage)
   ↓
7. HomePage muestra "No devices assigned yet"
   ↓
8. Usuario toca FAB "Request Device Access"
   ↓
9. Completa DeviceRequestDialog
   ↓
10. Request insertado en device_requests (status='pending')
   ↓
11. Usuario espera aprobación
```

### 8.2 Flujo de Aprobación de Solicitud (Admin)

```
1. Admin abre app → HomePage
   ↓
2. Toca botón "Admin" en AppBar
   ↓
3. AdminDashboardPage → Tab "Requests"
   ↓
4. Ve lista de solicitudes pendientes
   ↓
5. Selecciona solicitud → Toca "Approve"
   ↓
6. Si request tiene target_device_id:
      → Asigna ese dispositivo directamente
   Si no:
      → Dialog: Admin selecciona dispositivo manualmente
   ↓
7. INSERT en user_devices (user_id, device_id)
   ↓
8. UPDATE device_requests SET status='accepted'
   ↓
9. Guest inmediatamente ve dispositivo en HomePage (Realtime/Polling)
```

### 8.3 Flujo de Control de Dispositivo (Usuario)

```
1. Usuario ve dispositivo asignado en HomePage
   ↓
2. Para LIGHT/DISPENSER:
      Usuario toca toggle switch
      ↓
   Para SCREEN:
      Usuario toca icono edit (✏️)
      ↓
      ScreenMessageDialog → Ingresa texto
      ↓
3. App llama deviceRepo.setStateById() o setMessageById()
   ↓
4. UPDATE devices SET state/message = valor, updated_at = NOW()
   ↓
5. INSERT activity_logs (automático)
   ↓
6. Node-RED polling detecta cambio en devices
   ↓
7. Node-RED publica comando MQTT al topic adecuado
   ↓
8. ESP32 suscrito al topic ejecuta comando físico
   ↓
9. ESP32 confirma (opcional: publica estado actual)
```

### 8.4 Flujo de Ejecución de Rutina (Node-RED)

```
1. Inject node dispara cada 2 segundos
   ↓
2. HTTP GET /rest/v1/routines?enabled=eq.true
   ↓
3. Function "Check Intervals":
      Para cada rutina:
         Si expires_at <= NOW(): Skip
         Si (NOW() - last_run_at) >= interval_seconds:
            Añadir a lista de ejecución
   ↓
4. Split node: Procesa cada rutina individualmente
   ↓
5. Function "Prepare Updates":
      Crea dos mensajes:
         - PATCH /routines/{id} → last_run_at = NOW()
         - PATCH /devices/{device_id} → state/message = valor
   ↓
6. HTTP PATCH actualiza last_run_at
   ↓
7. HTTP PATCH actualiza device
   ↓
8. Activity log se inserta automáticamente (source='routine')
   ↓
9. Ciclo se repite cada 2 segundos
```

---

## 9. Integración y Comunicación

### 9.1 Integración Flutter - Supabase

**Biblioteca:** `supabase_flutter`

**Operaciones Implementadas:**
- **Authentication:** `supabase.auth.signInWithPassword()`, `signOut()`
- **Realtime:** `supabase.channel().onPostgresChanges()`
- **REST API:** `supabase.from('table').select()/.insert()/.update()`

**Patrón de Repositorio:**
Cada tabla tiene su repositorio que encapsula las queries, facilitando testing y mantenimiento.

### 9.2 Integración Node-RED - Supabase

**Método:** HTTP Request nodes con autenticación manual

**Headers Configurados:**
- `apikey`: Service Role Key
- `Authorization`: Bearer Service Role Key
- `Content-Type`: application/json

**Endpoints Usados:**
- `GET /rest/v1/routines`: Obtener rutinas activas
- `PATCH /rest/v1/routines?id=eq.{id}`: Actualizar last_run_at
- `PATCH /rest/v1/devices?id=eq.{id}`: Cambiar estado de dispositivo

### 9.3 Comunicación MQTT

**Broker:** Mosquitto

**Topics:**
- `demo/led/set`: Controlar LED (payload: "ON" | "OFF")
- `demo/lcd/text`: Enviar mensaje a LCD (payload: string de texto)
- `demo/uniLed/set`: Control UniLED

**Quality of Service (QoS):** 0 (At most once) - Prioriza velocidad sobre garantía de entrega

**Formato de Mensajes:**
- Estados: Strings simples ("ON", "OFF")
- Mensajes: Texto plano UTF-8

**Seguridad MQTT:**
- Username/Password básico (implementado)
- TLS/SSL (recomendado para producción)

---

## 10. Metodología de Desarrollo

### 10.1 Paradigma de Desarrollo

**Enfoque:** Desarrollo Ágil Iterativo

**Prácticas Aplicadas:**
- Desarrollo incremental con features completas por iteración
- Refactoring continuo para mantener calidad de código
- Testing manual exhaustivo antes de cada commit
- Documentación inline y comentarios en español

### 10.2 Herramientas de Desarrollo

| Categoría | Herramienta |
|-----------|-------------|
| **IDE** | Visual Studio Code / Android Studio |
| **Control de Versiones** | Git + GitHub |
| **UI Design** | Flutter DevTools, Material Theme Builder |
| **Backend Management** | Supabase Dashboard |
| **API Testing** | Postman (para endpoints Supabase) |
| **Database Management** | Supabase SQL Editor |

### 10.3 Estructura de Código (Clean Architecture)

**Capas:**
1. **Presentation:** Widgets, Pages, Providers (UI/UX)
2. **Domain:** Entidades, Casos de Uso (lógica de negocio)
3. **Infrastructure:** Repositorios, Servicios externos (acceso a datos)

**Beneficios:**
- Separación de responsabilidades
- Facilita testing unitario
- Reutilización de código
- Escalabilidad

### 10.4 Gestión de Dependencias

**Flutter Dependencies:**
- Dependencias de producción en `dependencies:`
- Dependencias de desarrollo en `dev_dependencies:`
- Versionado mediante `pubspec.yaml`

**Principales Dependencias:**
- `flutter_riverpod`: ^2.x
- `supabase_flutter`: últimas versión estable
- `geolocator`: para servicios de ubicación
- `shared_preferences`: persistencia local
- `intl`: formateo de fechas/números

---

## 11. Despliegue e Infraestructura

### 11.1 Arquitectura de Despliegue

```
┌─────────────────────────────────────────────┐
│         Google Play / App Store             │
│          (Distribución Futura)              │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│      Flutter App Build Artifacts            │
│  - Android: APK/AAB                         │
│  - iOS: IPA                                 │
└──────────────────┬──────────────────────────┘
                   │
                   │ API Calls
                   ▼
┌─────────────────────────────────────────────┐
│      Supabase Cloud (Managed)               │
│  - Auto-scaling                             │
│  - 99.9% Uptime SLA                         │
│  - Global CDN                               │
└──────────────────┬──────────────────────────┘
                   │
                   │ HTTP Polling
                   ▼
┌─────────────────────────────────────────────┐
│      Node-RED (Self-hosted/Cloud)           │
│  - VPS/Cloud VM                             │
│  - Docker Container                         │
└──────────────────┬──────────────────────────┘
                   │
                   │ MQTT
                   ▼
┌─────────────────────────────────────────────┐
│      MQTT Broker (Mosquitto)                │
│  - Same host as Node-RED or separate        │
└──────────────────┬──────────────────────────┘
                   │
                   │ WiFi
                   ▼
┌─────────────────────────────────────────────┐
│      IoT Devices (Local Network)            │
│  - ESP32 con WiFi                           │
└─────────────────────────────────────────────┘
```

### 11.2 Entorno de Desarrollo

**Requisitos:**
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android SDK (API 21+) / Xcode 13+ (para iOS)
- Node.js 16+ (para Node-RED)

**Configuración Local:**
1. Clonar repositorio
2. Instalar dependencias Flutter (`flutter pub get`)
3. Configurar credenciales Supabase en `env.dart`
4. Ejecutar app (`flutter run`)

### 11.3 Entorno de Producción

**Supabase:**
- Plan gratuito para MVP
- Upgrade a Pro para producción (mejor throughput, backups diarios)

**Node-RED:**
- Despliegue recomendado: Docker en VPS (DigitalOcean, AWS Lightsail)
- Configuración de persistencia de flujos
- Monitoreo con logs

**MQTT Broker:**
- Mosquitto en mismo servidor que Node-RED
- Configuración de firewall para puerto 1883 (solo acceso interno)

### 11.4 Estrategia de Backup

| Componente | Estrategia | Frecuencia |
|------------|-----------|------------|
| **Base de Datos** | Backups automáticos Supabase | Diario |
| **Flujos Node-RED** | Versionado en Git | Cada cambio |
| **Configuraciones** | Variables de entorno en `.env` (gitignored) | - |

---

## 12. Conclusiones y Trabajo Futuro

### 12.1 Logros del Proyecto

1. **Sistema RBAC Completo:** Implementación exitosa de roles con seguridad a nivel de base de datos
2. **Automatización Escalable:** Arquitectura de rutinas permite agregar fácilmente nuevas acciones
3. **UX Moderna:** Dark mode, Material 3, animaciones suaves
4. **Trazabilidad Total:** Activity logs proporcionan auditoría completa
5. **Arquitectura Limpia:** Código mantenible y testeable

### 12.2 Trabajo Futuro

#### Prioridad Alta
- [ ] Notificaciones Push para:
  - Solicitudes aprobadas/rechazadas
  - Alertas de dispositivos
- [ ] Mejora de Rutinas:
  - Condiciones (if-then-else)
  - Rutinas más complejas (secuencias)
  - Toggle real de estados (no solo valores fijos)

#### Prioridad Media
- [ ] Visualización de cámaras en tiempo real
- [ ] Dashboard de estadísticas de uso
- [ ] Exportación de logs en CSV
- [ ] Panel de administración web (complemento a la app)
- [ ] Soporte para múltiples idiomas (i18n)

#### Prioridad Baja
- [ ] Integración con asistentes de voz (Google Assistant, Alexa)
- [ ] Geofencing para automatizaciones basadas en ubicación
- [ ] Sharing de dispositivos entre usuarios
- [ ] Marketplace de rutinas predefinidas

### 12.3 Lecciones Aprendidas

**Técnicas:**
- La combinación de Supabase + Flutter acelera significativamente el desarrollo
- RLS de PostgreSQL es poderoso pero requiere cuidado con recursión
- Node-RED es ideal para prototipos rápidos de automatización

**De Negocio:**
- El sistema de solicitudes reduce fricción de onboarding
- Dark mode es altamente valorado por usuarios
- Logs de actividad generan confianza y transparencia

### 12.4 Impacto y Aplicaciones

**Hogares Inteligentes:**
Control centralizado de luces, termostatos, cerraduras

**Educación:**
Enseñanza de IoT y programación visual con Node-RED

**Pequeños Negocios:**
Gestión de dispositivos en tiendas, oficinas

**Investigación:**
Plataforma base para experimentos de IoT edge computing

---

## Anexos

### A. Glosario de Términos

- **RLS:** Row-Level Security - Seguridad a nivel de fila en PostgreSQL
- **RBAC:** Role-Based Access Control - Control de acceso basado en roles
- **MQTT:** Message Queuing Telemetry Transport - Protocolo de mensajería IoT
- **ESP32:** Microcontrolador con WiFi y Bluetooth integrados
- **BaaS:** Backend-as-a-Service - Servicios de backend gestionados
- **JWT:** JSON Web Token - Token de autenticación estándar
- **QoS:** Quality of Service - Nivel de garantía de entrega en MQTT

### B. Referencias

1. **Flutter Documentation:** https://docs.flutter.dev
2. **Supabase Documentation:** https://supabase.com/docs
3. **Node-RED Documentation:** https://nodered.org/docs
4. **MQTT Specification:** https://mqtt.org/mqtt-specification
5. **Material Design 3:** https://m3.material.io
6. **PostgreSQL RLS:** https://www.postgresql.org/docs/current/ddl-rowsecurity.html

---

**Fin del Documento - AnyaLink IoT Platform v1.0**
