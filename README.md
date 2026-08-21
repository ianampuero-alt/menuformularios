# CRM Arriendos · ALO Group — v2

Migración del proyecto AppSheet a front-end propio sobre **n8n → SAP Business One
Service Layer**.

Esta v2 no reescribe las pantallas: conserva las 11 páginas tal como estaban y les
agrega la **capa común que faltaba** (`js/app.js`), más las correcciones necesarias
para que los módulos se hablen entre sí.

---

## 1. Qué estaba roto

| # | Problema | Efecto real | Estado |
|---|----------|-------------|--------|
| 1 | **`js/app.js` no existía.** `clientes.html`, `Oportunidades.html`, `Oferta.html` y `Contrato.html` lo cargaban con `<script src="js/app.js">` y llamaban 15 métodos `app.*` | Los 4 módulos internos estaban **completamente muertos**: cada botón lanzaba `app is not defined` | ✅ Creado |
| 2 | **Dos vocabularios de sesión sin puente.** El portal del cliente escribía `sapRut` / `sapClientData`; el lado interno leía `alo_client_rut` / `alo_card_code` / `alo_client_name` | `cotizacion.html` mostraba siempre "Seleccionar Cliente" y no autocompletaba nada | ✅ Puente bidireccional |
| 3 | **Claves leídas pero nunca escritas.** `alo_sucursal`, `alo_user_name`, `alo_sales_person` | Vendedor y sucursal nunca se autocompletaban | ✅ Se guardan en el login |
| 4 | **Enlaces con mayúsculas mal escritas.** `href="contrato.html"` y `href="oportunidades.html"` vs. archivos `Contrato.html` / `Oportunidades.html` | **404 en cualquier servidor Linux** (nginx, Apache, GitHub Pages). Solo funcionaba en Windows | ✅ Corregidos |
| 5 | **`Oferta.html` huérfana.** Estaba completa pero el dashboard la tenía como `href="#"` + "Próximamente" | Módulo inalcanzable | ✅ Habilitada |
| 6 | **Menús inconsistentes.** `clientes` mostraba 3 enlaces, `Oportunidades` 5, `Oferta` ninguno | Se perdían módulos según dónde estuvieras | ✅ Menú único de 7, generado por `app.buildNav()` |
| 7 | **Guardia de sesión comentada** en `dashboard.html` (`// window.location.href`) | Se entraba al dashboard sin autenticarse | ✅ Activada |
| 8 | **5 parsers distintos** para las respuestas de n8n (`result.data`, `result.contratos`, `result.facturas`, `result._control`, array pelado) | Cada página fallaba distinto | ✅ Normalizador único en `Api.call()` |
| 9 | **`formulario.html` crasheaba** si Materialize no cargaba: `input.closest('.select-wrapper')` → `null.classList` | Formulario del cliente inutilizable sin CDN | ✅ Fallback al input |
| 10 | **Sin red = página en blanco.** `M.*` y `Swal.*` sin protección | `M is not defined` / `Swal is not defined` | ✅ Stubs degradados en `app.js` |

---

## 2. Estructura

```
v2/
├── js/app.js          ← núcleo compartido (cargar SIEMPRE primero)
├── index.html         login: cliente por RUT+OTP / vendedor por email+OTP
├── dashboard.html     home del vendedor (6 módulos)
├── clientes.html      búsqueda de clientes en SAP
├── Oportunidades.html pipeline comercial + KPIs
├── cotizacion.html    cotización de arriendo (VID_RTCOT)
├── Oferta.html        oferta de venta con líneas de ítems
├── Contrato.html      contrato de arriendo desde cotización (VID_RTOV)
├── menucliente.html   home del portal del cliente
├── historicoc.html    estado de cuenta, flota, solicitudes
├── formulario.html    actualización de datos del cliente
└── mantencionretiro.html  solicitud de mantención / retiro
```

### `js/app.js` en cinco bloques

1. **CONFIG** — base de n8n y mapa de endpoints en **un solo lugar**.
2. **SESIÓN** — claves unificadas, puente con las legadas, `rutToCardCode()`, `formatRut()`.
3. **API** — cliente HTTP con timeout de 45 s que aplana toda respuesta a
   `{ ok, list, obj, message, raw }`.
