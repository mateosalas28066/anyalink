---
name: esp32-mqtt-node
description: Use for any ESP32 firmware task in AnyaLink — PlatformIO structure, libraries, MQTT topics, payload formats, pin map, and secrets handling.
---

# AnyaLink — Firmware ESP32 (PlatformIO)

## Estructura del proyecto PlatformIO

```
firmware/
├── platformio.ini
├── src/
│   └── main.cpp
├── include/
│   ├── secrets.h        ← ignorado por .gitignore, contiene WiFi/MQTT creds
│   └── config.h         ← pin map, intervalos, alias MQTT
└── lib/                 ← libs locales si aplica
```

## `platformio.ini` base

```ini
[env:esp32dev]
platform  = espressif32
board     = esp32dev
framework = arduino

lib_deps =
  knolleary/PubSubClient @ ^2.8
  bogde/HX711 @ ^0.7.5
  adafruit/DHT sensor library @ ^1.4.6
  adafruit/Adafruit Unified Sensor @ ^1.1.14

monitor_speed = 115200
```

## Pin map (`include/config.h`)

```cpp
// HX711
#define HX711_DOUT  4
#define HX711_SCK   5

// DHT22
#define DHT_PIN     14
#define DHT_TYPE    DHT22

// Servo
#define SERVO_PIN   18

// Intervalos (ms)
#define METRIC_INTERVAL_MS  5000   // publicar métricas cada 5 s
#define RECONNECT_DELAY_MS  5000
```

## `include/secrets.h` (NO commitear)

```cpp
// ¡Agregar firmware/include/secrets.h a .gitignore!
#define WIFI_SSID     "tu_red"
#define WIFI_PASSWORD "tu_password"
#define MQTT_HOST     "192.168.X.X"   // IP de la PC con Mosquitto
#define MQTT_PORT     1883
#define DEVICE_ID     "esp32-dispensador"
```

## Tópicos MQTT

| Tópico | Dirección | QoS | Payload |
|--------|-----------|-----|---------|
| `anyalink/dispensador/metrics` | ESP32 → broker | 0 | JSON: `{"weight_g":120.5,"temp_c":23.1,"humidity_pct":55.2}` |
| `anyalink/dispensador/status` | ESP32 → broker | 1 | `"online"` / `"offline"` (LWT) |
| `anyalink/dispensador/command` | broker → ESP32 | 1 | JSON: `{"cmd":"dispense","grams":50}` |
| `anyalink/dispensador/ack` | ESP32 → broker | 1 | JSON: `{"cmd":"dispense","ok":true}` |

## LWT (Last Will and Testament)

```cpp
client.setCallback(mqttCallback);
client.connect(
  DEVICE_ID,
  nullptr, nullptr,
  "anyalink/dispensador/status", 1, true, "offline"
);
// Al conectar exitosamente:
client.publish("anyalink/dispensador/status", "online", true);
```

## Comandos PlatformIO útiles

```bash
pio run                          # compilar
pio run -t upload                # flash (ESP32 debe estar conectado)
pio device monitor               # serial monitor 115200
pio run -t upload --upload-port COM3   # forzar puerto
```

## Notas de implementación

- Usar `millis()` para intervalos, nunca `delay()` en el loop principal (bloquea MQTT keepalive).
- El servo se mueve X grados al recibir `dispense`, vuelve a posición base tras 1 s.
- HX711: llamar `scale.tare()` al arrancar; calibrar con masa conocida antes de usar en producción.
- Si MQTT se cae, reconectar en el loop con backoff de `RECONNECT_DELAY_MS`.
