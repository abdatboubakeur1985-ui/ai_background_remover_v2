import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// IMPORTANT: For production, do NOT ship a secret API key inside the APK.
// Put the remove.bg call behind your own backend/proxy.
const String removeBgApiKey = 'PUT_YOUR_REMOVE_BG_API_KEY_HERE';
const String proProductId = 'ai_background_remover_pro_lifetime_3eur';

void main() => runApp(const BackgroundRemoverApp());

class BackgroundRemoverApp extends StatelessWidget {
  const BackgroundRemoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Background Remover',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _input;
  Uint8List? _result;
  bool _busy = false;
  bool _pro = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 95);
    if (file == null) return;
    setState(() {
      _input = file;
      _result = null;
      _error = null;
    });
    await _removeBackground(file);
  }

  Future<void> _removeBackground(XFile file) async {
    if (removeBgApiKey == 'PUT_YOUR_REMOVE_BG_API_KEY_HERE') {
      setState(() => _error = 'أضف مفتاح remove.bg API أولًا.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
      );
      request.headers['X-Api-Key'] = removeBgApiKey;
      request.fields['size'] = 'auto';
      request.files.add(http.MultipartFile.fromBytes(
        'image_file',
        bytes,
        filename: file.name,
      ));
      final response = await request.send();
      final body = await response.stream.toBytes();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => _result = body);
      } else {
        setState(() => _error = 'فشلت المعالجة (${response.statusCode}).');
      }
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء إزالة الخلفية.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _shareResult() async {
    if (_result == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/removed_background.png');
    await file.writeAsBytes(_result!);
    await SharePlus.instance.share(ShareParams(
      text: 'AI Background Remover',
      files: [XFile(file.path)],
    ));
  }

  Future<void> _saveResult() async {
    if (_result == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/removed_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(_result!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الصورة داخل التطبيق.')),
      );
    }
  }

  void _showPro() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('AI Background Remover PRO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('3€ • شراء مرة واحدة', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          const Text('✓ بدون إعلانات\n✓ HD\n✓ جودة أعلى\n✓ بدون علامة مائية'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سنربط Google Play Billing في مرحلة النشر.')),
              );
            },
            child: const Text('اشترِ PRO بـ 3€'),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Background Remover'),
        actions: [
          IconButton(onPressed: _showPro, icon: const Icon(Icons.workspace_premium)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(colors: [Color(0xff6c3cff), Color(0xffb83cff)]),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('أزل الخلفية بالذكاء الاصطناعي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('اختر صورة وسنحاول فصل الشخص أو العنصر الرئيسي تلقائيًا.'),
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: _busy ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('اختر صورة'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('الكاميرا'))),
            ]),
            const SizedBox(height: 24),
            if (_busy) const Center(child: Padding(padding: EdgeInsets.all(30), child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('جاري إزالة الخلفية...')]))),
            if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!))),
            if (_input != null && _result == null && !_busy)
              ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(_input!.path), fit: BoxFit.cover)),
            if (_result != null) ...[
              const Text('النتيجة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  image: const DecorationImage(image: AssetImage('assets/checker.png'), repeat: ImageRepeat.repeat),
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_result!)),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: FilledButton.icon(onPressed: _saveResult, icon: const Icon(Icons.download), label: const Text('حفظ PNG'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: _shareResult, icon: const Icon(Icons.share), label: const Text('مشاركة'))),
              ]),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(onPressed: _pro ? () {} : _showPro, icon: const Icon(Icons.hd), label: Text(_pro ? 'تصدير HD' : 'فتح HD • PRO 3€')),
            ],
          ],
        ),
      ),
    );
  }
}