4. **UI** — toast, loader, `clp()`, `fecha()`, `toISO()`, `esc()` (anti-XSS), badges.
5. **APP** — los 15 métodos `app.*` que el HTML ya invocaba.

---

## 3. Endpoints de n8n

### Ya existentes (sin cambios)

| Clave | Ruta |
|---|---|
| `processEmail` | `/webhook/sap/processEmail` |
| `validateOTP` | `/webhook/sap/validateOTP` |
| `getContratos` | `/webhook/get-contratos` |
| `getContratosFlota` | `/webhook/get-contratos-flota` |
| `getFinanzas` | `/webhook/get-finanzas` |
| `getSolicitudes` | `/webhook/get-solicitudes` |
| `solicitudesSap` | `/webhook/solicitudes-sap` |
| `updateBP` | `/webhook/sap/updateBP` |
| `cotizacionCrear` | `/webhook/cotizaciones/procesar` |

### ⚠️ Por crear en n8n

Todos son **POST** con `Content-Type: application/json`.

#### `/webhook/clientes/buscar`
```jsonc
// entrada
{ "rut": "76721028-0", "cardCode": "C767210280", "cardName": "", "userEmail": "..." }
// salida
{ "success": true, "clientes": [
  { "CardCode": "C767210280", "LicTradNum": "767210280",
    "CardName": "CONSTRUCTORA ANDES SPA",
    "PayTermsGrpName": "30 días", "U_EstadoTrib": "VIGENTE" } ] }
```

#### `/webhook/oportunidades/listar`
```jsonc
// entrada
{ "texto": "", "estado": "O", "etapa": "4", "userEmail": "..." }
// salida — de OOPR
{ "success": true, "oportunidades": [
  { "OpprId": 412, "CardCode": "C767210280", "CardName": "...",
    "Remarks": "BRAZO ART 40 MTS", "SalesPerson": "ian@alo-group.com",
    "SalesStage": "4", "MaxSumLoc": 8400000,
    "PredDate": "2026-09-30", "Status": "O" } ] }
```
`Status`: `O` abierta · `W` ganada · `L` perdida.
`SalesStage`: `1` Prospecto 5% · `3` Cotizado 20% · `4` Negociación 50% · `5` Cierre 90%.
Los KPIs (potencial y **ponderado** = potencial × % de etapa) se calculan en el front.

#### `/webhook/oportunidades/crear`
```jsonc
// entrada
{ "cardCode":"C767210280", "cardName":"...", "rut":"76721028-0",
  "nombre":"BRAZO ART 40 MTS - CHILLÁN", "salesStage":"1",
  "potencial": 8400000, "fechaCierre":"2026-09-30",
  "vendedorEmail":"...", "comentarios":"", "sucursal":"SANTIAGO" }
// salida
{ "success": true, "data": { "opprId": 414 } }
```

#### `/webhook/ofertas/listar`
```jsonc
{ "texto": "", "estado": "O", "userEmail": "..." }
// salida — de Quotations
{ "success": true, "ofertas": [
  { "DocNum":9001, "CardCode":"C767210280", "CardName":"...",
    "DocDate":"2026-08-01", "DocDueDate":"2026-08-31",
    "SalesPerson":"...", "DocTotal":5300000, "DocStatus":"O" } ] }
```

#### `/webhook/ofertas/crear`
```jsonc
{ "cardCode":"...", "cardName":"...", "rut":"...",
  "docDate":"2026-08-21", "docDueDate":"2026-09-20",
  "referencia":"OC 4521", "vendedorEmail":"...", "sucursal":"SANTIAGO",
  "opprId": 412,                       // null si no viene de una oportunidad
  "lineas":[ { "itemCode":"COP010203", "quantity":3, "unitPrice":250000 } ] }
// salida
{ "success": true, "data": { "docNum": 9002 } }
```
El IVA **no** se envía: se calcula en SAP al guardar.

#### `/webhook/cotizaciones/obtener`
```jsonc
{ "docNum": "135183", "docEntry": "135183", "userEmail": "..." }
// salida
{ "success": true, "data": {
  "CardCode":"C767210280", "LicTradNum":"767210280",
  "CardName":"CONSTRUCTORA ANDES SPA", "PayTermsGrpName":"30 días",
  "PayToCode":"Casa Matriz", "Address":"Ruta 5 Sur km 12",
  "SalesPerson":"...", "U_Sucursal":"SANTIAGO" } }
```

