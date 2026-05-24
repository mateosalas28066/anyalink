# Pendientes y Riesgos

## Seguridad

- **service_role JWT hardcodeada en `infra/node-red/flows.json`**. Aceptable para MVP local; antes de cualquier despliegue compartido moverlo a env vars o config local. Existe el patrón documentado en `infra/README.md`.
- **RLS desactivada** en `devices`, `device_metrics`, `device_commands`. Equivalente a "datos públicos" — cualquiera con la anon key puede leer/escribir. Para una versión multi-usuario hay que agregar `user_id` en cada tabla y policies por sesión Supabase Auth.
- **Mosquitto sin auth ni TLS**. Solo escucha en la LAN doméstica (firewall rule `Private` profile). Si la PC se mueve a una red pública, conviene cerrar el puerto o agregar auth básica.

## Arquitectura

- **Doble capa Flutter** (`domain`+`data` vs `infrastructure`). La UI usa solo `infrastructure`. Hay que decidir una sola estrategia y borrar la otra para evitar drift.
- **AuthGate inactiva**. `LoginPage` y providers de Auth existen pero el gate manda directo a `HomePage`. Activarlo requiere cablear `authSessionProvider` con la navegación y agregar `user_id` al modelo.
- **`FeederCard` asume un único dispenser**. Si en el futuro hay más de un device tipo `feeder`, la UI debe manejarlo (hoy renderiza uno por cada uno, pero `Env.dispenserAlias` es singular).

## Operación

- **Bridge TP-Link congelado** (ver `05-bridge-iot.md`). No se actualiza, no se prueba. Si querés volver a usarlo, hay que validar que sigue corriendo contra Supabase y que las credenciales se moverieron fuera del código.
- **Calibración del HX711** está placeholder (`CALIBRATION = 1.0f` en `firmware/anyalink_node/src/main.cpp`). Hay que ajustarla con un peso conocido cuando esté el hardware ensamblado.
- **Sin watchdog ni OTA en el firmware**. Si la conexión MQTT cae, el reconnect del bridge funciona, pero un cuelgue serio requiere reset físico. Para flashear cambios hay que conectar USB.
- **Sin servicio para Node-RED**. Hoy corre desde consola (`node-red`). Si querés que arranque solo al boot, hay que configurarlo como tarea programada o servicio.
- **Duplicado del row `Dispensador`** en Supabase: la migration corrió dos veces sin uniqueness constraint en `alias`. El UUID activo es `895ab217-8fce-47c7-9c2a-96d07136f5d6`. El duplicado se puede borrar con `delete from devices where id = 'ae7b2115-e718-4f5d-8b0f-32c9a23441a9';`.

## Quality

- **`Env.addDemoTiles`** sigue en `true`. Agrega tiles falsos en el home si no aparecen los reales por alias. Útil para demo, ruidoso para producción.
- **Asset de cámara** (`assets/sample/camera.jpg`) no está declarado en `pubspec.yaml`. En algunas plataformas no carga.
- **`print` en el repo** para debug. Habría que pasar a `logger` o eliminarlos antes de un release.
- **Sin tests de error**: no hay cobertura para failure de Supabase, RLS bloqueante, broker caído, ESP32 desconectado.

## Fuera de alcance documentado (futuro)

Ver `08-informacion-extra-chatgpt.md`. Pendientes que NO son parte del MVP:

- Auth real + RBAC + multi-usuario.
- ESP32-CAM + streaming + visión por computadora.
- Rutinas programadas, alertas push.
- Tablas `routines`, `feeding_events`, `alerts`.
- OTA del firmware.
- Migración a HTTPS/TLS en MQTT.
