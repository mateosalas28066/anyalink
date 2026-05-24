# Documentacion Funcional de AnyaLink

Esta carpeta resume el estado real del proyecto segun el codigo actual. Sirve para retomar el desarrollo sin depender de memoria ni de documentacion historica que pueda estar desactualizada.

## Lectura recomendada

1. [Resumen del proyecto](01-resumen-proyecto.md)
2. [Arquitectura](02-arquitectura.md)
3. [Funcionalidades](03-funcionalidades.md)
4. [Supabase y datos](04-supabase-y-datos.md)
5. [Bridge IoT](05-bridge-iot.md)
6. [Desarrollo y testing](06-desarrollo-y-testing.md)
7. [Pendientes y riesgos](07-pendientes-y-riesgos.md)

## Estado actual en una frase

AnyaLink es una app Flutter que muestra un dashboard de dispositivos desde Supabase, permite cambiar estados con UI optimista y se apoya en scripts Python para sincronizar esos estados con hardware local TP-Link.

## Nota sobre documentacion historica

`AnyaLink_Documentation.md` se mantiene como referencia historica. Algunas partes mencionan capacidades como Node-RED, RBAC, rutinas o auditoria que no aparecen implementadas en el codigo actual revisado.
