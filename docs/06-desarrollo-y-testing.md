# Desarrollo y Testing

## Setup basico

```powershell
flutter pub get
flutter run
```

La app inicializa Supabase en `main.dart`, por lo que la configuracion en `Env` debe ser valida para correr contra datos reales.

## Dependencias relevantes

- `flutter_riverpod`: providers, streams y overrides de pruebas.
- `supabase_flutter`: cliente Supabase, Auth y Realtime.
- `flutter_test`: pruebas de widgets.
- Python bridge: depende de `python-kasa` y `requests`.

## Tests existentes

```powershell
flutter test
```

Pruebas actuales:

- `widget_test.dart`: smoke test neutro.
- `smoke_theme_test.dart`: monta `AnyaLinkApp`.
- `home_presence_test.dart`: verifica `AnyaLink` y `Lampara`.
- `list_presence_test.dart`: verifica `Dispositivos`.
- `device_toggle_test.dart`: verifica toggle mock de apagado a encendido.

## Fake repo de tests

`test/helpers/test_app.dart` crea un `ProviderScope` que sobreescribe `deviceRepoProvider` con `_FakeDeviceRepo`.

Ese fake:

- Mantiene estado en memoria.
- Emite lista de un dispositivo con alias de `Env.lightAlias`.
- Implementa `getAll`, `getByAlias`, `setStateByAlias`, `setStateById`, `watchAll` y `watchStateByAlias`.

Esto permite probar UI sin Supabase real.

## Checklist antes de continuar desarrollo

- Ejecutar `flutter test`.
- Probar `flutter run` en la plataforma objetivo.
- Confirmar si se usara polling o Realtime.
- Confirmar que `devices` tiene filas con `id`, `alias`, `type` y `state`.
- Verificar que el asset de camara este declarado en `pubspec.yaml` antes de depender de el.
- Mover credenciales fuera del codigo antes de compartir o desplegar.
