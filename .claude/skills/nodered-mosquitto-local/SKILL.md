---
name: nodered-mosquitto-local
description: Use for infrastructure tasks related to Mosquitto MQTT broker or Node-RED in AnyaLink. Covers startup, configuration, flows location, env vars for Supabase, and sanity checks.
---

# AnyaLink — Mosquitto + Node-RED (infra local)

## Mosquitto MQTT Broker

**Instalación:** MSI en `C:\Program Files\mosquitto\`, corre como servicio Windows.

**Configuración relevante** (`C:\Program Files\mosquitto\mosquitto.conf`):

```conf
listener 1883 0.0.0.0
allow_anonymous true
```

**Comandos de servicio:**

```powershell
net start mosquitto          # arrancar
net stop mosquitto           # detener
# o bien con el nombre completo del servicio:
net start "Mosquitto Broker"
```

**Sanity check:**

```bash
# Terminal 1 — suscribir
mosquitto_sub -h localhost -t 'anyalink/#' -v

# Terminal 2 — publicar
mosquitto_pub -h localhost -t 'anyalink/test' -m 'hola'
# Debe aparecer: anyalink/test hola en terminal 1
```

**Puerto del ESP32:** el ESP32 conecta a la IP de la PC Windows en el puerto 1883. Verificar que el Firewall de Windows tenga regla inbound TCP 1883 (solo Private network).

## Node-RED

**Instalación:** `npm install -g node-red` (requiere Node 24 ya instalado).

**Arrancar:**

```bash
node-red
# Acceso web: http://localhost:1880
```

**Directorio de usuario:** `%USERPROFILE%\.node-red\`
**Flows:** `%USERPROFILE%\.node-red\flows.json`
  - En el MVP también mantenemos copia en `infra/nodered/flows.json`

## Variables de entorno para Node-RED + Supabase

Node-RED accede a Supabase usando las credenciales como variables de entorno (no hardcodeadas en flows):

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGci...   ← usar service_role, no anon
```

En Windows, setear antes de arrancar Node-RED:

```powershell
$env:SUPABASE_URL = "https://xxxxx.supabase.co"
$env:SUPABASE_SERVICE_KEY = "eyJ..."
node-red
```

O crear un `.env` y cargar con `dotenv` desde un nodo `function` en Node-RED.

## Flujo Node-RED del MVP (esquema)

```
[MQTT in: anyalink/dispensador/metrics]
  └── [function: parsear JSON]
        └── [supabase-insert: device_metrics]

[MQTT in: anyalink/dispensador/status]
  └── [function: manejar online/offline]
        └── [supabase-update: devices.state]

[supabase-poll: device_commands WHERE status='pending']
  └── [function: extraer comando]
        └── [MQTT out: anyalink/dispensador/command]
              └── [supabase-update: device_commands.status='ack']
```

**Nodos npm necesarios en Node-RED:**
```bash
cd %USERPROFILE%\.node-red
npm install node-red-node-mqtt @supabase/supabase-js
```

## Sanity checks completos

```bash
# 1. Broker levantado
mosquitto_sub -h localhost -t '#' -v -C 1 && echo "broker OK"

# 2. Node-RED responde
curl -s http://localhost:1880/flows | head -c 50 && echo " — NR OK"

# 3. ESP32 publicando métricas (ver en suscriptor)
mosquitto_sub -h localhost -t 'anyalink/dispensador/metrics' -C 1 -v
```
