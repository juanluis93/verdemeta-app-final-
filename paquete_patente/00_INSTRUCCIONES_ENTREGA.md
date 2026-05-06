# Paquete de Presentacion - Verdemeta

Este paquete contiene la documentacion recomendada para presentar el software "Verdemeta" ante una oficina de propiedad intelectual o con asesoria legal especializada.

## Objetivo
Dejar evidencia clara de:
- autoria
- fecha
- alcance tecnico
- codigo fuente entregado

## Orden sugerido de envio
1. `01_CARTA_PRESENTACION.md` (pasar a PDF con firma)
2. `02_MEMORIA_TECNICA.md` (pasar a PDF)
3. `03_DECLARACION_AUTORIA.md` (firmada)
4. `04_INVENTARIO_CODIGO.md`
5. `05_ANEXOS_Y_CHECKLIST.md`
6. ZIP del codigo fuente (sin binarios ni carpetas de build)

## Formato recomendado de entrega
- Documento principal en PDF.
- Anexos tecnicos en PDF.
- Codigo fuente en archivo ZIP.
- Nombre sugerido del ZIP: `VERDEMETA_CODIGO_FUENTE_YYYYMMDD.zip`

## Recomendacion legal importante
En la mayoria de jurisdicciones, el software se protege principalmente por derecho de autor.
La patente aplica solo en casos tecnicos muy especificos.
Antes de presentar, valida el expediente con un abogado de propiedad intelectual.

## Completado rapido
1. Reemplaza todos los campos entre corchetes, por ejemplo: `[NOMBRE COMPLETO]`.
2. Convierte a PDF los documentos que corresponda.
3. Firma los documentos requeridos.
4. Genera el ZIP con el script `generar_paquete_fuente.ps1`.
5. Adjunta el ZIP del codigo fuente y su archivo `.sha256.txt`.
6. Adjunta evidencia de fecha (constancia digital, notarial o equivalente oficial).

## Comando para generar ZIP + hash
Ejecuta en PowerShell desde la raiz del proyecto:

`powershell -ExecutionPolicy Bypass -File .\paquete_patente\generar_paquete_fuente.ps1`
