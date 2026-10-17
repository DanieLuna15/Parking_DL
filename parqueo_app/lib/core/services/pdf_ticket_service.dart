import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfTicketService {
  /// Genera e imprime el ticket de ENTRADA en formato térmico o PDF
  static Future<void> printEntryTicket({
    required String ticketCode,
    required String licensePlate,
    required String vehicleType,
    required String entryTime,
    double ratePerHour = 5.0,
    String? parkingName,
    String? cashier,
    String? ticketUrl,
  }) async {
    final pdf = pw.Document();

    final qrData = ticketUrl != null && ticketUrl.isNotEmpty
        ? ticketUrl
        : 'https://parkingo.app/tickets/$ticketCode';

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          160 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Encabezado
                pw.Text(
                  'PARKINGO',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  parkingName ?? 'Estacionamiento Central',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'TICKET DE INGRESO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

                // Caja de Placa
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'PLACA DE VEHÍCULO',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        licensePlate,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                // Detalles
                _buildPdfRow('Nro. Ticket:', ticketCode),
                _buildPdfRow('Tipo:', vehicleType),
                _buildPdfRow('Ingreso:', entryTime),
                _buildPdfRow('Tarifa/Hora:', 'Bs. ${ratePerHour.toStringAsFixed(2)}'),
                _buildPdfRow('Cajero:', cashier ?? 'Daniel Luna'),

                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

                // Código QR en el PDF
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrData,
                    width: 75,
                    height: 75,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  ticketCode,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5),
                pw.Text(
                  'Conserve este ticket para retirar su vehículo.\n¡Gracias por su visita!',
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ticket_Entrada_$licensePlate.pdf',
    );
  }

  /// Genera e imprime el comprobante de SALIDA y cobro
  static Future<void> printExitReceipt({
    required String ticketCode,
    required String licensePlate,
    required String vehicleType,
    required String entryTime,
    required String exitTime,
    required String duration,
    required double totalPaid,
    required String paymentMethod,
    double discount = 0.0,
    double penaltyAmount = 0.0,
    bool isLostTicket = false,
    String? parkingName,
    String? cashier,
    String? ticketUrl,
  }) async {
    final pdf = pw.Document();

    final qrData = ticketUrl != null && ticketUrl.isNotEmpty
        ? ticketUrl
        : 'https://parkingo.app/tickets/$ticketCode';

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          180 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'PARKINGO',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  parkingName ?? 'Estacionamiento Central',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  isLostTicket ? 'COMPROBANTE - TICKET EXTRAVIADO' : 'COMPROBANTE DE SALIDA Y PAGO',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: isLostTicket ? PdfColors.red900 : PdfColors.black,
                  ),
                ),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

                // Caja de Placa
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'PLACA: $licensePlate',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.Text(
                        'Ticket: $ticketCode',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                _buildPdfRow('Tipo Vehículo:', vehicleType),
                _buildPdfRow('Hora Ingreso:', entryTime),
                _buildPdfRow('Hora Salida:', exitTime),
                _buildPdfRow('Tiempo Total:', duration),
                _buildPdfRow('Método de Pago:', paymentMethod.toUpperCase()),
                if (penaltyAmount > 0 || isLostTicket)
                  _buildPdfRow('Recargo Ticket Perdido:', '+ Bs. ${penaltyAmount.toStringAsFixed(2)}'),
                if (discount > 0)
                  _buildPdfRow('Descuento:', '- Bs. ${discount.toStringAsFixed(2)}'),
                pw.Divider(thickness: 1),

                // Total Pagado en grande
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL PAGADO:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Bs. ${totalPaid.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),

                // Código QR de verificación
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrData,
                    width: 70,
                    height: 70,
                  ),
                ),

                pw.SizedBox(height: 6),
                _buildPdfRow('Atendido por:', cashier ?? 'Daniel Luna'),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Comprobante electrónico válido.\n¡Esperamos tenerle pronto de vuelta!',
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Recibo_Salida_$licensePlate.pdf',
    );
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
