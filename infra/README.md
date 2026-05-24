# AnyaLink — Infraestructura local

## Arranque

### 1. Mosquitto (broker MQTT)
```
net start mosquitto
```
Puerto: 1883. Config: `infra/mosquitto/mosquitto.conf` (copia versionada).
Para aplicar cambios al config real en `C:\Program Files\mosquitto\mosquitto.conf`:
```
net stop mosquitto
copy infra\mosquitto\mosquitto.conf "C:\Program Files\mosquitto\mosquitto.conf"
net start mosquitto
```

### 2. Node-RED
```
node-red
```
Puerto: 1880. Abrir http://localhost:1880 para ver/editar flujos.

Para importar los flujos iniciales:
1. Abrir Node-RED (http://localhost:1880)
2. Menú → Import → pegar contenido de `infra/node-red/flows.json`
3. Deploy

### 3. Variables de entorno para Node-RED

Antes de arrancar Node-RED, configurar en el entorno:
```
$env:SUPABASE_URL = "https://<tu-proyecto>.supabase.co"
$env:SUPABASE_SERVICE_KEY = "<service-role-key>"
$env:SUPABASE_AUTH_HEADER = "Bearer <service-role-key>"
```

O configuar en `~/.node-red/settings.js` bajo `functionGlobalContext`.

## Sanity checks

```bash
# Verificar que Mosquitto escucha
mosquitto_sub -h localhost -t "anyalink/#" -v

# Publicar test
mosquitto_pub -h localhost -t "anyalink/test" -m "hola"

# Simular metrics del ESP32
mosquitto_pub -h localhost -t "anyalink/device/<DEVICE_ID>/metrics" \
  -m '{"weight_g":245.3,"temperature_c":24.1,"humidity_pct":56}'

# Simular online
mosquitto_pub -h localhost -t "anyalink/device/<DEVICE_ID>/online" -m "online" -r
```

## Flujos Node-RED

| Flujo | Descripción |
|---|---|
| Comandos pendientes → MQTT | Poll Supabase cada 2s, publica en MQTT, marca como `sent` |
| ACK estado → Supabase | Suscribe a `state`, marca comando como `done` |
| Metrics → Supabase upsert | Suscribe a `metrics`, upsert en `device_metrics` |
| Heartbeat online | Suscribe a `online` (retained), actualiza `devices.online` |
