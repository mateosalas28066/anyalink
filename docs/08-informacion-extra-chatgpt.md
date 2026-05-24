# Expansión Técnica y Roadmap de AnyaLink

## Propósito

Este documento complementa la documentación existente del proyecto AnyaLink con información técnica, decisiones arquitectónicas, roadmap, integración IoT avanzada, Node-RED, MQTT, visión por computadora, operación del sistema y recomendaciones de evolución.

La idea es consolidar tanto el estado actual implementado como la dirección técnica real del proyecto según:

* Código Flutter y bridge Python.
* Documentación IEEE/ISO.
* Conversaciones y decisiones tomadas durante el desarrollo.
* Visión del proyecto como ecosistema IoT para mascotas.

---

# 1. Visión real del proyecto

AnyaLink dejó de ser únicamente una app de domótica genérica y evolucionó hacia una plataforma IoT enfocada inicialmente en el cuidado inteligente de mascotas.

Actualmente el proyecto mezcla:

* Dashboard domótico.
* Control remoto de dispositivos.
* Integración con hardware ESP32.
* Automatización.
* Monitoreo ambiental.
* Streaming de cámara.
* Persistencia en la nube.
* Sincronización entre hardware y backend.
* Visión por computadora como línea futura.

La arquitectura ya permite escalar a:

* Múltiples hogares.
* Múltiples mascotas.
* Ecosistemas de sensores.
* Automatización avanzada.
* Integración con asistentes.
* Analítica de comportamiento.

---

# 2. Evolución conceptual de AnyaLink

## Fase inicial

La primera versión del proyecto comenzó como:

* Dashboard Flutter.
* Supabase como backend.
* Control de dispositivos TP-Link.
* Polling y sincronización básica.

## Evolución hacia IoT para mascotas

Posteriormente el proyecto se orientó a:

* Dispensador inteligente.
* ESP32-CAM.
* Rutinas de alimentación.
* Métricas de consumo.
* Monitoreo remoto.
* Alertas.
* Video en vivo.

## Evolución futura esperada

La dirección natural del proyecto apunta hacia:

* Plataforma IoT modular.
* Automatización visual.
* Ecosistema de dispositivos.
* IA para análisis de comportamiento.
* Rutinas inteligentes.
* Integración edge + cloud.

---

# 3. Arquitectura extendida recomendada

## Arquitectura actual resumida

```text
Flutter App
    ↓
Supabase
    ↓
Bridge Python
    ↓
Hardware local TP-Link / ESP32
```

## Arquitectura recomendada a futuro

```text
Flutter App
    ↓
Supabase
    ↓
API / Automation Layer
    ↓
MQTT Broker
    ↓
ESP32 / ESP32-CAM / Edge Nodes
    ↓
Sensores y actuadores
```

## Componentes sugeridos

### Frontend

* Flutter.
* Riverpod.
* Material 3.
* Responsive UI.
* WebSocket/MQTT clients.

### Backend

* Supabase.
* PostgreSQL.
* Realtime.
* Edge Functions.
* Storage.
* Auth.

### Automatización

* Node-RED.
* MQTT Broker.
* Reglas automáticas.
* Webhooks.
* Integración entre servicios.

### Edge Computing

* ESP32.
* ESP32-CAM.
* Raspberry Pi opcional.
* Python bridges.

### IA / visión

* OpenCV.
* TensorFlow Lite.
* YOLO Nano/Tiny.
* Detección de presencia.
* Detección de consumo.

---

# 4. Rol recomendado de Node-RED

## Por qué Node-RED tiene sentido en AnyaLink

Aunque actualmente la lógica vive distribuida entre Flutter, Supabase y scripts Python, Node-RED puede convertirse en el centro de automatización visual del ecosistema.

Node-RED encaja especialmente bien porque:

* Simplifica flujos IoT.
* Facilita pruebas.
* Reduce código repetitivo.
* Permite automatización visual.
* Integra MQTT, HTTP y WebSocket fácilmente.
* Facilita dashboards internos.
* Permite integración rápida con IA y APIs.

