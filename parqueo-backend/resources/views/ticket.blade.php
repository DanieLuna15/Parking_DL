<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ticket #{{ $entry->ticket_code }} - ParkinGo</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;800&family=Plus+Jakarta+Sans:wght@500;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #2563EB;
            --primary-dark: #1D4ED8;
            --bg-color: #F1F5F9;
            --ticket-bg: #FFFFFF;
            --text-main: #0F172A;
            --text-muted: #64748B;
            --border-color: #CBD5E1;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
            padding: 24px 16px 60px;
        }

        .actions-bar {
            width: 100%;
            max-width: 400px;
            margin-bottom: 20px;
            display: flex;
            gap: 10px;
        }

        .btn {
            flex: 1;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 12px 18px;
            border-radius: 12px;
            font-weight: 700;
            font-size: 14px;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.2s ease;
            border: none;
        }

        .btn-primary {
            background-color: var(--primary);
            color: white;
            box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);
        }

        .btn-primary:hover {
            background-color: var(--primary-dark);
        }

        .btn-outline {
            background-color: white;
            color: var(--text-main);
            border: 1px solid var(--border-color);
        }

        .ticket-wrapper {
            width: 100%;
            max-width: 380px;
            background: var(--ticket-bg);
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
            position: relative;
            overflow: hidden;
            border: 1px solid rgba(0, 0, 0, 0.05);
        }

        /* Dientes de ticket en la parte superior e inferior */
        .ticket-header {
            background: linear-gradient(135deg, #1E3A8A 0%, #2563EB 100%);
            color: white;
            padding: 24px 20px;
            text-align: center;
        }

        .ticket-brand {
            font-size: 22px;
            font-weight: 800;
            letter-spacing: -0.5px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .parking-name {
            font-size: 13px;
            opacity: 0.9;
            margin-top: 4px;
        }

        .ticket-body {
            padding: 24px 22px;
        }

        .plate-box {
            background-color: #F8FAFC;
            border: 2px dashed #94A3B8;
            border-radius: 14px;
            padding: 14px;
            text-align: center;
            margin-bottom: 20px;
        }

        .plate-label {
            font-size: 11px;
            text-transform: uppercase;
            font-weight: 700;
            color: var(--text-muted);
            letter-spacing: 1px;
        }

        .plate-number {
            font-family: 'JetBrains Mono', monospace;
            font-size: 30px;
            font-weight: 800;
            color: #1E293B;
            letter-spacing: 2px;
            margin-top: 2px;
        }

        .info-grid {
            display: flex;
            flex-direction: column;
            gap: 12px;
            font-size: 13px;
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .info-row .label {
            color: var(--text-muted);
            font-weight: 500;
        }

        .info-row .value {
            font-weight: 700;
            color: var(--text-main);
            text-align: right;
            font-family: 'JetBrains Mono', monospace;
        }

        .divider {
            border-top: 1px dashed #E2E8F0;
            margin: 16px 0;
        }

        .qr-section {
            text-align: center;
            padding: 16px 0 6px;
        }

        .qr-img {
            width: 170px;
            height: 170px;
            border-radius: 12px;
            padding: 6px;
            background: white;
            border: 1px solid #E2E8F0;
        }

        .ticket-code-display {
            font-family: 'JetBrains Mono', monospace;
            font-size: 13px;
            font-weight: 700;
            color: var(--primary);
            margin-top: 8px;
            letter-spacing: 1px;
        }

        .ticket-footer {
            text-align: center;
            padding: 16px 20px 22px;
            background: #F8FAFC;
            border-top: 1px solid #E2E8F0;
            font-size: 11px;
            color: var(--text-muted);
            line-height: 1.5;
        }

        .status-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 800;
            text-transform: uppercase;
        }

        .status-inside {
            background-color: #DBEAFE;
            color: #1D4ED8;
        }

        .status-exited {
            background-color: #DCFCE7;
            color: #15803D;
        }

        /* Estilos de Impresión / Guardado en PDF */
        @media print {
            body {
                background: white;
                padding: 0;
                margin: 0;
            }

            .actions-bar {
                display: none !important;
            }

            .ticket-wrapper {
                box-shadow: none;
                border: 1px solid #000;
                border-radius: 0;
                max-width: 100%;
                width: 300px; /* Tamaño recibo térmico 80mm */
                margin: 0 auto;
            }

            .ticket-header {
                background: white !important;
                color: black !important;
                border-bottom: 2px solid black;
            }

            .ticket-brand, .parking-name {
                color: black !important;
            }

            .plate-box {
                background: white !important;
                border: 2px solid black !important;
            }

            .plate-number {
                color: black !important;
            }

            .ticket-footer {
                background: white !important;
                color: black !important;
                border-top: 1px solid black;
            }

            @page {
                margin: 5mm;
                size: auto;
            }
        }
    </style>
</head>
<body>

    <div class="actions-bar">
        <button class="btn btn-primary" onclick="window.print()">
            🖨️ Imprimir / Guardar en PDF
        </button>
        <button class="btn btn-outline" onclick="compartirTicket()">
            📲 Compartir
        </button>
    </div>

    <div class="ticket-wrapper">
        <div class="ticket-header">
            <div class="ticket-brand">
                <span>🅿️</span> ParkinGo
            </div>
            <div class="parking-name">{{ $entry->parking->name ?? 'Estacionamiento Central' }}</div>
            <div style="margin-top: 8px;">
                @if($entry->status === 'inside')
                    <span class="status-badge status-inside">● EN ESTACIONAMIENTO</span>
                @else
                    <span class="status-badge status-exited">✓ TICKET COBRADO Y SALIDA</span>
                @endif
            </div>
        </div>

        <div class="ticket-body">
            <div class="plate-box">
                <div class="plate-label">Placa de Vehículo</div>
                <div class="plate-number">{{ $entry->license_plate }}</div>
            </div>

            <div class="info-grid">
                <div class="info-row">
                    <span class="label">Nro. de Ticket</span>
                    <span class="value">{{ $entry->ticket_code }}</span>
                </div>
                <div class="info-row">
                    <span class="label">Tipo de Vehículo</span>
                    <span class="value">{{ $entry->vehicleType->name }}</span>
                </div>
                <div class="info-row">
                    <span class="label">Hora de Ingreso</span>
                    <span class="value">{{ $entry->entry_time->format('d/m/Y H:i:s') }}</span>
                </div>
                <div class="info-row">
                    <span class="label">Tarifa por Hora</span>
                    <span class="value">{{ $entry->parking->currency_symbol ?? 'Bs.' }} {{ number_format($entry->vehicleType->rate_per_hour, 2) }}</span>
                </div>
                <div class="info-row">
                    <span class="label">Atendido por</span>
                    <span class="value">{{ $entry->user->name ?? 'Daniel Luna' }}</span>
                </div>

                @if($entry->exit)
                <div class="divider"></div>
                <div class="info-row">
                    <span class="label">Hora de Salida</span>
                    <span class="value">{{ $entry->exit->exit_time->format('d/m/Y H:i:s') }}</span>
                </div>
                <div class="info-row">
                    <span class="label">Tiempo Total</span>
                    <span class="value">{{ intdiv($entry->exit->duration_minutes, 60) }}h {{ $entry->exit->duration_minutes % 60 }}m</span>
                </div>
                <div class="info-row">
                    <span class="label">Método de Pago</span>
                    <span class="value">{{ strtoupper($entry->exit->payment_method) }}</span>
                </div>
                <div class="info-row" style="font-size: 16px; margin-top: 4px;">
                    <span class="label" style="font-weight: 800; color: #1E293B;">TOTAL COBRADO</span>
                    <span class="value" style="font-weight: 800; color: #2563EB;">{{ $entry->parking->currency_symbol ?? 'Bs.' }} {{ number_format($entry->exit->total_paid, 2) }}</span>
                </div>
                @endif
            </div>

            <div class="qr-section">
                <img src="{{ $qrUrl }}" alt="Código QR Ticket" class="qr-img">
                <div class="ticket-code-display">{{ $entry->ticket_code }}</div>
            </div>
        </div>

        <div class="ticket-footer">
            {{ $entry->parking->receipt_footer ?? 'Conserve este ticket para la entrega del vehículo. No nos hacemos responsables por objetos dejados en el interior.' }}
            <br>
            <strong>ParkinGo SaaS Parking System</strong>
        </div>
    </div>

    <script>
        function compartirTicket() {
            if (navigator.share) {
                navigator.share({
                    title: 'Ticket {{ $entry->ticket_code }} - ParkinGo',
                    text: 'Comprobante de parqueo para el vehículo {{ $entry->license_plate }}',
                    url: window.location.href,
                }).catch(() => {});
            } else {
                navigator.clipboard.writeText(window.location.href);
                alert('¡Enlace del ticket copiado al portapapeles!');
            }
        }
    </script>
</body>
</html>
