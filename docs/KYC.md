# 🪪 Verificación facial de identidad (Tarea 2)

Documenta el flujo de KYC (selfie vs. INE/pasaporte) introducido en el registro. Aplica a **YOER y Cliente** por igual (decisión confirmada explícitamente con el usuario).

## 1. Flujo

```
Registro (signUp exitoso)
    ↓
/kyc → KycConsentScreen (checkbox obligatorio)
    ↓
KycIdCaptureScreen (cámara trasera + recorte con image_cropper)
    ↓
KycSelfieCaptureScreen (cámara frontal)
    ↓
KycRepository.verifyIdentity() → yofreelancer-kyc-service (proyecto separado, FastAPI + DeepFace)
    ↓
kycStatus se persiste en profiles.kyc_status vía AuthRepository.updateProfile()
    ↓
Router: kycStatus == verified → deja pasar; si no, vuelve a /kyc
```

El gate se aplica en `lib/app/router/app_router.dart`: cualquier usuario autenticado con `kycStatus != verified` es redirigido a `/kyc` sin importar la ruta a la que intente ir.

## 2. Contrato de fallo cerrado ("fail closed")

Ni el cliente Flutter ni el microservicio asumen "verificado" por omisión:

- El microservicio (`yofreelancer-kyc-service`) solo responde `match: true` si `DeepFace.verify()` corrió sin error y la distancia quedó por debajo del umbral. Cualquier excepción, imagen sin rostro detectado, o timeout produce una respuesta de error (4xx/5xx), nunca un `match: true` accidental.
- El cliente (`KycRemoteDataSource.verifyIdentity`) trata **cualquier** no-2xx, timeout (20s), error de red o JSON inválido como "no verificado" (`KycResult.error()`), nunca como verificado.
- El estado resultante (`verified`/`rejected`/`error`) se persiste siempre en `profiles.kyc_status` — nunca se deja el campo sin actualizar esperando que "probablemente pasó".

## 3. Verificación facial (`yofreelancer-kyc-service`)

- FastAPI + DeepFace (modelo ArcFace, backend de detección RetinaFace, métrica coseno).
- Las imágenes se decodifican directo a memoria (`cv2.imdecode`) y **nunca se escriben a disco**. No hay política de retención que aplicar porque no hay persistencia que retener.
- Umbral de similitud configurable (`SIMILARITY_THRESHOLD`, default `0.32`) — **este valor es un punto de partida y debe calibrarse con muestras reales de INE/pasaporte mexicanos antes de producción**, no fue validado con datos reales en esta sesión.
- Liveness: por ahora es un stub (`app/liveness.py`) que siempre devuelve `status="skipped"`. La ruta de mejora recomendada y documentada en el código es activar `anti_spoofing=True` en `DeepFace.extract_faces` (parámetro real de la librería) cuando se priorice.
- Solo se guarda un registro de auditoría no biométrico (`kyc_verifications`: `request_id, user_id, match, similarity, model, threshold, timestamp`) — nunca las imágenes.

**`yofreelancer-kyc-service` es un proyecto standalone en su propio repo Git**, separado tanto de esta app móvil como del backend Node (`yofreelancer-backend`) — no vive dentro de este repo. La app lo llama **directo** por su propia URL (`KycConfig.baseUrl`, configurable con `--dart-define=KYC_SERVICE_URL=...`), nunca a través del backend Node como proxy: no hay una razón de peso para meter a Node en medio, y hacerlo solo agregaría latencia y acoplamiento. Ver su propio `README.md` para cómo levantarlo en local y correr sus pruebas.

## 4. Consentimiento

Texto mostrado antes de capturar cualquier foto (`KycConsentScreen`), con checkbox obligatorio:

> "Antes de continuar necesitamos verificar tu identidad para proteger a la comunidad de YO FREE-LANCER. Te pediremos: 1) una foto de tu identificación oficial (INE o pasaporte), 2) una selfie tuya en este momento. Estas imágenes se procesan de forma automática para comparar tu rostro con el de tu identificación y no se almacenan: se procesan en memoria y se descartan de inmediato. Solo conservamos el resultado (verificado / no verificado) asociado a tu cuenta."

## 5. Decisión: usuarios existentes quedan exentos (grandfathering)

La migración de `kyc_status` en `supabase_schema.sql` corre un backfill dentro de un bloque `do $$ ... end $$` que solo se ejecuta la primera vez que se agrega la columna: en ese momento, marca `kyc_status = 'verified'` para **todas las filas que ya existían**. El gate del router (`kycStatus != verified` → `/kyc`) por lo tanto solo afecta de verdad a cuentas creadas **después** de este despliegue.

**Por qué**: no romper el acceso de usuarios ya activos de un día para otro (regla general del proyecto: "no rompas funcionalidad existente"). Los usuarios nuevos sí pasan por el flujo completo de verificación facial desde su registro.

**Importante para quien despliegue este schema**: el backfill es de una sola vez, gatillado por la ausencia previa de la columna `kyc_status` — si el script se vuelve a ejecutar después del primer despliegue (es idempotente para el resto del schema), el `if not exists` evita que se vuelva a marcar `verified` a cuentas nuevas que legítimamente siguen en `pending`.

## 6. Pendiente / fuera de alcance de esta entrega

- Calibración real del umbral de similitud con datos mexicanos.
- Liveness real (más allá del stub).
- Hosting en producción de `yofreelancer-kyc-service` (no decidido).
- El microservicio no tiene su propio "respaldo": si no responde, la verificación simplemente no se completa (fallo cerrado) — esto es el comportamiento correcto por diseño, no un pendiente.
