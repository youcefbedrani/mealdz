import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/classifier_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/app_routes.dart';
import 'result_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  bool _isAnalyzing = false;
  Uint8List? _imageBytes;

  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _isAnalyzing = true;
    });

    await ref.read(predictionProvider.notifier).classify(bytes);

    if (!mounted) return;
    final result = ref.read(predictionProvider);
    if (result.hasError) {
      final err = result.error.toString();
      final locale = ref.read(localeProvider);
      final msg = err.contains('model') || err.contains('Interpreter')
          ? AppTranslations.translate(locale.languageCode, 'model_not_ready')
          : err.contains('network') || err.contains('Socket')
              ? AppTranslations.translate(locale.languageCode, 'offline_warning')
              : AppTranslations.translate(locale.languageCode, 'analysis_failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4)));
        setState(() => _isAnalyzing = false);
      }
      return;
    }

    Navigator.pushReplacement(
      context,
      slideUpRoute(ResultScreen(imageBytes: _imageBytes!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(locale),
              _buildViewfinder(locale),
              _buildTip(locale),
              _buildCaptureRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Locale locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconBtn(Icons.arrow_back, () => Navigator.pop(context)),
          Text(AppTranslations.translate(locale.languageCode, 'scan_meal'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          _iconBtn(Icons.photo_library_outlined,
              () => _pickImage(ImageSource.gallery)),
        ],
      ),
    );
  }

  Widget _buildViewfinder(Locale locale) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                  image: _imageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_imageBytes!),
                          fit: BoxFit.cover,
                          opacity: 0.7)
                      : null),
              child: _imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        Text(AppTranslations.translate(locale.languageCode, 'position_meal_in_frame'),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 15)),
                      ],
                    )
                  : _isAnalyzing
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                                color: Color(0xFF1D9E75), strokeWidth: 3),
                            const SizedBox(height: 20),
                            Text(AppTranslations.translate(locale.languageCode, 'analyzing_with_ai'),
                                style: const TextStyle(
                                    color: Color(0xFF1D9E75),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500)),
                          ],
                        )
                      : null,
            ),
            if (!_isAnalyzing) ...[
              _corner(top: 16, left: 16, bT: true, bL: true),
              _corner(top: 16, right: 16, bT: true, bR: true),
              _corner(bottom: 16, left: 16, bB: true, bL: true),
              _corner(bottom: 16, right: 16, bB: true, bR: true),
            ],
            if (_isAnalyzing)
              AnimatedBuilder(
                animation: _scanAnim,
                builder: (_, __) => Positioned(
                  top: _scanAnim.value *
                      (MediaQuery.of(context).size.height * 0.4),
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        Color(0xFF1D9E75),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(Locale locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _isAnalyzing
            ? AppTranslations.translate(locale.languageCode, 'please_wait_ai')
            : AppTranslations.translate(locale.languageCode, 'make_sure_plate_visible'),
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }

  Widget _buildCaptureRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: GestureDetector(
        onTap: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isAnalyzing ? Colors.white24 : Colors.white,
            border: Border.all(color: Colors.white38, width: 4),
          ),
          child: _isAnalyzing
              ? const SizedBox()
              : const Icon(Icons.camera_alt,
                  color: Color(0xFF1D9E75), size: 32),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.white12, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool bT = false,
    bool bB = false,
    bool bL = false,
    bool bR = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: bT
                ? const BorderSide(color: Color(0xFF1D9E75), width: 2.5)
                : BorderSide.none,
            bottom: bB
                ? const BorderSide(color: Color(0xFF1D9E75), width: 2.5)
                : BorderSide.none,
            left: bL
                ? const BorderSide(color: Color(0xFF1D9E75), width: 2.5)
                : BorderSide.none,
            right: bR
                ? const BorderSide(color: Color(0xFF1D9E75), width: 2.5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
