# Pendientes y Riesgos

## Seguridad

- Hay credenciales hardcodeadas en Dart y Python.
- La documentacion nueva no copia esos valores, pero el codigo debe migrarlos a configuracion segura.
- El bridge unificado parece usar una llave privilegiada en codigo. Eso debe corregirse antes de cualquier uso compartido o despliegue.

## Arquitectura

- Hay dos rutas de repositorio:
  - `domain` + `data`, con `DevicesRepository`.
  - `infrastructure/supabase`, con `DeviceRepositorySupabase`.
- La UI actual usa la segunda ruta. Conviene decidir una sola arquitectura para evitar cambios duplicados.

## Autenticacion

- `LoginPage` y providers de Auth existen.
- `AuthGate` no usa la sesion y manda directo a `HomePage`.
- Si se quiere login real, hay que conectar `authSessionProvider` con navegacion y estados de carga/error.

## Assets

- `CameraCard` carga `assets/sample/camera.jpg`.
- `pubspec.yaml` no declara assets activos.
- En algunas plataformas el asset puede no cargar hasta declararlo.

## Documentacion historica

`AnyaLink_Documentation.md` menciona capacidades que no aparecen conectadas en el codigo revisado:

- Node-RED.
- RBAC.
- Rutinas.
- Auditoria.
- Solicitudes de dispositivos.

Debe tratarse como vision o referencia historica, no como fuente unica de verdad.

## Operacion del bridge

- El bridge depende de red local, discovery TP-Link y Supabase disponible.
- No hay servicio, supervisor ni instalador definido.
- Si el bridge se detiene, la app puede seguir escribiendo Supabase, pero el hardware no recibira cambios.

## Calidad pendiente

- Evitar prints directos en repositorios productivos.
- Revisar encoding de textos existentes con caracteres corruptos.
- Agregar pruebas para error de Supabase, estado vacio, demo tiles y AuthGate cuando se active login.
- Documentar o crear migraciones SQL para la tabla `devices`.
