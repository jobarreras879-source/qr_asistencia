# QR Asistencia AVS

Aplicacion Flutter para control de asistencia con escaneo QR, historial operativo
y sincronizacion opcional con Google Drive y Google Sheets.

## Release estable

Este repositorio queda marcado como la base estable final de AVS.

- Version funcional: `1.3.0`
- Build de release: `4`
- Estado: `Estable`
- Hito: `Rediseño final AVS`

## Stack principal

- Flutter
- Supabase
- Google Sign-In
- Google Drive API
- Google Sheets API

## APK release

El APK firmado de Android se genera con:

```bash
flutter build apk --release
```

Salida esperada:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Nota de continuidad

Esta base queda reservada para AVS. A partir de este punto, la version general
para venta a multiples clientes debe continuar sobre una nueva base de datos y,
si lo deseas, sobre una nueva rama o repositorio derivado de este estado.
