# Desarrollo y Testing

## Setup mínimo

### App Flutter

```powershell
flutter pub get
flutter run -d windows
flutter test
flutter analyze
```

Requiere `lib/core/env.dart` (copia de `env.dart.example`) con la URL y anon key de Supabase reales.

### Firmware ESP32 (PlatformIO)

```powershell
cd firmware\anyalink_node
pio run                # build
pio run -t upload      # flash
pio device monitor     # serial 115200
```

Si `pio` no está en PATH: `C:\Users\<user>\.platformio\penv\Scripts\pio.exe`. Plan 1 incluye el snippet para sumarlo al PATH.

Requiere `firmware/anyalink_node/include/secrets.h` (copia de `secrets.h.example`) con WiFi, IP del broker (=IP local de tu PC) y `DEVICE_ID` del row `Dispensador` en Supabase.

### Infra local

```powershell
# Broker (corre como servicio Windows ya instalado)
net start mosquitto

# Sub para debug
& "W:\Mosquitto\mosquitto_sub.exe" -h 192.168.20.113 -t 'anyalink/#' -v

# Node-RED (consola)
node-red

# UI editor
start http://localhost:1880
```

Detalle en `infra/README.md`.

## Dependencias relevantes

- App: `flutter_riverpod`, `supabase_flutter`, `flutter_test`.
- Firmware: `PubSubClient`, `Adafruit SSD1306`, `Adafruit GFX`, `ESP32Servo`, `DHT sensor library`, `HX711`, `ArduinoJson`.
- Bridge TP-Link (congelado): `python-kasa`, `requests`.

## Tests existentes

```powershell
flutter test
```

- `widget_test.dart`: smoke neutro.
- `smoke_theme_test.dart`: monta `AnyaLinkApp`.
- `home_presence_test.dart`: verifica `AnyaLink` y `Lampara`.
- `list_presence_test.dart`: verifica `Dispositivos`.
- `device_toggle_test.dart`: toggle mock encendido/apagado.
- `feeder_dispense_test.dart`: tap en "Dispensar" llama `sendCommand` con `action='dispense'`.
- `feeder_metrics_test.dart`: emisión vía stream actualiza valores en el `FeederCard`.

## Fake repo

`test/helpers/test_app.dart`:

- `_FakeDeviceRepo` implementa todo el contrato (`getAll`, `getByAlias`, `setStateByAlias`, `setStateById`, `watchAll`, `watchStateByAlias`, `sendCommand`, `watchMetrics`).
- Almacena `sentCommands` para asserts.
- `emitMetrics(metrics)` para empujar valores en tests.
- `buildTestApp` y `buildFeederTestApp` arman el `ProviderScope` con overrides.

## Verificación end-to-end (con hardware real)

1. Aplicar la migration en Supabase.
2. Levantar Mosquitto (servicio) y Node-RED (`node-red`).
3. Sub a `anyalink/#` debe quedar a la escucha sin error.
4. Insertar manualmente una fila en `device_commands` (`status='pending'`) y verificar que pasa a `sent` en ≤2 s.
5. Flashear ESP32, ver en monitor serial `WiFi OK` → `MQTT OK` → métricas cada 5 s.
6. `devices.online` pasa a `true` en Supabase.
7. En la app, tile `Dispensador` con badge verde y métricas en vivo. Botón "Dispensar" mueve el servo y la fila pasa `pending → sent → done`.

## Checklist antes de commitear

- `flutter analyze` sin errores (warnings info son OK).
- `flutter test` 7/7 verde.
- `pio run` (firmware) compila.
- `lib/core/env.dart` y `firmware/.../secrets.h` no aparecen en `git status` (están gitignored).
