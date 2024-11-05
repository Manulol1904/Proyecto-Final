// ignore_for_file: file_names, use_super_parameters, avoid_print

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:charts_flutter/flutter.dart' as charts;

// Function to convert Flutter Color to PdfColor
PdfColor _convertToPdfColor(Color color) {
  return PdfColor(color.red / 255, color.green / 255, color.blue / 255, color.opacity);
}

class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({Key? key}) : super(key: key);

  @override
  _MonthlyReportPageState createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  final GlobalKey chartKey = GlobalKey();
  Map<String, int> typeCounts = {'Matemáticas': 0, 'Inglés': 0, 'Física': 0};
  Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  Map<String, Map<String, dynamic>> tutorStats = {};
  List<Map<String, dynamic>> sessionDetails = []; // Nueva lista para almacenar los detalles de las sesiones

  Future<void> _loadSessionData() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));

    final sessions = await FirebaseFirestore.instance
        .collection('TutoringSessions')
        .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
        .where('timestamp', isLessThanOrEqualTo: endOfMonth)
        .get();

    final sessionData = sessions.docs;

    typeCounts = {'Matemáticas': 0, 'Inglés': 0, 'Física': 0};
    ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    tutorStats = {};
    sessionDetails = []; // Limpiar la lista de detalles

    for (var session in sessionData) {
      final String type = session['type'] ?? 'Desconocido';
      final int rating = session['rating'] ?? 0;
      final String tutorName = session['tutorName'] ?? 'Sin Nombre';
      final String studentName = session['studentName'] ?? 'Sin Nombre'; // Nuevo campo

      // Agregar detalles de la sesión a la lista
      sessionDetails.add({
        'tutorName': tutorName,
        'studentName': studentName,
        'type': type,
        'rating': rating,
      });

      if (typeCounts.containsKey(type)) typeCounts[type] = typeCounts[type]! + 1;
      if (ratingCounts.containsKey(rating)) ratingCounts[rating] = ratingCounts[rating]! + 1;

      if (tutorStats.containsKey(tutorName)) {
        tutorStats[tutorName]!['count'] += 1;
        tutorStats[tutorName]!['ratingSum'] += rating;
      } else {
        tutorStats[tutorName] = {'count': 1, 'ratingSum': rating};
      }
    }

    setState(() {});
  }

  Future<Uint8List> _generatePDFReport() async {
    final pdf = pw.Document();

    final chartImage = await _captureChartAsImage();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte Mensual de Tutorías',
                style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total de Tutorías: ${typeCounts.values.reduce((a, b) => a + b)}',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Resumen por Tipo de Tutoría',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue600),
              ),
              pw.SizedBox(height: 10),
              pw.Image(pw.MemoryImage(chartImage), height: 150),
              pw.SizedBox(height: 20),
              ...typeCounts.entries.map((entry) {
                final pdfColor = _getColorForType(entry.key);
                return pw.Row(
                  children: [
                    pw.Container(color: _convertToPdfColor(pdfColor), width: 20, height: 20),
                    pw.SizedBox(width: 10),
                    pw.Text('${entry.key}: ${((entry.value / typeCounts.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(2)}%'),
                  ],
                );
              }).toList(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Resumen de Tutores',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue600),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Tutor', 'Número de Tutorías', 'Promedio de Rating'],
                data: tutorStats.entries.map((entry) {
                  final String tutorName = entry.key;
                  final int sessionCount = entry.value['count'];
                  final double avgRating = entry.value['ratingSum'] / sessionCount;
                  return [tutorName, sessionCount, avgRating.toStringAsFixed(2)];
                }).toList(),
                cellStyle: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                },
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Detalle de Tutorías',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue600),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Tutor', 'Estudiante', 'Tipo', 'Rating'],
                data: sessionDetails.map((session) => [
                  session['tutorName'],
                  session['studentName'],
                  session['type'],
                  session['rating'].toString(),
                ]).toList(),
                cellStyle: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Matemáticas':
        return Colors.blue;
      case 'Inglés':
        return Colors.red;
      case 'Física':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<Uint8List> _captureChartAsImage() async {
    final boundary = chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: 2.0);
    final byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Reporte Mensual'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
      ),
      body: Center(
        child: Column(
          children: [
            RepaintBoundary(
              key: chartKey,
              child: SizedBox(
                height: 200,
                child: charts.PieChart(
                  [
                    charts.Series<MapEntry<String, int>, String>(
                      id: 'TutoringTypes',
                      domainFn: (entry, _) => entry.key,
                      measureFn: (entry, _) => entry.value,
                      labelAccessorFn: (entry, _) => '${entry.key}: ${((entry.value / typeCounts.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(2)}%',
                      data: typeCounts.entries.toList(),
                      colorFn: (entry, _) => charts.ColorUtil.fromDartColor(_getColorForType(entry.key)),
                    )
                  ],
                  animate: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: typeCounts.entries.map((entry) {
                final pdfColor = _getColorForType(entry.key);
                return Row(
                  children: [
                    Container(color: pdfColor, width: 20, height: 20),
                    const SizedBox(width: 10),
                    Text('${entry.key}: ${((entry.value / typeCounts.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(2)}%'),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final pdfData = await _generatePDFReport();
                await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfData);
              },
              child: const Text('Generar Reporte PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
