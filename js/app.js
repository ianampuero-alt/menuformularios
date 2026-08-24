/* =============================================================================
 * ALO Group · CRM de Arriendos — Núcleo compartido
 * -----------------------------------------------------------------------------
 * Este archivo es el que las páginas internas (clientes, Oportunidades, Oferta,
 * Contrato) ya esperaban con <script src="js/app.js"></script> pero que nunca
 * existió en la carpeta. Aquí vive TODO lo transversal:
 *
 *   1. CONFIG      — un único lugar con la base de n8n y el mapa de endpoints.
 *   2. SESIÓN      — claves unificadas + puente con las claves legadas
 *                    (sapRut / sapClientData) para que el portal del cliente y
 *                    el lado interno hablen el mismo idioma.
 *   3. API         — cliente HTTP que normaliza TODAS las formas de respuesta
 *                    que devuelven los distintos workflows de n8n.
 *   4. UI          — toast, loader, formateo de moneda/fecha es-CL.
 *   5. APP         — los 15 métodos app.* que invocan los onclick del HTML.
 *
 * Cargar este archivo en TODAS las páginas, antes del <script> propio de cada
 * una. No depende de jQuery ni de Materialize. Usa SweetAlert2 si está presente.
 * ========================================================================== */

(function (window, document) {
    'use strict';

    /* =========================================================================
     * 1. CONFIGURACIÓN
     * ---------------------------------------------------------------------
     * Un solo punto de verdad. Si cambia el tenant de n8n, se cambia aquí y
     * no en 11 archivos distintos.
     * ====================================================================== */

    var CFG = {
        N8N_BASE: 'https://alogroup.app.n8n.cloud',

        // Timeout por request. n8n + SAP Service Layer puede ser lento en
        // consultas de cartera, por eso 45s y no los 10s típicos.
        TIMEOUT_MS: 45000,

        EP: {
            // --- Autenticación (ya implementados en n8n) -------------------
            processEmail:      '/webhook/sap/processEmail',
            validateOTP:       '/webhook/sap/validateOTP',

            // --- Portal cliente (ya implementados en n8n) -----------------
            getContratos:      '/webhook/get-contratos',
            getContratosFlota: '/webhook/get-contratos-flota',
            getFinanzas:       '/webhook/get-finanzas',
            getSolicitudes:    '/webhook/get-solicitudes',
            solicitudesSap:    '/webhook/solicitudes-sap',
            updateBP:          '/webhook/sap/updateBP',

            // --- Lado interno / comercial ---------------------------------
            // OJO: estos son los que faltan por crear en n8n. El contrato de
            // entrada/salida de cada uno está documentado en README.md.
            cotizacionCrear:   '/webhook/cotizaciones/procesar',
            cotizacionGet:     '/webhook/cotizaciones/obtener',
            clientesBuscar:    '/webhook/clientes/buscar',
            oportListar:       '/webhook/oportunidades/listar',
            oportCrear:        '/webhook/oportunidades/crear',
            ofertaListar:      '/webhook/ofertas/listar',
            ofertaCrear:       '/webhook/ofertas/crear',
            contratoCrear:     '/webhook/contratos/crear'
        },

        // Etapas de oportunidad en SAP B1 (OOPR.SalesStage) con su ponderador.
        ETAPAS: {
            '1': { nombre: 'Prospecto',   pct: 5  },
            '3': { nombre: 'Cotizado',    pct: 20 },
            '4': { nombre: 'Negociación', pct: 50 },
            '5': { nombre: 'Cierre',      pct: 90 }
        },

        // Sucursales / territorios. Debe calzar con cotizacion.html.
        SUCURSALES: ['SANTIAGO', 'ANTOFAGASTA', 'CONCEPCION', 'VINA', 'PUERTO_MONTT']
    };

    function url(key) {
        var path = CFG.EP[key];
        if (!path) throw new Error('Endpoint no configurado: ' + key);
        return CFG.N8N_BASE + path;
    }


    /* =========================================================================
     * 2. SESIÓN
     * ---------------------------------------------------------------------
     * El proyecto venía con DOS vocabularios que no se conocían entre sí:
     *
     *   Portal cliente : sapRut, sapClientData
     *   Lado interno   : alo_client_rut, alo_card_code, alo_client_name,
     *                    alo_user_email, alo_sucursal, ...
     *
     * cotizacion.html leía alo_card_code / alo_client_name / alo_sucursal, pero
     * NADIE los escribía nunca -> el badge quedaba siempre en "Seleccionar
     * Cliente" y el formulario nunca se autocompletaba.
     *
     * Session.bridge() se ejecuta al cargar y sincroniza ambos vocabularios en
     * las dos direcciones, así cualquier página encuentra el contexto.
     * ====================================================================== */

    var K = {
        // usuario interno
        userEmail:   'alo_user_email',
        userName:    'alo_user_name',
        userRole:    'alo_user_role',
        salesPerson: 'alo_sales_person',
        sucursal:    'alo_sucursal',
        // cliente en contexto
        clientRut:   'alo_client_rut',
        clientName:  'alo_client_name',
        cardCode:    'alo_card_code',
        // documentos en tránsito
        opprId:      'alo_oppr_id',
        quotId:      'alo_quot_id',
        // legadas (portal cliente)
        legacyRut:   'sapRut',
        legacyData:  'sapClientData'
    };

    var Session = {
        get: function (k) {
            try { return sessionStorage.getItem(k); } catch (e) { return null; }
        },
        set: function (k, v) {
            try {
                if (v === null || v === undefined || v === '') sessionStorage.removeItem(k);
                else sessionStorage.setItem(k, String(v));
            } catch (e) { /* modo privado / storage bloqueado */ }
        },
        del: function (k) { try { sessionStorage.removeItem(k); } catch (e) {} },

        /**
         * Normaliza un RUT a CardCode de SAP: 76.721.028-0 -> C767210280
         * (misma regla que ya usaba historicoc.html, centralizada aquí).
         */
        rutToCardCode: function (rut) {
            if (!rut) return '';
            var raw = String(rut).replace(/[^0-9kK]/gi, '').toUpperCase();
            if (!raw) return '';
            return raw.charAt(0) === 'C' ? raw : 'C' + raw;
        },

        /** Formatea 767210280 -> 76.721.028-0 para mostrar en pantalla. */
        formatRut: function (rut) {
            if (!rut) return '';
            var raw = String(rut).replace(/[^0-9kK]/gi, '').toUpperCase();
            if (raw.length < 2) return raw;
            var dv = raw.slice(-1);
            var cuerpo = raw.slice(0, -1).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
            return cuerpo + '-' + dv;
        },

        /** Sincroniza vocabulario legado <-> unificado en ambas direcciones. */
        bridge: function () {
            // a) sapRut -> alo_client_rut / alo_card_code
            var legacyRut = Session.get(K.legacyRut);
            if (legacyRut && !Session.get(K.clientRut)) {
                Session.set(K.clientRut, legacyRut);
            }
            // b) sapClientData (JSON crudo de SAP) -> nombre + cardcode
            var raw = Session.get(K.legacyData);
            if (raw) {
                try {
                    var p = JSON.parse(raw);
                    var c = p && p.data ? p.data : p;
                    if (c) {
                        if (c.CardName && !Session.get(K.clientName)) Session.set(K.clientName, c.CardName);
                        if (c.CardCode && !Session.get(K.cardCode))   Session.set(K.cardCode, c.CardCode);
                    }
                } catch (e) { /* JSON corrupto: se ignora en silencio */ }
            }
            // c) al revés: si el lado interno fijó el cliente, que el portal lo vea
            var rut = Session.get(K.clientRut);
            if (rut && !Session.get(K.legacyRut)) Session.set(K.legacyRut, rut);

            // d) CardCode derivable del RUT si SAP no lo devolvió
            if (!Session.get(K.cardCode) && rut) {
                Session.set(K.cardCode, Session.rutToCardCode(rut));
            }
            // e) nombre visible del vendedor
            if (!Session.get(K.userName)) {
                var em = Session.get(K.userEmail);
                if (em) Session.set(K.userName, em.split('@')[0].replace(/[._]/g, ' '));
            }
        },

        /** Contexto del cliente actualmente seleccionado. */
        cliente: function () {
            return {
                rut:      Session.get(K.clientRut) || Session.get(K.legacyRut) || '',
                nombre:   Session.get(K.clientName) || '',
                cardCode: Session.get(K.cardCode) || ''
            };
        },

        /** Contexto del usuario interno (vendedor). */
        usuario: function () {
            return {
                email:    Session.get(K.userEmail) || '',
                nombre:   Session.get(K.userName) || Session.get(K.salesPerson) || '',
                rol:      Session.get(K.userRole) || 'comercial',
                sucursal: Session.get(K.sucursal) || ''
            };
        },

        /** Fija el cliente en contexto y lo propaga a AMBOS vocabularios. */
        setCliente: function (c) {
            if (!c) return;
            var rut = c.rut || c.RUT || c.U_RUT || c.LicTradNum || '';
            var cc  = c.cardCode || c.CardCode || Session.rutToCardCode(rut);
            var nom = c.nombre || c.CardName || c.name || '';
            Session.set(K.clientRut, rut);
            Session.set(K.cardCode, cc);
            Session.set(K.clientName, nom);
            Session.set(K.legacyRut, rut);
            // No pisar sapClientData si ya tiene el objeto completo de SAP
            // (Industria/Direccion/Contactos); solo crear el fallback si no existe.
            if (!Session.get(K.legacyData)) {
                Session.set(K.legacyData, JSON.stringify({ CardCode: cc, CardName: nom, LicTradNum: rut }));
            }
        },

        logout: function () {
            try { sessionStorage.clear(); } catch (e) {}
            window.location.href = 'index.html';
        }
    };


    /* =========================================================================
     * 3. CLIENTE API
     * ---------------------------------------------------------------------
     * Cada workflow de n8n devolvía su propia forma:
     *   { data: {...} }              (login)
     *   { success:true, contratos:[] }
     *   { facturas:[] } / { solicitudes:[] }
     *   { _control: { continue:false, message } }   (freno de negocio)
     *   [ ... ]                      (array pelado)
     *
     * api() aplana todo eso a UN contrato único:
     *   { ok:boolean, list:Array, obj:Object|null, message:string, raw:any }
     *
     * Así las vistas dejan de tener 5 parsers distintos.
     * ====================================================================== */

    function pickList(r) {
        if (Array.isArray(r)) return r;
        var keys = ['list', 'items', 'rows', 'results',
                    'clientes', 'oportunidades', 'ofertas', 'cotizaciones',
                    'contratos', 'facturas', 'solicitudes', 'equipos'];
        for (var i = 0; i < keys.length; i++) {
            if (Array.isArray(r[keys[i]])) return r[keys[i]];
        }
        if (Array.isArray(r.data)) return r.data;
        // n8n a veces envuelve como { data: { value: [...] } } (OData de SAP)
        if (r.data && Array.isArray(r.data.value)) return r.data.value;
        if (Array.isArray(r.value)) return r.value;
        return null;
    }

    var Api = {
        /**
         * @param {string} epKey  clave dentro de CFG.EP
         * @param {object} payload cuerpo JSON (se hace POST siempre, como el resto del proyecto)
         * @returns {Promise<{ok,list,obj,message,raw}>}
         */
        call: function (epKey, payload) {
            var endpoint = url(epKey);
            var ctrl = (typeof AbortController !== 'undefined') ? new AbortController() : null;
            var timer = ctrl ? setTimeout(function () { ctrl.abort(); }, CFG.TIMEOUT_MS) : null;

            return fetch(endpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload || {}),
                signal: ctrl ? ctrl.signal : undefined
            }).then(function (res) {
                if (timer) clearTimeout(timer);
                return res.text().then(function (txt) {
                    var body = null;
                    if (txt) { try { body = JSON.parse(txt); } catch (e) { body = { message: txt }; } }
                    return { res: res, body: body };
                });
            }).then(function (w) {
                var r = w.body || {};
                var res = w.res;

                // Freno explícito de negocio desde n8n
                var stopped = r._control && r._control.continue === false;
                var msg = r.message
                       || (r._control && r._control.message)
                       || (r.error && (r.error.message || r.error))
                       || '';

                var ok = res.ok && !stopped && r.success !== false;
                var list = pickList(r);
                var obj = null;
                if (!list) {
                    if (r.data && typeof r.data === 'object') obj = r.data;
                    else if (typeof r === 'object' && !Array.isArray(r)) obj = r;
                }

                if (!ok && !msg) {
                    msg = res.ok ? 'El proceso fue detenido por el servidor.'
                                 : ('Error ' + res.status + ' al llamar al webhook.');
                }
                return { ok: ok, list: list || [], obj: obj, message: msg, raw: r, status: res.status };
            }).catch(function (err) {
                if (timer) clearTimeout(timer);
                var msg = (err && err.name === 'AbortError')
                    ? 'La consulta a SAP superó el tiempo de espera. Intenta nuevamente.'
                    : 'No se pudo conectar con el webhook de n8n. Revisa tu conexión.';
                return { ok: false, list: [], obj: null, message: msg, raw: null, status: 0, error: err };
            });
        }
    };


    /* =========================================================================
     * 4. UI COMPARTIDA — loader, toast, formateo
     * ====================================================================== */

    var UI = {
        _loaderEl: null,

        _ensureLoader: function () {
            if (UI._loaderEl) return UI._loaderEl;
            var el = document.getElementById('loader');
            if (el) { UI._loaderEl = el; return el; }
            el = document.createElement('div');
            el.id = 'alo-loader';
            el.setAttribute('role', 'status');
            el.setAttribute('aria-live', 'polite');
            el.style.cssText = 'position:fixed;inset:0;z-index:9999;display:none;' +
                'flex-direction:column;align-items:center;justify-content:center;text-align:center;' +
                'background:rgba(15,22,30,.82);backdrop-filter:blur(4px);color:#EAF2FB;' +
                'font-family:Inter,system-ui,sans-serif;';
            el.innerHTML =
                '<div style="width:52px;height:52px;border-radius:50%;border:4px solid rgba(234,242,251,.25);' +
                'border-top-color:#F0851E;animation:alo-spin 1s linear infinite;margin-bottom:14px;"></div>' +
                '<div id="alo-loader-text" style="font-weight:700;font-size:1.1rem;"></div>';
            if (!document.getElementById('alo-spin-kf')) {
                var st = document.createElement('style');
                st.id = 'alo-spin-kf';
                st.textContent = '@keyframes alo-spin{to{transform:rotate(360deg)}}';
                document.head.appendChild(st);
            }
            document.body.appendChild(el);
            UI._loaderEl = el;
            return el;
        },

        loading: function (msg) {
            var el = UI._ensureLoader();
            var t = document.getElementById('alo-loader-text') || document.getElementById('loaderText');
            if (t) t.textContent = msg || 'Cargando…';
            el.style.display = 'flex';
        },

        done: function () {
            if (UI._loaderEl) UI._loaderEl.style.display = 'none';
            var legacy = document.getElementById('loader');
            if (legacy) legacy.style.display = 'none';
        },

        /** Toast no bloqueante. Usa el #toast-wrap de cotizacion.html si existe. */
        toast: function (msg, ok) {
            var wrap = document.getElementById('toast-wrap');
            if (!wrap) {
                wrap = document.createElement('div');
                wrap.id = 'toast-wrap';
                wrap.style.cssText = 'position:fixed;z-index:10000;bottom:24px;left:50%;' +
                    'transform:translateX(-50%);display:flex;flex-direction:column;gap:10px;' +
                    'width:min(92%,400px);font-family:Inter,system-ui,sans-serif;';
                document.body.appendChild(wrap);
            }
            var el = document.createElement('div');
            el.className = 'toast ' + (ok ? 'ok' : 'err');
            el.setAttribute('role', ok ? 'status' : 'alert');
            el.style.cssText = 'padding:14px 18px;border-radius:12px;color:#fff;font-size:.92rem;' +
                'font-weight:500;box-shadow:0 10px 30px rgba(0,0,0,.18);' +
                'background:' + (ok ? '#2E7D46' : '#C0341D') + ';';
            el.textContent = msg;
            wrap.appendChild(el);
            setTimeout(function () { el.remove(); }, 4500);
        },

        /** Diálogo de confirmación. SweetAlert2 si está, confirm() si no. */
        confirm: function (titulo, texto) {
            if (window.Swal) {
                return window.Swal.fire({
                    title: titulo, text: texto, icon: 'question',
                    showCancelButton: true,
                    confirmButtonText: 'Sí, continuar', cancelButtonText: 'Cancelar',
                    confirmButtonColor: '#2F7FC4', cancelButtonColor: '#6B7A8C'
                }).then(function (r) { return !!r.isConfirmed; });
            }
            return Promise.resolve(window.confirm(titulo + '\n\n' + (texto || '')));
        },

        clp: function (n) {
            var v = Number(n);
            if (!isFinite(v)) v = 0;
            return '$' + Math.round(v).toLocaleString('es-CL');
        },

        /** Acepta ISO, DD/MM/AAAA o Date. Devuelve DD/MM/AAAA. */
        fecha: function (v) {
            if (!v) return '--';
            if (/^\d{2}\/\d{2}\/\d{4}$/.test(v)) return v;
            var d = (v instanceof Date) ? v : new Date(v);
            if (isNaN(d.getTime())) return String(v);
            var p = function (x) { return (x < 10 ? '0' : '') + x; };
            return p(d.getDate()) + '/' + p(d.getMonth() + 1) + '/' + d.getFullYear();
        },

        /** DD/MM/AAAA -> AAAA-MM-DD (lo que espera SAP Service Layer). */
        toISO: function (v) {
            if (!v) return null;
            var m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(String(v).trim());
            if (m) return m[3] + '-' + m[2] + '-' + m[1];
            var d = new Date(v);
            return isNaN(d.getTime()) ? null : d.toISOString().slice(0, 10);
        },

        hoyISO: function () { return new Date().toISOString().slice(0, 10); },

        /** Escapa texto antes de inyectarlo en innerHTML. */
        esc: function (s) {
            return String(s === null || s === undefined ? '' : s)
                .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
        },

        /** Fila de estado (cargando / vacío / error) dentro de un <tbody>. */
        fila: function (tbodyId, cols, icono, texto) {
            var tb = document.getElementById(tbodyId);
            if (!tb) return;
            tb.innerHTML = '<tr><td colspan="' + cols + '" style="padding:40px 20px;text-align:center;color:#6B7A8C;">' +
                '<div style="font-size:2.4rem;margin-bottom:8px;opacity:.5;">' + icono + '</div>' +
                UI.esc(texto) + '</td></tr>';
        },

        badge: function (texto, tipo) {
            var c = { ok: ['#E6F4EA', '#137333'], warn: ['#FEF7E0', '#B06000'],
                      err: ['#FCE8E6', '#C5221F'], info: ['#EBF5FF', '#2F7FC4'],
                      mute: ['#F1F5F9', '#6B7A8C'] }[tipo] || ['#F1F5F9', '#6B7A8C'];
            return '<span style="display:inline-flex;align-items:center;padding:4px 10px;' +
                'border-radius:20px;font-size:.75rem;font-weight:700;background:' + c[0] +
                ';color:' + c[1] + ';">' + UI.esc(texto) + '</span>';
        },

        val: function (id) {
            var el = document.getElementById(id);
            return el ? String(el.value || '').trim() : '';
        },
        setVal: function (id, v) {
            var el = document.getElementById(id);
            if (el) el.value = (v === null || v === undefined) ? '' : v;
        },
        setTxt: function (id, v) {
            var el = document.getElementById(id);
            if (el) el.textContent = (v === null || v === undefined) ? '' : v;
        },
        show: function (id, disp) {
            var el = document.getElementById(id);
            if (el) el.style.display = disp || 'block';
        },
        hide: function (id) {
            var el = document.getElementById(id);
            if (el) el.style.display = 'none';
        }
    };


    /* =========================================================================
     * 5. APP — la superficie que el HTML ya invoca
     * ====================================================================== */

    var app = {

        cfg: CFG, session: Session, api: Api, ui: UI,

        /* ---------------------------------------------------------------------
         * Sesión y navegación
         * ------------------------------------------------------------------ */

        /**
         * Guardia de sesión. Las páginas internas la llaman al final del body.
         * Si no hay vendedor autenticado, devuelve al login en vez de dejar la
         * página a medio renderizar (que era el comportamiento anterior).
         */
        checkSession: function () {
            Session.bridge();
            var u = Session.usuario();
            var esInterna = /clientes|oportunidades|oferta|contrato|cotizacion|dashboard/i
                                .test(location.pathname.split('/').pop() || '');
            if (esInterna && !u.email) {
                UI.toast('Tu sesión expiró. Vuelve a iniciar sesión.', false);
                setTimeout(function () { window.location.href = 'index.html'; }, 1200);
                return false;
            }
            app.pintarCabecera();
            return true;
        },

        /** Rellena badge de cliente / nombre de vendedor si la página los tiene. */
        pintarCabecera: function () {
            var c = Session.cliente(), u = Session.usuario();

            if (document.getElementById('display-client-name')) {
                UI.setTxt('display-client-name', c.nombre || 'Seleccionar Cliente');
                UI.setTxt('display-rut', c.rut ? Session.formatRut(c.rut) : '--');
                UI.setTxt('display-cardcode', c.cardCode || '--');
                var av = document.getElementById('client-avatar');
                if (av) {
                    av.textContent = c.nombre
                        ? c.nombre.trim().split(/\s+/).map(function (w) { return w[0]; })
                              .join('').substring(0, 2).toUpperCase()
                        : 'AL';
                }
            }
            if (document.getElementById('welcome-title')) {
                UI.setTxt('welcome-title', '¡Hola, ' + (u.nombre || 'Vendedor') + '!');
            }
            // Vendedor readonly en los modales de oportunidad / oferta
            ['opVendedor', 'ofVendedor', 'vendedorEmail'].forEach(function (id) {
                var el = document.getElementById(id);
                if (el && !el.value) el.value = u.email || '';
            });
            var suc = document.getElementById('sucursal');
            if (suc && !suc.value && u.sucursal) suc.value = u.sucursal;
        },

        logout: function () { Session.logout(); },

        /**
         * Menú unificado. Cada página traía su propio subconjunto de enlaces
         * (clientes mostraba 3, Oportunidades 5, Oferta ninguno), así que el
         * usuario perdía módulos según dónde estuviera. Aquí se reconstruye
         * el mismo menú en todas, marcando la página actual.
         */
        MENU: [
            { href: 'dashboard.html',     label: 'Inicio' },
            { href: 'clientes.html',      label: 'Clientes' },
            { href: 'Oportunidades.html', label: 'Oportunidades' },
            { href: 'cotizacion.html',    label: 'Cotizaciones' },
            { href: 'Oferta.html',        label: 'Ofertas' },
            { href: 'Contrato.html',      label: 'Contratos' },
            { href: 'historicoc.html',    label: 'Situación comercial' }
        ],

        buildNav: function () {
            var navbar = document.querySelector('.navbar');
            if (!navbar) return;
            var nav = navbar.querySelector('.nav-menu');
            if (!nav) {
                nav = document.createElement('nav');
                nav.className = 'nav-menu';
                // El botón de logout no siempre es hijo directo de .navbar
                // (en Oferta.html está anidado), así que sólo usamos
                // insertBefore cuando de verdad lo es.
                var ref = navbar.querySelector('.logout, .btn-logout, .btn-back');
                if (ref && ref.parentNode === navbar) navbar.insertBefore(nav, ref);
                else navbar.appendChild(nav);
            }
            var actual = (location.pathname.split('/').pop() || 'index.html').toLowerCase();
            nav.innerHTML = app.MENU.map(function (m) {
                var act = m.href.toLowerCase() === actual ? ' class="active"' : '';
                return '<a href="' + m.href + '"' + act + '>' + UI.esc(m.label) + '</a>';
            }).join('\n');
        },

        /**
         * Fija el cliente en contexto y navega. Este era el eslabón que
         * faltaba: cotizacion.html esperaba alo_card_code/alo_client_name y
         * nadie los escribía.
         */
        seleccionarCliente: function (rut, nombre, cardCode, destino) {
            Session.setCliente({ rut: rut, nombre: nombre, cardCode: cardCode });
            if (destino) window.location.href = destino;
            else { app.pintarCabecera(); UI.toast('Cliente en contexto: ' + nombre, true); }
        },


        /* ---------------------------------------------------------------------
         * clientes.html
         * ------------------------------------------------------------------ */

        buscarClientes: function () {
            var rut = UI.val('searchRut'), nombre = UI.val('searchName');
            if (!rut && !nombre) {
                UI.toast('Ingresa un RUT o un nombre comercial para buscar.', false);
                return;
            }
            UI.fila('tablaClientesBody', 5, '⏳', 'Consultando SAP Business One…');

            Api.call('clientesBuscar', {
                rut: rut,
                cardCode: rut ? Session.rutToCardCode(rut) : '',
                cardName: nombre,
                userEmail: Session.usuario().email
            }).then(function (r) {
                if (!r.ok) { UI.fila('tablaClientesBody', 5, '⚠️', r.message); return; }
                if (!r.list.length) {
                    UI.fila('tablaClientesBody', 5, '🔍', 'Sin resultados para esa búsqueda.');
                    return;
                }
                var html = r.list.map(function (c) {
                    var cardCode = c.CardCode || c.cardCode || '';
                    var rutC     = c.LicTradNum || c.U_RUT || c.rut || '';
                    var nom      = c.CardName || c.cardName || c.nombre || 'Sin nombre';
                    var pago     = c.PayTermsGrpName || c.condPago || c.GroupNum || '--';
                    var trib     = c.U_EstadoTrib || c.estadoTributario || (c.Frozen === 'tYES' ? 'BLOQUEADO' : 'VIGENTE');
                    var esBloq   = /bloque|moros/i.test(trib);
                    return '<tr>' +
                        '<td><strong>' + UI.esc(Session.formatRut(rutC)) + '</strong>' +
                            '<div style="font-family:monospace;font-size:.75rem;color:#6B7A8C;">' + UI.esc(cardCode) + '</div></td>' +
                        '<td>' + UI.esc(nom) + '</td>' +
                        '<td>' + UI.esc(pago) + '</td>' +
                        '<td>' + UI.badge(trib, esBloq ? 'err' : 'ok') + '</td>' +
                        '<td style="white-space:nowrap;">' +
                            btn('Cotizar', "app.seleccionarCliente('" + js(rutC) + "','" + js(nom) + "','" + js(cardCode) + "','cotizacion.html')") +
                            btn('Ficha', "app.seleccionarCliente('" + js(rutC) + "','" + js(nom) + "','" + js(cardCode) + "','historicoc.html')", true) +
                        '</td></tr>';
                }).join('');
                document.getElementById('tablaClientesBody').innerHTML = html;
            });
        },


        /* ---------------------------------------------------------------------
         * Oportunidades.html
         * ------------------------------------------------------------------ */

        buscarOportunidades: function () {
            UI.fila('tablaOportunidadesBody', 9, '⏳', 'Consultando oportunidades…');
            Api.call('oportListar', {
                texto:    UI.val('filtroTexto'),
                estado:   UI.val('filtroEstado'),
                etapa:    UI.val('filtroEtapa'),
                userEmail: Session.usuario().email
            }).then(function (r) {
                if (!r.ok) {
                    UI.fila('tablaOportunidadesBody', 9, '⚠️', r.message);
                    app._kpisOport([]);
                    return;
                }
                app._renderOportunidades(r.list);
            });
        },

        _renderOportunidades: function (lista) {
            app._kpisOport(lista);
            if (!lista.length) {
                UI.fila('tablaOportunidadesBody', 9, '📋', 'No hay oportunidades que coincidan con el filtro.');
                return;
            }
            var html = lista.map(function (o) {
                var id     = o.OpprId || o.opprId || o.id || '--';
                var nom    = o.CardName || o.cliente || '--';
                var cc     = o.CardCode || o.cardCode || '';
                var rutO   = o.LicTradNum || o.rut || '';
                var desc   = o.Remarks || o.Name || o.descripcion || o.nombre || '--';
                var vend   = o.SalesPerson || o.vendedor || o.U_Vendedor || '--';
                var etapa  = String(o.SalesStage || o.etapa || '1');
                var meta   = CFG.ETAPAS[etapa] || { nombre: 'Etapa ' + etapa, pct: 0 };
                var pot    = Number(o.MaxSumLoc || o.potencial || 0);
                var cierre = o.PredDate || o.CloseDate || o.cierre;
                var estado = String(o.Status || o.estado || 'O').toUpperCase();
                var est = estado === 'W' ? ['GANADA', 'ok']
                        : estado === 'L' ? ['PERDIDA', 'err']
                        : ['ABIERTA', 'info'];
                return '<tr>' +
                    '<td><strong style="color:#22374A;">#' + UI.esc(id) + '</strong></td>' +
                    '<td>' + UI.esc(nom) + '<div style="font-family:monospace;font-size:.72rem;color:#6B7A8C;">' + UI.esc(cc) + '</div></td>' +
                    '<td>' + UI.esc(desc) + '</td>' +
                    '<td style="font-size:.82rem;">' + UI.esc(vend) + '</td>' +
                    '<td>' + UI.badge(meta.nombre + ' · ' + meta.pct + '%', 'mute') + '</td>' +
                    '<td style="text-align:right;font-weight:700;">' + UI.clp(pot) + '</td>' +
                    '<td>' + UI.esc(UI.fecha(cierre)) + '</td>' +
                    '<td>' + UI.badge(est[0], est[1]) + '</td>' +
                    '<td style="white-space:nowrap;">' +
                        btn('Cotizar', "app.cotizarDesdeOportunidad('" + js(id) + "','" + js(rutO) + "','" + js(nom) + "','" + js(cc) + "')") +
                    '</td></tr>';
            }).join('');
            document.getElementById('tablaOportunidadesBody').innerHTML = html;
        },

        _kpisOport: function (lista) {
            var abiertas = 0, potencial = 0, ponderado = 0, ganadas = 0;
            lista.forEach(function (o) {
                var estado = String(o.Status || o.estado || 'O').toUpperCase();
                var pot = Number(o.MaxSumLoc || o.potencial || 0);
                var etapa = String(o.SalesStage || o.etapa || '1');
                var pct = (CFG.ETAPAS[etapa] || { pct: 0 }).pct;
                if (estado === 'W') { ganadas++; }
                else if (estado !== 'L') {
                    abiertas++; potencial += pot; ponderado += pot * pct / 100;
                }
            });
            UI.setTxt('kpiAbiertas', abiertas);
            UI.setTxt('kpiPotencial', UI.clp(potencial));
            UI.setTxt('kpiPonderado', UI.clp(ponderado));
            UI.setTxt('kpiGanadas', ganadas);
        },

        abrirNuevaOportunidad: function () {
            UI.show('modalNueva', 'flex');
            UI.setVal('opVendedor', Session.usuario().email);
            var c = Session.cliente();
            if (c.nombre) UI.setVal('opCliente', c.nombre + ' (' + Session.formatRut(c.rut) + ')');
            UI.setVal('opEtapa', '1');
        },

        cerrarNuevaOportunidad: function () {
            UI.hide('modalNueva');
            ['opCliente', 'opNombre', 'opPotencial', 'opCierre', 'opComentarios'].forEach(function (id) {
                UI.setVal(id, '');
            });
        },

        crearOportunidad: function () {
            var cliente = UI.val('opCliente'), nombre = UI.val('opNombre');
            if (!cliente || !nombre) {
                UI.toast('Cliente y nombre de la oportunidad son obligatorios.', false);
                return;
            }
            var potencial = Number(UI.val('opPotencial').replace(/[^\d]/g, '')) || 0;
            var ctx = Session.cliente();

            UI.loading('Creando oportunidad en SAP…');
            Api.call('oportCrear', {
                cardCode:    ctx.cardCode || Session.rutToCardCode(cliente),
                cardName:    ctx.nombre || cliente,
                rut:         ctx.rut,
                nombre:      nombre,
                salesStage:  UI.val('opEtapa') || '1',
                potencial:   potencial,
                fechaCierre: UI.toISO(UI.val('opCierre')),
                vendedorEmail: UI.val('opVendedor') || Session.usuario().email,
                comentarios: UI.val('opComentarios'),
                sucursal:    Session.usuario().sucursal
            }).then(function (r) {
                UI.done();
                if (!r.ok) { UI.toast('Proceso detenido: ' + r.message, false); return; }
                var id = (r.obj && (r.obj.opprId || r.obj.OpprId || r.obj.docNum)) || '';
                UI.toast('Oportunidad' + (id ? ' N° ' + id : '') + ' creada en SAP.', true);
                app.cerrarNuevaOportunidad();
                app.buscarOportunidades();
            });
        },

        /** Lleva la oportunidad al formulario de cotización con contexto. */
        cotizarDesdeOportunidad: function (opprId, rut, nombre, cardCode) {
            Session.setCliente({ rut: rut, nombre: nombre, cardCode: cardCode });
            Session.set(K.opprId, opprId);
            window.location.href = 'cotizacion.html';
        },


        /* ---------------------------------------------------------------------
         * Oferta.html
         * ------------------------------------------------------------------ */

        buscarOfertas: function () {
            UI.fila('tablaOfertasBody', 8, '⏳', 'Consultando ofertas…');
            Api.call('ofertaListar', {
                texto:  UI.val('filtroTexto'),
                estado: UI.val('filtroEstado'),
                userEmail: Session.usuario().email
            }).then(function (r) {
                if (!r.ok) { UI.fila('tablaOfertasBody', 8, '⚠️', r.message); return; }
                if (!r.list.length) {
                    UI.fila('tablaOfertasBody', 8, '📄', 'No hay ofertas que coincidan con el filtro.');
                    return;
                }
                document.getElementById('tablaOfertasBody').innerHTML = r.list.map(function (o) {
                    var num  = o.DocNum || o.docNum || '--';
                    var nom  = o.CardName || o.cliente || '--';
                    var cc   = o.CardCode || o.cardCode || '';
                    var rutO = o.LicTradNum || o.rut || '';
                    var est  = String(o.DocStatus || o.estado || 'O').toUpperCase();
                    var eb   = est === 'C' ? ['CERRADA', 'mute'] : ['ABIERTA', 'ok'];
                    return '<tr>' +
                        '<td><strong style="color:#22374A;">#' + UI.esc(num) + '</strong></td>' +
                        '<td>' + UI.esc(nom) + '<div style="font-family:monospace;font-size:.72rem;color:#6B7A8C;">' + UI.esc(cc) + '</div></td>' +
                        '<td>' + UI.esc(UI.fecha(o.DocDate || o.fecha)) + '</td>' +
                        '<td>' + UI.esc(UI.fecha(o.DocDueDate || o.vence)) + '</td>' +
                        '<td style="font-size:.82rem;">' + UI.esc(o.SalesPerson || o.vendedor || '--') + '</td>' +
                        '<td style="text-align:right;font-weight:700;">' + UI.clp(o.DocTotal || o.total || 0) + '</td>' +
                        '<td>' + UI.badge(eb[0], eb[1]) + '</td>' +
                        '<td style="white-space:nowrap;">' +
                            btn('A contrato', "app.contratarDesdeOferta('" + js(num) + "','" + js(rutO) + "','" + js(nom) + "','" + js(cc) + "')") +
                        '</td></tr>';
                }).join('');
            });
        },

        abrirNuevaOferta: function () {
            UI.show('modalNueva', 'flex');
            UI.setVal('ofVendedor', Session.usuario().email);
            UI.setVal('ofFecha', UI.hoyISO());
            var v = new Date(); v.setDate(v.getDate() + 30);
            UI.setVal('ofVence', v.toISOString().slice(0, 10));
            var c = Session.cliente();
            if (c.nombre) UI.setVal('ofCliente', c.nombre + ' (' + Session.formatRut(c.rut) + ')');
            app._recalcOferta();
        },

        cerrarNuevaOferta: function () {
            UI.hide('modalNueva');
            UI.setVal('ofCliente', ''); UI.setVal('ofReferencia', '');
        },

        agregarLineaOferta: function () {
            var cont = document.getElementById('lineasOferta');
            if (!cont) return;
            var base = cont.querySelector('.linea, .line-row, div');
            var row = base ? base.cloneNode(true) : null;
            if (!row) return;
            row.querySelectorAll('input').forEach(function (i) { i.value = ''; });
            cont.appendChild(row);
            app._bindLineas();
        },

        quitarLineaOferta: function (btnEl) {
            var cont = document.getElementById('lineasOferta');
            if (!cont || !btnEl) return;
            var filas = cont.querySelectorAll('.linea, .line-row');
            var row = btnEl.closest('.linea') || btnEl.closest('.line-row') || btnEl.parentNode;
            if (filas.length <= 1) {
                row.querySelectorAll('input').forEach(function (i) { i.value = ''; });
            } else {
                row.remove();
            }
            app._recalcOferta();
        },

        _bindLineas: function () {
            var cont = document.getElementById('lineasOferta');
            if (!cont) return;
            cont.querySelectorAll('.line-qty, .line-price').forEach(function (i) {
                i.oninput = app._recalcOferta;
            });
        },

        _lineasOferta: function () {
            var cont = document.getElementById('lineasOferta');
            if (!cont) return [];
            var out = [];
            cont.querySelectorAll('.line-item').forEach(function (itemEl) {
                var row = itemEl.closest('.linea') || itemEl.closest('.line-row') || itemEl.parentNode;
                var q = row.querySelector('.line-qty'), p = row.querySelector('.line-price');
                var code = String(itemEl.value || '').trim();
                if (!code) return;
                out.push({
                    itemCode: code,
                    quantity: Number(q && q.value) || 1,
                    unitPrice: Number(p && p.value) || 0
                });
            });
            return out;
        },

        _recalcOferta: function () {
            var total = app._lineasOferta().reduce(function (a, l) {
                return a + l.quantity * l.unitPrice;
            }, 0);
            UI.setTxt('ofTotalPreview', UI.clp(total));
        },

        crearOferta: function () {
            var cliente = UI.val('ofCliente');
            var lineas = app._lineasOferta();
            if (!cliente) { UI.toast('Debes indicar el cliente.', false); return; }
            if (!lineas.length) { UI.toast('Agrega al menos un ítem con código.', false); return; }

            var ctx = Session.cliente();
            UI.loading('Creando oferta en SAP…');
            Api.call('ofertaCrear', {
                cardCode:   ctx.cardCode || Session.rutToCardCode(cliente),
                cardName:   ctx.nombre || cliente,
                rut:        ctx.rut,
                docDate:    UI.val('ofFecha') || UI.hoyISO(),
                docDueDate: UI.val('ofVence'),
                referencia: UI.val('ofReferencia'),
                vendedorEmail: UI.val('ofVendedor') || Session.usuario().email,
                sucursal:   Session.usuario().sucursal,
                opprId:     Session.get(K.opprId) || null,
                lineas:     lineas
            }).then(function (r) {
                UI.done();
                if (!r.ok) { UI.toast('Proceso detenido: ' + r.message, false); return; }
                var num = (r.obj && (r.obj.docNum || r.obj.DocNum)) || '';
                UI.toast('Oferta' + (num ? ' N° ' + num : '') + ' creada en SAP.', true);
                Session.del(K.opprId);
                app.cerrarNuevaOferta();
                app.buscarOfertas();
            });
        },

        contratarDesdeOferta: function (docNum, rut, nombre, cardCode) {
            Session.setCliente({ rut: rut, nombre: nombre, cardCode: cardCode });
            Session.set(K.quotId, docNum);
            window.location.href = 'Contrato.html';
        },


        /* ---------------------------------------------------------------------
         * Contrato.html
         * ------------------------------------------------------------------ */

        cargarCotizacion: function () {
            var doc = UI.val('docCotizacion');
            if (!doc) { UI.toast('Ingresa el N° de cotización u oferta.', false); return; }

            UI.loading('Trayendo datos de la cotización ' + doc + '…');
            Api.call('cotizacionGet', { docNum: doc, docEntry: doc, userEmail: Session.usuario().email })
              .then(function (r) {
                UI.done();
                if (!r.ok) { UI.toast(r.message, false); return; }
                var d = r.obj || r.list[0];
                if (!d) { UI.toast('No se encontró la cotización N° ' + doc + '.', false); return; }

                UI.setVal('cardCode', d.CardCode || d.cardCode || '');
                UI.setVal('rut', Session.formatRut(d.LicTradNum || d.rut || ''));
                UI.setVal('cardName', d.CardName || d.cardName || '');
                UI.setVal('destFact', d.PayToCode || d.destFact || '');
                UI.setVal('condPago', d.PayTermsGrpName || d.condPago || '');
                UI.setVal('destFAddr', d.Address || d.destFAddr || '');

                UI.setTxt('metaCotizacion', '#' + doc);
                UI.setTxt('metaSucursal', d.Sucursal || d.U_Sucursal || Session.usuario().sucursal || '--');
                UI.setTxt('metaVendedor', d.SalesPerson || d.vendedor || Session.usuario().email || '--');

                UI.show('panelCliente'); UI.show('panelContrato'); UI.show('panelAcciones');

                if (!UI.val('fechaInicio')) UI.setVal('fechaInicio', UI.hoyISO());

                Session.setCliente({
                    rut: d.LicTradNum || d.rut,
                    nombre: d.CardName || d.cardName,
                    cardCode: d.CardCode || d.cardCode
                });
                app.pintarCabecera();
                UI.toast('Datos cargados. Revisa y genera el contrato.', true);
            });
        },

        generarContrato: function () {
            var doc = UI.val('docCotizacion');
            var ini = UI.val('fechaInicio'), fin = UI.val('fechaTermino');
            if (!doc)  { UI.toast('Falta el N° de cotización.', false); return; }
            if (!ini)  { UI.toast('Indica la fecha de inicio del contrato.', false); return; }
            if (fin && fin < ini) {
                UI.toast('La fecha de término no puede ser anterior al inicio.', false);
                return;
            }

            var btn = document.getElementById('btnGenerar');
            UI.confirm('¿Generar el contrato?',
                       'Se creará el contrato de arriendo en SAP a partir de la cotización N° ' + doc + '. Esta acción queda registrada.')
            .then(function (ok) {
                if (!ok) return;
                if (btn) btn.disabled = true;
                UI.loading('Generando contrato en SAP…');
                return Api.call('contratoCrear', {
                    docCotizacion: doc,
                    cardCode:      UI.val('cardCode'),
                    cardName:      UI.val('cardName'),
                    rut:           UI.val('rut'),
                    condPago:      UI.val('condPago'),
                    destFact:      UI.val('destFact'),
                    destFAddr:     UI.val('destFAddr'),
                    fechaInicio:   ini,
                    fechaTermino:  fin || null,
                    observaciones: UI.val('observaciones'),
                    vendedorEmail: Session.usuario().email,
                    sucursal:      Session.usuario().sucursal
                }).then(function (r) {
                    UI.done();
                    if (btn) btn.disabled = false;
                    if (!r.ok) { UI.toast('Proceso detenido: ' + r.message, false); return; }
                    var num = (r.obj && (r.obj.docNum || r.obj.DocNum)) || '';
                    Session.del(K.quotId);
                    UI.toast('Contrato' + (num ? ' N° ' + num : '') + ' generado en SAP.', true);
                    setTimeout(function () { window.location.href = 'dashboard.html'; }, 2000);
                });
            });
        }
    };

    /* Helpers locales para armar botones dentro de las tablas. */
    function btn(label, onclick, ghost) {
        return '<button type="button" onclick="' + onclick + '" ' +
            'style="cursor:pointer;font-family:inherit;font-size:.78rem;font-weight:700;' +
            'padding:6px 12px;margin-right:6px;border-radius:8px;' +
            (ghost
                ? 'background:#fff;color:#2F7FC4;border:1.5px solid #2F7FC4;'
                : 'background:#2F7FC4;color:#fff;border:1.5px solid #2F7FC4;') +
            '">' + UI.esc(label) + '</button>';
    }
    /** Escapa una cadena para usarla dentro de un atributo onclick con comillas simples. */
    function js(s) {
        return String(s === null || s === undefined ? '' : s)
            .replace(/\\/g, '\\\\').replace(/'/g, "\\'")
            .replace(/"/g, '&quot;').replace(/\r?\n/g, ' ');
    }

    /* =========================================================================
     * ARRANQUE
     * ====================================================================== */

    // El puente de sesión debe correr lo antes posible, antes de que el script
    // propio de cada página lea sessionStorage.
    Session.bridge();

    /**
     * Red de seguridad para las librerías de CDN.
     *
     * formulario.html y mantencionretiro.html llaman a M.* (Materialize) y
     * Swal.* directamente. Si el CDN no responde — red corporativa, proxy,
     * sin internet — la página moría con "M is not defined" y el formulario
     * quedaba inutilizable. Con estos stubs degrada en vez de romperse.
     */
    function shimCDN() {
        if (!window.Swal) {
            window.Swal = {
                fire: function (opts) {
                    var o = (typeof opts === 'string') ? { title: opts } : (opts || {});
                    var texto = [o.title, o.text].filter(Boolean).join(' — ');
                    if (o.showCancelButton) {
                        return UI.confirm(o.title || '¿Confirmas?', o.text || '')
                                 .then(function (ok) { return { isConfirmed: ok, value: ok }; });
                    }
                    UI.toast(texto || '', o.icon !== 'error' && o.icon !== 'warning');
                    return Promise.resolve({ isConfirmed: true, value: true });
                },
                close: function () { UI.done(); },
                showLoading: function () { UI.loading('Procesando…'); },
                showValidationMessage: function (m) { UI.toast(m, false); }
            };
        }
        if (!window.M) {
            window.M = {
                toast: function (o) { UI.toast((o && (o.html || o.text)) || '', true); },
                updateTextFields: function () {},
                FormSelect: { init: function () {} },
                Modal: { init: function () {}, getInstance: function () { return { open: function () {}, close: function () {} }; } },
                Collapsible: { init: function () {} },
                Datepicker: { init: function () {} }
            };
        }
    }

    document.addEventListener('DOMContentLoaded', function () {
        shimCDN();
        Session.bridge();
        app.buildNav();
        app.pintarCabecera();
        app._bindLineas();

        // Autocarga de listados según la página, para que no haya que pulsar
        // "Filtrar" para ver algo.
        var page = (location.pathname.split('/').pop() || '').toLowerCase();
        if (page.indexOf('oportunidades') === 0) app.buscarOportunidades();
        if (page.indexOf('oferta') === 0)        app.buscarOfertas();

        // Si venimos de una oferta, precargar el número en Contrato.
        if (page.indexOf('contrato') === 0) {
            var q = Session.get(K.quotId);
            if (q && !UI.val('docCotizacion')) {
                UI.setVal('docCotizacion', q);
                app.cargarCotizacion();
            }
        }
    });

    window.app = app;
    window.ALO = app; // alias

})(window, document);