---

## Arquitectura recomendada con Node-RED

```text
Flutter App
    ↓
Supabase
    ↓
Node-RED
    ↓
MQTT Broker
    ↓
ESP32 / ESP32-CAM
```

---

## Responsabilidades ideales de Node-RED

### Automatización

Ejemplos:

* Si nivel de comida < 20% → enviar alerta.
* Si rutina programada → enviar comando MQTT.
* Si temperatura > umbral → activar ventilador.
* Si mascota detectada → registrar evento.

### Orquestación

Node-RED puede:

* Consumir cambios desde Supabase.
* Ejecutar reglas.
* Publicar MQTT.
* Guardar logs.
* Disparar notificaciones.
* Llamar APIs externas.

### Integración de dispositivos

Permite integrar fácilmente:

* TP-Link.
* ESP32.
* cámaras IP.
* Home Assistant.
* Alexa.
* Google Home.
* Telegram.
* Discord.

---

## Flujos recomendados

### Flujo: dispensación manual

```text
Flutter → Supabase → Node-RED → MQTT → ESP32
```

### Flujo: rutina automática

```text
Scheduler → Node-RED → MQTT → ESP32
```

### Flujo: sensor ambiental

```text
ESP32 → MQTT → Node-RED → Supabase → Flutter
```

### Flujo: alerta

```text
Sensor → Node-RED → Push Notification
```

---

## Ventajas reales

### Reduce complejidad del frontend

La app deja de contener demasiada lógica operacional.

### Centraliza automatizaciones

Toda la lógica de eventos vive en un solo lugar.

### Facilita debugging

Node-RED permite visualizar:

* mensajes,
* payloads,
* errores,
* estados,
* triggers.

### Facilita pruebas académicas

Muy útil para:

* demostraciones,
* prototipos,
* pruebas rápidas,
* validación funcional.

---

## Riesgos y consideraciones

### No reemplaza backend completo

Node-RED no debe reemplazar:

* Auth.
* Persistencia principal.
* Seguridad crítica.

### Seguridad

Debe protegerse:

* acceso al panel,
* MQTT,
* APIs,
* credenciales.

### Escalabilidad

Para producción grande:

* dividir flujos,
* usar contenedores,
* separar broker.

---

# 5. MQTT en AnyaLink

## Rol de MQTT

MQTT es ideal para el proyecto porque:

* es ligero,
* funciona bien en IoT,
* soporta tiempo real,
* consume pocos recursos.

---

## Broker recomendado

Opciones viables:

### Desarrollo local

* Mosquitto.
* EMQX.

### Producción

* HiveMQ.
* EMQX Cloud.
* AWS IoT.

---

## Estructura recomendada de topics

```text
anyalink/device/{deviceId}/state
anyalink/device/{deviceId}/command
anyalink/device/{deviceId}/metrics
anyalink/device/{deviceId}/alerts
```

Ejemplo:

```text
anyalink/device/comedor-01/command
```

Payload:

```json
{
  "action": "feed",
  "portion": 1
}
```

---

## Buenas prácticas MQTT

### Mantener topics consistentes.

### Usar QoS correctamente.

* QoS 0 para métricas frecuentes.
* QoS 1 para comandos críticos.

### Mantener payloads simples.

### Implementar heartbeat.

Ejemplo:

```json
{
  "online": true,
  "timestamp": "2026-05-24T12:00:00Z"
}
```

---

# 6. ESP32 y firmware

## Componentes ya considerados

* ESP32.
* ESP32-CAM.
* Servomotor.
* DHT11/DHT22.
* Sensor de nivel.
* Cámara.

---

## Recomendaciones técnicas

## Preferir ESP32 sobre ESP8266

Porque:

* más RAM,
* doble núcleo,
* mejor WiFi,
* mejor soporte cámara,
* más estable.

---

## Librerías sugeridas

### MQTT

* PubSubClient.
* AsyncMqttClient.

### Sensores

* DHT sensor library.

### Cámara

* esp32-camera.

