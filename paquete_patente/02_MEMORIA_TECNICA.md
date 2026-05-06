# Memoria Tecnica - Verdemeta

## 1. Resumen ejecutivo
Verdemeta es una aplicacion orientada al seguimiento nutricional y de habitos, con enfoque en alimentacion basada en plantas. El sistema permite registrar alimentos, calcular indicadores diarios y consultar informacion historica para apoyo a decisiones de salud y nutricion.

## 2. Problema que resuelve
El software atiende la necesidad de registrar y analizar consumo alimentario de forma estructurada, especialmente para usuarios que siguen un estilo de vida vegano o plant-based y requieren trazabilidad diaria de sus metas nutricionales.

## 3. Descripcion funcional
Funciones principales:
- Registro de alimentos consumidos.
- Gestion de base de datos de alimentos.
- Seguimiento de metricas/objetivos diarios.
- Pantallas de autenticacion y perfil.
- Notificaciones para recordatorios diarios.

## 4. Arquitectura y componentes
Implementaciones identificadas en el repositorio:
- Frontend web: `index.html`, `css/`, `js/`.
- Migracion Flutter: `flutter-migration/lib/` con capas por modulos (presentacion, dominio, datos y servicios).
- Persistencia: scripts SQL y capa de acceso a datos (`flutter-migration/database/`, `lib/database/`).

## 5. Tecnologias utilizadas
- Flutter / Dart.
- HTML, CSS y JavaScript.
- SQLite (segun estructura y scripts de base de datos).
- Android build tooling (Gradle/Kotlin configs dentro de `flutter-migration/android/`).

## 6. Alcance de la entrega
Se entrega codigo fuente y documentacion tecnica asociada a la version:
- Version: [VERSION]
- Fecha de corte: [FECHA]
- Branch de referencia: `tst`

## 7. Elementos de originalidad (completar)
Describir en detalle los aspectos tecnicos que consideras novedosos:
- [ASPECTO 1]
- [ASPECTO 2]
- [ASPECTO 3]

Nota: esta seccion debe redactarse con precision tecnica y revision legal, ya que sera clave en cualquier analisis de patentabilidad.

## 8. Limitaciones y dependencias
- El sistema puede depender de bibliotecas de terceros con sus propias licencias.
- La proteccion sobre codigo propio no transfiere derechos sobre componentes de terceros.

## 9. Evidencia de autoria y fecha
Adjuntar en anexos:
- Historial de versiones (commits, tags o bitacora de cambios).
- Constancias de fecha (sello digital/notarial/registro oficial).
- Identificacion de autores y porcentaje de contribucion (si aplica).
