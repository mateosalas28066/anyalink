# Documentación funcional de AnyaLink

Refleja el estado actual del MVP. Cuando cambies algo en el código, actualizá la doc correspondiente.

## Lectura recomendada

1. [Resumen del proyecto](01-resumen-proyecto.md)
2. [Arquitectura](02-arquitectura.md)
3. [Funcionalidades](03-funcionalidades.md)
4. [Supabase y datos](04-supabase-y-datos.md)
5. [Bridge IoT (TP-Link, congelado)](05-bridge-iot.md)
6. [Desarrollo y testing](06-desarrollo-y-testing.md)
7. [Pendientes y riesgos](07-pendientes-y-riesgos.md)
8. [Visión y roadmap](08-informacion-extra-chatgpt.md)

## READMEs específicos

- Firmware ESP32: [`firmware/anyalink_node/README.md`](../firmware/anyalink_node/README.md)
- Infra local (Mosquitto + Node-RED): [`infra/README.md`](../infra/README.md)

## Estado actual en una frase

App Flutter que muestra dispositivos desde Supabase y comanda un ESP32 dispensador (servo + sensores HX711/DHT22) vía un broker MQTT local puenteado a Supabase por Node-RED.

## Nota sobre documentación histórica

`AnyaLink_Documentation.md` se mantiene como referencia. Algunas capacidades descritas allí (RBAC, rutinas programadas, alertas push, ESP32-CAM) son futuras, no parte del MVP.