### OTA

* ArduinoOTA.

---

## OTA (Over The Air)

Muy recomendable implementar:

```text
Flutter → Backend → ESP32 OTA
```

Permite:

* actualizar firmware,
* corregir errores,
* agregar features,
* evitar reflasheo físico.

---

# 7. Visión por computadora

## Estado actual

Actualmente la visión por computadora es conceptual/documental.

No aparece integrada completamente en el código revisado.

---

## Líneas reales viables

### Detección de mascota

Confirmar presencia frente al dispensador.

### Confirmación de consumo

Detectar si realmente comió.

### Detección de comportamiento

Ejemplos:

* ansiedad,
* visitas frecuentes,
* falta de consumo,
* patrones anormales.

---

## Tecnologías viables

### Edge lightweight

* TensorFlow Lite.
* MobileNet.
* YOLO Tiny.

### Procesamiento externo

* OpenCV.
* Python.
* Raspberry Pi.

---

## Recomendación realista

No ejecutar IA pesada directamente en ESP32-CAM.

Mejor:

```text
ESP32-CAM → Stream → Edge server/Raspberry → IA
```

---

# 8. Persistencia y modelo de datos ampliado

## Tablas actuales

Principalmente:

```text
devices
```

---

## Tablas recomendadas

## users

```text
id
email
created_at
```

---

## devices

```text
id
user_id
alias
type
state
online
last_seen
created_at
```

---

## routines

```text
id
user_id
name
cron
enabled
created_at
```

---

## routine_actions

```text
id
routine_id
device_id
action
payload
```

---

## feeding_events

```text
id
device_id
portion
origin
status
created_at
```

---

## environmental_metrics

```text
id
device_id
temperature
humidity
food_level
created_at
```

---

## alerts

```text
id
user_id
type
message
read
created_at
```

---

# 9. Realtime vs Polling

## Estado actual

Actualmente:

```dart
Env.useRealtime = false
```

Por lo tanto el sistema usa polling.

---

## Problema del polling

* más consumo,
* más latencia,
* más tráfico.

---

## Recomendación futura

Migrar progresivamente a:

```text
Supabase Realtime + MQTT
```

Idealmente:

* MQTT para IoT.
* Realtime para UI.

---

# 10. Seguridad

## Riesgos detectados

### Credenciales hardcodeadas.

### Llaves sensibles en código.

### Configuración expuesta.

### Bridge con acceso privilegiado.

---

## Recomendaciones prioritarias

## Variables de entorno

Nunca dejar:

* passwords,
* URLs privadas,
* service keys,
* tokens,
* MQTT creds,

hardcodeados.

---

## Roles mínimos

Separar:

* frontend anon key,
* backend service role,
* IoT credentials.

---

## Row Level Security

Muy recomendable usar:

```text
Supabase RLS
```

para:

* dispositivos,
* rutinas,
* historial,
* alertas.

---

## MQTT Auth

Usar:

* usuario/contraseña,
* TLS,
* ACLs por topic.

---

# 11. Notificaciones

## Posibles tecnologías

### Firebase Cloud Messaging.

### OneSignal.

---

## Eventos ideales

* Bajo alimento.
* Dispositivo offline.
* Rutina ejecutada.
* Error mecánico.
* Temperatura alta.
* Cámara desconectada.

---

# 12. Integración futura con Home Assistant

## Potencial enorme

AnyaLink puede integrarse fácilmente con:

entity["software","Home Assistant","Open-source home automation platform"]

---

## Beneficios

* automatización avanzada,
* dashboards,
* asistentes,
* escenas,
* ecosistema enorme.

---

## Posible arquitectura

```text
ESP32 ↔ MQTT ↔ Home Assistant ↔ Node-RED ↔ Supabase ↔ Flutter
```

---

# 13. Roadmap recomendado

# Fase 1 — Estabilización

## Prioridades

* remover secretos,
* consolidar arquitectura,
* activar Auth real,
* limpiar providers,
* documentar migraciones.

---

# Fase 2 — IoT sólido

