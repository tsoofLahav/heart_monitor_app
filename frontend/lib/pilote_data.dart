import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'session_data_manager.dart';
import 'signal_chart_painter.dart';

class PiloteSessionExport {
  static String sanitizeFileBaseName(String raw, String fallbackId) {
    var s = raw.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();
    if (s.isEmpty) {
      final short = fallbackId.length >= 8 ? fallbackId.substring(0, 8) : fallbackId;
      s = 'session_$short';
    }
    return s;
  }

  static Future<File> writeSessionJsonToPath({
    required String directoryPath,
    required String fileBaseName,
    required String sessionIdFallback,
    required Map<String, dynamic> sessionEntry,
  }) async {
    final base = sanitizeFileBaseName(fileBaseName, sessionIdFallback);
    final path = '$directoryPath/$base.json';
    final file = File(path);
    await file.writeAsString(jsonEncode(sessionEntry));
    return file;
  }

  static Future<Uint8List> buildSessionPdfBytes({
    required String displayName,
    required Map<String, dynamic> sessionEntry,
  }) async {
    final startedAtUtc = sessionEntry['startedAtUtc']?.toString() ?? '(unknown)';
    final backend = sessionEntry['backend'];
    String fpsLine = 'FPS: (unknown)';
    String resolutionLine = 'Resolution: (unknown)';
    if (backend is Map) {
      final quality = backend['quality'];
      final fps = backend['fps'] ?? (quality is Map ? quality['fps'] : null);
      if (fps != null) fpsLine = 'FPS: $fps';
      final w = backend['video_width'] ?? (quality is Map ? quality['video_width'] : null);
      final h = backend['video_height'] ?? (quality is Map ? quality['video_height'] : null);
      if (w != null && h != null) {
        resolutionLine = 'Resolution: ${w}x$h';
      }
    }
    final jsonPayload = const JsonEncoder.withIndent('  ').convert(sessionEntry);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Pilote session export',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Name: $displayName', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 6),
          pw.Text('Started (UTC): $startedAtUtc', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 6),
          pw.Text(fpsLine, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 6),
          pw.Text(resolutionLine, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 16),
          pw.Text('Raw JSON', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Paragraph(
            text: jsonPayload,
            style: const pw.TextStyle(fontSize: 7, lineSpacing: 1.2),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static Future<File> writeSessionPdfToPath({
    required String directoryPath,
    required String fileBaseName,
    required String sessionIdFallback,
    required Map<String, dynamic> sessionEntry,
  }) async {
    final base = sanitizeFileBaseName(fileBaseName, sessionIdFallback);
    final path = '$directoryPath/$base.pdf';
    final file = File(path);
    final bytes = await buildSessionPdfBytes(
      displayName: fileBaseName.isNotEmpty ? fileBaseName : sessionIdFallback,
      sessionEntry: sessionEntry,
    );
    await file.writeAsBytes(bytes);
    return file;
  }
}

class PiloteSignalViewerPage extends StatelessWidget {
  final String sessionId;

  const PiloteSignalViewerPage({super.key, required this.sessionId});

  Map<String, dynamic>? _backend(SessionDataManager manager) {
    final entry = manager.sessionData[sessionId];
    if (entry == null) return null;
    final backend = entry['backend'];
    if (backend is! Map) return null;
    return Map<String, dynamic>.from(backend);
  }

  List<double>? _extractSignal(Map<String, dynamic> backend) {
    final cs = backend['clean_signal'];
    if (cs is! List) return null;
    try {
      return cs.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return null;
    }
  }

  List<double> _extractRealPeaks(Map<String, dynamic> backend) {
    final peaks = backend['real_peaks'];
    if (peaks is! List) return [];
    try {
      return peaks.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return [];
    }
  }

  double _extractDuration(Map<String, dynamic> backend) {
    final d = backend['duration'];
    if (d is num) return d.toDouble();
    final quality = backend['quality'];
    if (quality is Map) {
      final sec = quality['duration_sec'];
      if (sec is num) return sec.toDouble();
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final manager = SessionDataManager();
    final name = manager.names[sessionId] ?? 'Session $sessionId';
    final backend = _backend(manager);
    final signal = backend != null ? _extractSignal(backend) : null;
    final realPeaks = backend != null ? _extractRealPeaks(backend) : <double>[];
    final duration = backend != null ? _extractDuration(backend) : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(name, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: signal == null || signal.isEmpty
          ? const Center(
              child: Text(
                'No clean_signal in this session.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Signal (real peaks marked)',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${realPeaks.length} peak${realPeaks.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomPaint(
                            painter: SignalWithPeaksPainter(
                              signal: signal,
                              realPeaks: realPeaks,
                              duration: duration,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class SessionDataPage extends StatefulWidget {
  const SessionDataPage({super.key});

  @override
  State<SessionDataPage> createState() => _SessionDataPageState();
}

class _SessionDataPageState extends State<SessionDataPage> {
  final manager = SessionDataManager();

  Rect? _shareOriginFromContext(BuildContext? ctx) {
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Future<void> _sharePdf(String id, BuildContext buttonContext) async {
    final origin = _shareOriginFromContext(buttonContext);
    final name = manager.names[id] ?? 'session_$id';
    final entry = manager.sessionData[id];
    if (entry == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = await PiloteSessionExport.writeSessionPdfToPath(
      directoryPath: dir.path,
      fileBaseName: name,
      sessionIdFallback: id,
      sessionEntry: entry,
    );
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Pilote session "$name"',
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = manager.sessionData.entries.toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Session Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (_, index) {
          final id = entries[index].key;
          final name = manager.names[id] ?? 'Session $id';

          return ListTile(
            title: TextField(
              controller: TextEditingController(text: name),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Session Name',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) => manager.names[id] = value,
            ),
            leading: IconButton(
              tooltip: 'View signal',
              icon: const Icon(Icons.show_chart, color: Colors.tealAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PiloteSignalViewerPage(sessionId: id),
                  ),
                );
              },
            ),
            trailing: Builder(
              builder: (btnCtx) => IconButton(
                tooltip: 'Share PDF',
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: () => _sharePdf(id, btnCtx),
              ),
            ),
          );
        },
      ),
    );
  }
}
