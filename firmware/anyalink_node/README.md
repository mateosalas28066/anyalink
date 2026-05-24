# firmware/anyalink_node

Firmware ESP32 del dispensador AnyaLink. Base importada del proyecto previo `ESP32_1` (de ahí WiFiMulti + OLED + scaffolding MQTT). El Plan 2 lo extiende con sensores, servo y migración de topics a `anyalink/device/{id}/*`.

## Hardware

- Placa: **ESP32 DOIT DevKit v1** (board ID `esp32doit-devkit-v1`).
- OLED SSD1306 128×64 I2C en `0x3C` (SDA=21, SCL=22).
- LED indicador en GPIO 27.
- Plan 2 agrega:
  - Servomotor en GPIO 13 (PWM por LEDC).
  - HX711 (celda de carga): DT=GPIO 16, SCK=GPIO 17.
  - DHT22 o DHT11 en GPIO 4 (data).

## Setup

1. Copiar `include/secrets.h.example` a `include/secrets.h` y rellenar:
   - Redes WiFi (lista para WiFiMulti).
   - `MQTT_HOST` = IP local de tu PC en la LAN (donde corre Mosquitto).
   - `DEVICE_ID` = UUID de la fila en Supabase `devices` (alias `Dispensador`).
2. Build y flash:
   ```
   pio run -t upload
   pio device monitor
   ```
3. Monitor serial a 115200 baud.

## Estado actual de `main.cpp`

Lo importado del proyecto previo, funcional como prueba:
- Conecta a WiFi (multi-red).
- Conecta a broker MQTT local.
- Muestra "Arrancando" en OLED al boot.
- Escucha `demo/uniLed/set` ("ON"/"OFF") y `demo/lcd/text`.
- Publica `BOOT` en los `*/status` al conectarse.

Sirve para validar que el import quedó OK antes de meter la lógica del MVP.

## Pendiente (Plan 2)

- Migrar topics a `anyalink/device/{DEVICE_ID}/{command|state|metrics|online}`.
- LWT con `offline` retained al conectar / publicar `online` retained.
- Lectura periódica DHT + HX711 cada 5s -> publish JSON en `metrics`.
- Manejo de `{"action":"dispense","cmd_id":"..."}` -> mover servo 0→90→0, publicar ACK en `state`.
- Mostrar en OLED: peso actual, estado online, último comando ejecutado.

## Origen

Heredado de `D:\Descargas\ESP32_1`. Eliminadas: IP del broker Azure, credenciales WiFi hardcodeadas, user/pass MQTT de la VM. La estructura del archivo (OLED helper, reconnect, callback dispatch) se preservó.
