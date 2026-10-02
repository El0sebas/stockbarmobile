import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/empresa.dart';
import '../data/mock_data.dart';

String _money(num n) {
  final rounded = n.round();
  final digits = rounded.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '\$ ${rounded < 0 ? '-' : ''}$buf';
}

String _documentoCliente(
  Map<String, dynamic> venta,
  List<Map<String, dynamic>> clientes,
) {
  final idCliente = venta['id_cliente'];
  if (idCliente == null || idCliente == 0) return 'Consumidor final';
  final cliente = clientes.firstWhere(
    (c) => c['id_cliente'] == idCliente,
    orElse: () => const {},
  );
  return cliente.isEmpty ? 'Consumidor final' : 'CC ${cliente['id_cliente']}';
}

// Genera los bytes de la factura de venta — mismo formato y las mismas
// reglas (desglose de IVA por tarifa, forma de pago, disclaimer legal) que
// stockbar-web/src/utils/factura.js, adaptado a widgets del paquete `pdf`
// (puro Dart, ver data/empresa.dart para por qué no se usa `printing` aquí).
Future<Uint8List> generarFacturaPdfBytes(
  Map<String, dynamic> venta, {
  List<Map<String, dynamic>> clientes = const [],
}) async {
  final doc = pw.Document();
  final productos = (venta['productos'] as List).cast<Map<String, dynamic>>();
  final pagos = (venta['pagos'] as List).cast<Map<String, dynamic>>();
  final idFactura = 'VNT-${venta['id'].toString().padLeft(3, '0')}';
  final fecha = venta['fecha_hora_venta'] as DateTime;

  final tarifas =
      productos.map((p) => (p['porcentajeIva'] as num?) ?? 0).toSet().toList()
        ..sort();
  final desglose = tarifas.map((tasa) {
    final items = productos
        .where((p) => ((p['porcentajeIva'] as num?) ?? 0) == tasa)
        .toList();
    final t = calcularTotalesVenta(items);
    return ['$tasa%', _money(t['baseGravable']!), _money(t['iva']!)];
  }).toList();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    EmpresaEmisora.razonSocial,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'NIT: ${EmpresaEmisora.nit}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    EmpresaEmisora.direccion,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Tel: ${EmpresaEmisora.telefono}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    EmpresaEmisora.regimen,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'FACTURA DE VENTA',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'No. $idFactura',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.SizedBox(
                    width: 180,
                    child: pw.Text(
                      EmpresaEmisora.resolucionDian,
                      style: const pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Fecha: ${formatearFecha(fecha)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Vendedor: ${venta['usuario'] ?? 'N/A'}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Cliente: ${venta['cliente']}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Documento: ${_documentoCliente(venta, clientes)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              'Cant.',
              'Descripción',
              'Precio unit.',
              'IVA',
              'Subtotal',
            ],
            data: productos
                .map(
                  (p) => [
                    '${p['cantidad']}',
                    '${p['nombre']}',
                    _money(p['precio'] as num),
                    '${p['porcentajeIva'] ?? 0}%',
                    _money((p['precio'] as num) * (p['cantidad'] as num)),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1A365D),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignments: {
              0: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 10),
          pw.SizedBox(
            width: 260,
            child: pw.TableHelper.fromTextArray(
              headers: ['Tarifa IVA', 'Base gravable', 'IVA'],
              data: desglose,
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF59E0B),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL A PAGAR: ${_money(venta['total'] as num)}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Forma de pago:',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          if (pagos.isEmpty)
            pw.Text(
              '- Sin pagos registrados',
              style: const pw.TextStyle(fontSize: 9),
            )
          else
            ...pagos.map(
              (p) => pw.Text(
                '- ${p['metodo']}: ${_money(p['monto'] as num)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Este documento es una representación de la venta generada por el sistema StockBar y no constituye factura electrónica DIAN.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            'Para efectos tributarios formales, valide la numeración autorizada ante la DIAN.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

// ponytail: ruta de almacenamiento propia de la app hardcodeada (sin
// path_provider) porque cualquier plugin federado exige "Modo de
// desarrollador" de Windows en este equipo para compilar el APK — apenas se
// active, subir esto a path_provider.getApplicationDocumentsDirectory().
Future<String> guardarFacturaPdf(Uint8List bytes, String nombreArchivo) async {
  final dir = Directory(
    '/storage/emulated/0/Android/data/com.example.stockbar_mobile/files/facturas',
  );
  await dir.create(recursive: true);
  final file = File('${dir.path}/$nombreArchivo.pdf');
  await file.writeAsBytes(bytes);
  return file.path;
}
