import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_share_me/flutter_share_me.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'pilote_data.dart';
import 'session_data_manager.dart';

class PiloteExportScreen extends StatefulWidget {
  final String sessionId;

  const PiloteExportScreen({super.key, required this.sessionId});

  @override
  State<PiloteExportScreen> createState() => _PiloteExportScreenState();
}

class _PiloteExportScreenState extends State<PiloteExportScreen> {
  final manager = SessionDataManager();
  late final TextEditingController _nameController;
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final defaultName =
        'pilote_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first}';
    _nameController = TextEditingController(
      text: manager.names[widget.sessionId] ?? defaultName,
    );
    manager.names[widget.sessionId] = _nameController.text;
    _nameController.addListener(() {
      manager.names[widget.sessionId] = _nameController.text;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _entry => manager.sessionData[widget.sessionId];

  Rect? _shareOriginFromKey() {
    final ctx = _shareButtonKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Future<File> _writePdfToDirectory(Directory dir) async {
    final entry = _entry!;
    return PiloteSessionExport.writeSessionPdfToPath(
      directoryPath: dir.path,
      fileBaseName: _nameController.text,
      sessionIdFallback: widget.sessionId,
      sessionEntry: entry,
    );
  }

  Future<void> _sharePdf() async {
    final entry = _entry;
    if (entry == null) {
      _toast('Session data missing.');
      return;
    }
    final origin = _shareOriginFromKey();
    final dir = await getApplicationDocumentsDirectory();
    final file = await _writePdfToDirectory(dir);
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Pilote session "${_nameController.text}"',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _savePdfToDocumentsOnly() async {
    final entry = _entry;
    if (entry == null) {
      _toast('Session data missing.');
      return;
    }
    final root = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${root.path}/pilote_exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = await _writePdfToDirectory(exportDir);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved PDF to\n${file.path}'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _sendToWhatsApp() async {
    final entry = _entry;
    if (entry == null) {
      _toast('Session data missing.');
      return;
    }
    final root = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${root.path}/pilote_exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = await _writePdfToDirectory(exportDir);
    if (!mounted) return;
    try {
      final response = await FlutterShareMe().shareToWhatsApp(
        msg: 'Pilote: ${_nameController.text}',
        imagePath: file.path,
      );
      if (!mounted) return;
      if (response != null && response.isNotEmpty && response != 'success') {
        _toast('WhatsApp: $response');
      }
    } catch (e) {
      if (!mounted) return;
      _toast('Could not open WhatsApp: $e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pilote')),
        body: const Center(child: Text('No session data.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Save / share'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Session name',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'File name (without .pdf)',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: _shareButtonKey,
              onPressed: _sharePdf,
              icon: const Icon(Icons.share),
              label: const Text('Share PDF'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _savePdfToDocumentsOnly,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save PDF to phone'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _sendToWhatsApp,
              icon: const Icon(Icons.chat),
              label: const Text('Send to WhatsApp'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SessionDataPage()),
                );
              },
              child: const Text('Open Session Data list'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
