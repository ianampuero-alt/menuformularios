
const app = {
    showAlert: function(msg, type = 'error', elementId = 'alertMsg') {
        const el = document.getElementById(elementId);
        if(!el) return;
        el.innerText = msg;
        el.className = 'alert alert-' + type;
        el.style.display = 'block';
        setTimeout(() => el.style.display = 'none', 6000);
    },

    // LOGIN
    requestOtp: function() {
        const email = document.getElementById('email').value;
        if(!email.endsWith('@alo-group.com')) {
            this.showAlert('Debe ingresar un correo corporativo válido.');
            return;
        }
        this.showAlert('OTP enviado a ' + email, 'success');
        document.getElementById('otpGroup').style.display = 'block';
        document.getElementById('btnRequestOtp').style.display = 'none';
        document.getElementById('btnLogin').style.display = 'block';
    },

    login: function(e) {
        e.preventDefault();
        const otp = document.getElementById('otp').value;
        const email = document.getElementById('email').value;
        
        if(otp) {
            sessionStorage.setItem('alo_user_email', email);
            sessionStorage.setItem('alo_user_role', 'comercial'); // Mapeo Vendedor (Regla v1)
            window.location.href = 'dashboard.html';
        }
    },

    checkSession: function() {
        if(sessionStorage.getItem('alo_user_role') !== 'comercial') {
            window.location.href = 'index.html';
        }
        const nameEl = document.getElementById('userName');
        if(nameEl) nameEl.innerText = sessionStorage.getItem('alo_user_email').split('@')[0].replace('.', ' ').toUpperCase();
    },

    logout: function() {
        sessionStorage.clear();
        window.location.href = 'index.html';
    },

    // CLIENTES
    buscarClientes: function() {
        const tbody = document.getElementById('tablaClientesBody');
        if(!tbody) return;
        tbody.innerHTML = `
            <tr>
                <td>76721028-0</td>
                <td>FULL FACILITY SPA</td>
                <td>CREDITO 24 HORAS</td>
                <td><span style="color: #2ecc71; font-weight: 600;">Evaluación OK</span></td>
                <td><button class="btn btn-primary btn-sm" onclick="app.usarCliente('76721028-0')">Crear Cotización</button></td>
            </tr>
            <tr>
                <td>76468734-5</td>
                <td>DECOINFLABLES IMPORTADORA</td>
                <td>CONTADO</td>
                <td><span style="color: #e74c3c; font-weight: 600;">Requiere Eval. (Regla 4015)</span></td>
                <td><button class="btn btn-primary btn-sm" onclick="app.usarCliente('76468734-5')">Crear Cotización</button></td>
            </tr>
        `;
    },

    usarCliente: function(rut) {
        sessionStorage.setItem('alo_temp_rut', rut);
        window.location.href = 'cotizacion.html';
    },

    // COTIZACIÓN
    initCotizacion: function() {
        const rut = sessionStorage.getItem('alo_temp_rut');
        if(rut) {
            document.getElementById('rutCliente').value = rut;
            sessionStorage.removeItem('alo_temp_rut');
        }
        
        const bodyEquipos = document.getElementById('bodyEquipos');
        if(bodyEquipos) {
            bodyEquipos.addEventListener('input', (e) => {
                if(e.target.classList.contains('eq-code')) {
                    this.generarAdicionales();
                }
            });
        }
        
        const formCot = document.getElementById('formCotizacion');
        if(formCot) {
            formCot.addEventListener('submit', (e) => this.crearCotizacion(e));
        }
    },

    generarAdicionales: function() {
        const codes = document.querySelectorAll('.eq-code');
        const bodyAdic = document.getElementById('bodyAdicionales');
        if(!bodyAdic) return;
        
        bodyAdic.innerHTML = '';
        let hasEquip = false;
        
        codes.forEach(input => {
            const eq = input.value.trim().toUpperCase();
            if(eq.startsWith('CO')) {
                hasEquip = true;
                // Regla 5003: Seguros y Alistamiento obligatorios
                bodyAdic.innerHTML += `
                    <tr>
                        <td>SEGURO</td>
                        <td>SEG-${eq}</td>
                        <td><input type="number" class="form-control adic-monto" placeholder="Calc. automático" readonly></td>
                    </tr>
                    <tr>
                        <td>ALISTAMIENTO</td>
                        <td>zALI-${eq}</td>
                        <td><input type="number" class="form-control adic-monto" value="50000"></td>
                    </tr>
                `;
            }
        });
        
        if(!hasEquip) {
            bodyAdic.innerHTML = '<tr><td colspan="3" class="text-center text-muted">Ingrese un código válido (ej. COBAC001)</td></tr>';
        }
    },

    agregarFlete: function() {
        const bodyAdic = document.getElementById('bodyAdicionales');
        if(!bodyAdic) return;
        // Flete Service Layer bloqueo - Ingreso Manual temporal
        bodyAdic.innerHTML += `
            <tr>
                <td>FLETE</td>
                <td>
                    <select class="form-control">
                        <option value="SERVI019">FLETE SOLO IDA</option>
                        <option value="SERVI020">FLETE SOLO RETORNO</option>
                    </select>
                </td>
                <td><input type="number" class="form-control adic-monto" value="150000"></td>
            </tr>
        `;
    },

    calcularTotales: function() {
        // Regla 4007: Mínimo 3 días
        const dias = document.querySelector('.eq-dias').value;
        if(dias < 3) {
            this.showAlert('Regla 4007: El arriendo mínimo es de 3 días.', 'error', 'alertCot');
            return;
        }
        
        // Regla 4011: Nro. Oportunidad
        const oppr = document.getElementById('opprId').value;
        if(!oppr) {
            this.showAlert('Regla 4011: Debe indicar el Nro. de Oportunidad.', 'error', 'alertCot');
            return;
        }

        // Dummy calculation (Neto = TarBase + Adicionales)
        let neto = (25000 * parseInt(dias)); // Tarifa Base simulada
        document.querySelectorAll('.adic-monto').forEach(inp => {
            if(inp.value) neto += parseFloat(inp.value);
        });

        const iva = Math.round(neto * 0.19);
        const total = neto + iva;

        document.getElementById('valNeto').innerText = neto.toLocaleString('es-CL');
        document.getElementById('valIva').innerText = iva.toLocaleString('es-CL');
        document.getElementById('valTotal').innerText = total.toLocaleString('es-CL');
        document.getElementById('totalesBox').style.display = 'block';
    },

    crearCotizacion: function(e) {
        e.preventDefault();
        this.calcularTotales();
        const alertEl = document.getElementById('alertCot');
        if(alertEl.style.display === 'block' && alertEl.classList.contains('alert-error')) return;
        
        this.showAlert('Enviando datos a n8n / SAP Service Layer...', 'success', 'alertCot');
        setTimeout(() => {
            this.showAlert('¡Cotización generada exitosamente! DocEntry: 172950', 'success', 'alertCot');
            document.getElementById('formCotizacion').reset();
            document.getElementById('totalesBox').style.display = 'none';
            document.getElementById('bodyAdicionales').innerHTML = '';
        }, 2000);
    }
};

// Event Listeners for Login
document.addEventListener('DOMContentLoaded', () => {
    const btnRequest = document.getElementById('btnRequestOtp');
    if(btnRequest) btnRequest.addEventListener('click', () => app.requestOtp());
    
    const formLogin = document.getElementById('loginForm');
    if(formLogin) formLogin.addEventListener('submit', (e) => app.login(e));
});