## Objetivos

* MQTT estable,
* ESP32 real,
* métricas,
* rutinas.

---

# Fase 3 — Automatización

## Objetivos

* Node-RED,
* reglas,
* alertas,
* dashboards.

---

# Fase 4 — IA y visión

## Objetivos

* detección de mascota,
* detección de consumo,
* eventos inteligentes.

---

# Fase 5 — Plataforma completa

## Objetivos

* múltiples dispositivos,
* múltiples mascotas,
* multiusuario,
* suscripciones,
* analítica avanzada.

---

# 14. Recomendaciones Flutter

## Consolidar arquitectura

Actualmente existen capas duplicadas:

* domain/data,
* infrastructure.

Conviene elegir una sola estrategia.

---

## Recomendación real

Usar:

```text
Presentation
Domain
Infrastructure
```

con:

* repositories únicos,
* casos de uso claros,
* providers limpios.

---

## Recomendaciones Riverpod

### Evitar lógica pesada en widgets.

### Centralizar side-effects.

### Separar providers:

* UI,
* repositorio,
* realtime,
* automation.

---

# 15. Testing recomendado

## Actualmente existe

* smoke tests,
* widget tests,
* fake repos.

---

## Faltante importante

### Integration tests.

### MQTT tests.

### Realtime tests.

### Hardware simulation.

### Offline tests.

---

## Recomendación

Implementar:

```text
Flutter integration_test
```

más:

* mocks MQTT,
* fake Supabase,
* hardware simulators.

---

# 16. Observabilidad y logs

## Muy recomendable agregar

### Logs estructurados.

### Dashboard técnico.

### Error tracking.

### Métricas.

---

## Herramientas útiles

### Sentry.

### Grafana.

### Prometheus.

### Loki.

---

# 17. Operación real del sistema

## Escenario doméstico esperado

```text
Usuario fuera de casa
    ↓
App Flutter
    ↓
Supabase / MQTT
    ↓
ESP32
    ↓
Dispensación
    ↓
Confirmación
    ↓
Historial y alerta
```

---

## Dependencias críticas

* energía,
* WiFi,
* broker,
* Supabase,
* hardware.

---

## Consideraciones reales

### Debe existir modo recovery.

### Debe existir watchdog.

### Debe existir reconexión.

### Debe existir fail-safe.

---

# 18. Posibles futuras funcionalidades

## IA

* reconocimiento de mascota,
* detección de comportamiento,
* predicción de consumo.

---

## Social

* perfiles de mascotas,
* compartir clips,
* comunidad.

---

## Comercial

* suscripción premium,
* analítica avanzada,
* almacenamiento cloud.

---

## Hardware

* balanza,
* lector RFID,
* sensores ultrasónicos,
* batería backup.

---

# 19. Decisiones técnicas recomendadas

## Mantener Flutter.

## Mantener Supabase.

## Adoptar MQTT como estándar IoT.

## Integrar Node-RED.

## Migrar a Realtime gradualmente.

## Mantener Python solo para bridges específicos.

## Evitar lógica crítica distribuida entre demasiados servicios.

---

# 20. Conclusión técnica

AnyaLink ya tiene una base técnica mucho más amplia que un simple prototipo académico.

La combinación de:

* Flutter,
* Supabase,
* ESP32,
* MQTT,
* Node-RED,
* automatización,
* visión por computadora,

permite evolucionar el proyecto hacia una plataforma IoT moderna, escalable y realmente diferenciada.

Actualmente el mayor reto no es crear nuevas funcionalidades, sino:

* consolidar arquitectura,
* reducir deuda técnica,
* centralizar automatización,
* asegurar estabilidad,
* profesionalizar seguridad,
* y definir claramente qué partes son prototipo y cuáles serán productivas.

El proyecto ya tiene suficiente complejidad y potencial como para evolucionar hacia:

* producto académico avanzado,
* startup IoT,
* plataforma de automatización doméstica enfocada en mascotas,
* o laboratorio de investigación para edge AI y smart home.
