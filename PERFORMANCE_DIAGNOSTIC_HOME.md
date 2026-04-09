# Diagnostico de rendimiento: Inicio y Home

Esta instrumentacion agrega trazas con prefijo `[PERF]` para medir el costo de arranque, restauracion de sesion, carga de Home y campañas.

## Como correr la medicion

1. Usa un dispositivo Android fisico cuando sea posible.
2. Ejecuta la app en modo profile:

```powershell
flutter run --profile
```

3. Observa la consola de Flutter y filtra las lineas con `[PERF]`.
4. Repite cada escenario 5 veces.

## Escenarios a medir

### 1. Arranque frio

- Cierra la app completamente.
- Abrela de nuevo.
- Mide desde `app_bootstrap` hasta `home_load_data ... first_useful_frame`.

### 2. Resume a Home

- Abre la app y llega a Home.
- Manda la app al background 10 a 15 segundos.
- Vuelve a abrirla.
- Revisa las trazas `home_load_data` con `reason=resume`.

### 3. Red lenta o inestable

- Repite arranque o resume con Wi-Fi inestable o datos moviles.
- Revisa si los tiempos altos se concentran en:
  - `ProjectService.getProyectos`
  - `AttendanceService.getTodayCount`
  - `AppCampaignService.listCampaigns`
  - `home_connectivity lookup_complete`

## Trazas mas importantes

- `app_bootstrap`
  - `main_entered`
  - `bindings_ready`
  - `supabase_initialize`
  - `material_app_built`
  - `first_frame`

- `login_screen`
  - `first_frame`
  - `login_restore_session`
  - `login_submit`

- `home_load_data`
  - `_refreshSession`
  - `parallel_fetch_home_data`
  - `first_useful_frame`

- `home_fetch_data`
  - `ProjectService.getProyectos`
  - `AttendanceService.getTodayCount`
  - `before_set_state`
  - `after_set_state`
  - `post_fetch_frame`

- `home_load_campaigns`
  - `AppCampaignService.listCampaigns`
  - `before_set_state`
  - `after_set_state`

- `home_maybe_start_campaign_flow`
  - confirma si modal o tooltip estan afectando la entrada a Home

## Plantilla de reporte

Usa esta tabla para resumir los 5 intentos:

| Escenario | Tramo | Intento 1 | Intento 2 | Intento 3 | Intento 4 | Intento 5 | Promedio |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Arranque frio | app_bootstrap -> first_frame |  |  |  |  |  |  |
| Arranque frio | home_load_data total |  |  |  |  |  |  |
| Arranque frio | ProjectService.getProyectos |  |  |  |  |  |  |
| Arranque frio | AttendanceService.getTodayCount |  |  |  |  |  |  |
| Arranque frio | AppCampaignService.listCampaigns |  |  |  |  |  |  |
| Resume | home_load_data total |  |  |  |  |  |  |
| Resume | AppCampaignService.listCampaigns |  |  |  |  |  |  |
| Resume | home_connectivity lookup_complete |  |  |  |  |  |  |

## Que buscar

- Si `home_load_data` es alto pero `ProjectService`, `AttendanceService` y campañas son bajos:
  - el problema es mas de orquestacion o render.

- Si `AttendanceService.getTodayCount` domina:
  - el cuello esta en la consulta a `registros`.

- Si `AppCampaignService.listCampaigns` domina:
  - el problema esta en Edge Functions, sesion o carga repetida de campañas.

- Si `home_connectivity lookup_complete` aparece lento seguido:
  - el polling de internet esta aportando costo innecesario.

- Si `reason=resume` se parece a un arranque frio:
  - Home esta recargando mas de lo necesario al volver del background.
