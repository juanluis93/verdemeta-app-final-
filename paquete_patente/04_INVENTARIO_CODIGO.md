# Inventario de Codigo Fuente Entregado

## Identificacion
- Proyecto: Verdemeta
- Repositorio: Verdemeta-
- Branch de referencia: `tst`
- Fecha de inventario: 2026-04-22
- Responsable: [NOMBRE]

## Archivos y carpetas principales incluidos
- `README.md`
- `index.html`
- `css/`
- `js/`
- `flutter-migration/pubspec.yaml`
- `flutter-migration/lib/`
- `flutter-migration/test/`
- `flutter-migration/database/`
- `flutter-migration/android/` (solo fuentes y configuracion)
- `paquete_patente/06_FOTO_CODIGO_FUENTE_20260422.txt` (fotografia integral del codigo fuente)

## Exclusiones recomendadas para el ZIP legal
No incluir artefactos generados ni binarios:
- `flutter-migration/build/`
- `flutter-migration/recovered_from_apk/`
- carpetas `generated/`, `outputs/`, `intermediates/`, `tmp/`
- caches y archivos temporales de IDE

## Huella de integridad (opcional pero recomendado)
Adjuntar hash del ZIP final para integridad documental:
- SHA-256: [PEGAR HASH]

## Generacion automatica del ZIP y hash
Se incluye el script:
- `paquete_patente/generar_paquete_fuente.ps1`

Comando:
- `powershell -ExecutionPolicy Bypass -File .\\paquete_patente\\generar_paquete_fuente.ps1`

## Nota
Este inventario se entrega como referencia del contenido fuente remitido en el expediente.