#### `/webhook/contratos/crear`
```jsonc
{ "docCotizacion":"135183", "cardCode":"...", "cardName":"...", "rut":"...",
  "condPago":"30 días", "destFact":"Casa Matriz", "destFAddr":"Ruta 5 Sur km 12",
  "fechaInicio":"2026-09-01", "fechaTermino":"2026-12-01",
  "observaciones":"", "vendedorEmail":"...", "sucursal":"SANTIAGO" }
// salida
{ "success": true, "data": { "docNum": 7301 } }
```

### Convención de respuesta (importante)

`Api.call()` acepta cualquiera de estas formas, pero **lo ideal es unificar** en n8n:

```jsonc
{ "success": true,  "data": { ... } }          // o "list"/"clientes"/...
{ "success": false, "message": "motivo legible para el usuario" }
```

Para **frenar un proceso por regla de negocio** (cliente moroso, descuento sobre el
tope autorizado, etc.), n8n debe responder:

```jsonc
{ "_control": { "continue": false, "message": "Cliente con saldo vencido" } }
```

El front muestra `Proceso detenido: <message>` y **mantiene el modal abierto con los
datos escritos**, para que el vendedor corrija sin re-tipear.

---

## 4. Flujos que ya quedan conectados

```
Clientes ──[Cotizar]──────────────► Cotización   (cliente en contexto)
         └─[Ficha]───────────────► Situación comercial

Oportunidades ──[Cotizar]────────► Cotización   (+ alo_oppr_id, muestra el banner
                                                  y lo envía en el payload)

Oferta ──[A contrato]────────────► Contrato     (precarga el N° y trae los datos solo)

Contrato ──[Generar]─────────────► SAP ─► vuelve al Dashboard
```

Antes de la v2 **ninguna** de estas flechas existía: no había forma de pasar el
cliente de un módulo a otro.

---

## 5. Cómo probarlo

`js/app.js` es un archivo estático; se puede abrir con doble clic, pero conviene
servirlo por HTTP para que el navegador no bloquee los `fetch`:

```bash
cd v2
python -m http.server 8080
# http://localhost:8080/index.html
```

**Publicación:** cualquier hosting estático (nginx, IIS, Netlify, GitHub Pages).
En n8n hay que habilitar **CORS** para el dominio donde quede publicado, o los
`fetch` se bloquean.

---

## 6. Pendientes conocidos

- **Los 7 webhooks de la sección 3** todavía no existen en n8n. Hasta crearlos, esos
  módulos muestran *"No se pudo conectar con el webhook"* — que es el comportamiento
  correcto, no un error del front.
- **CSS duplicado**: cada HTML lleva su propio `<style>` (~35 KB) y el logo en base64
  repetido 11 veces. Funciona, pero extraerlo a `css/alo.css` + `img/logo.png`
  bajaría el peso total de ~1,1 MB a menos de 200 KB. No lo toqué para no arriesgar
  el diseño en este paso.
- **`cotizacion.html`** conserva su propio `fetch` en vez de usar `app.api`. Funciona
  igual; unificarlo es cosmético.
- **OTP**: el login depende de `processEmail` / `validateOTP`. Si SAP no responde, no
  hay modo de acceso alternativo.

---

## 7. Verificación ejecutada

Las 11 páginas se cargaron en Chromium con los webhooks simulados:

- **0 errores de JavaScript** en las 11 páginas.
- Los **15 métodos** `app.*` que el HTML invoca existen y responden.
- Puente de sesión: `sapRut` + `sapClientData` → `{rut, nombre, cardCode}` ✔
- `cotizacion.html` autocompleta CardCode, vendedor, sucursal y badge del cliente ✔
- KPIs de oportunidades: potencial $8.400.000 → ponderado $4.200.000 (etapa 50%) ✔
- Total de oferta: 3 × $250.000 = $750.000 ✔
- Freno `_control.continue:false` → toast de error **sin** cerrar el modal ✔
- Webhook caído → mensaje legible, sin excepción ✔
- Validaciones locales (N° de cotización vacío, fecha de término < inicio) → **0
  llamadas** a SAP ✔
- Dashboard sin sesión → redirige a `index.html` ✔
- Sin CDN (Materialize/SweetAlert bloqueados) → las páginas siguen operativas ✔
