import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../models/parsed_receipt.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../widgets/receipt_frame_overlay.dart';
import 'receipt_review_screen.dart';

typedef GalleryImagePicker = Future<XFile?> Function();
typedef ReceiptImageCropper = Future<CroppedFile?> Function(String imagePath);
typedef ReceiptTextRecognizer = Future<String> Function(String imagePath);

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    required this.onSaved,
    this.pickImage,
    this.cropImage,
    this.recognizeText,
    super.key,
  });

  final VoidCallback onSaved;
  final GalleryImagePicker? pickImage;
  final ReceiptImageCropper? cropImage;
  final ReceiptTextRecognizer? recognizeText;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final _ocrService = const OcrService();
  final _receiptParser = ReceiptParser();
  final _cropper = ImageCropper();
  final _imagePicker = ImagePicker();

  CameraController? _controller;
  ParsedReceipt? _parsedReceipt;
  String? _croppedImagePath;
  String? _recognizedText;
  String? _cameraError;
  String? _ocrError;
  bool _isInitializing = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  bool _flashEnabled = false;
  bool _flashUnavailable = false;
  int _cameraGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_releaseCamera());
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed &&
        _croppedImagePath == null &&
        !_isCapturing) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing || _controller != null || _croppedImagePath != null) {
      return;
    }

    final generation = ++_cameraGeneration;
    _isInitializing = true;
    if (mounted) {
      setState(() {
        _cameraError = null;
      });
    }

    CameraController? pendingController;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCameraAvailable', 'No camera was found.');
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      pendingController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await pendingController.initialize();

      if (!mounted || generation != _cameraGeneration) return;
      setState(() {
        _controller = pendingController;
        _cameraError = null;
        _flashUnavailable = false;
      });
      pendingController = null;
    } on CameraException catch (error) {
      if (mounted && generation == _cameraGeneration) {
        setState(() => _cameraError = _cameraErrorMessage(error));
      }
    } catch (_) {
      if (mounted && generation == _cameraGeneration) {
        setState(
          () => _cameraError =
              'Không thể mở camera. Hãy thử lại hoặc kiểm tra quyền camera.',
        );
      }
    } finally {
      if (pendingController != null) {
        try {
          await pendingController.dispose();
        } on PlatformException {
          // CameraX can fail to release a preview surface that was never
          // created when controller initialization fails. Preserve the
          // original initialization error shown by this screen.
        }
      }
      if (mounted && generation == _cameraGeneration) {
        setState(() => _isInitializing = false);
      }
    }
  }

  String _cameraErrorMessage(CameraException error) {
    if (error.code.contains('Denied') || error.code.contains('Restricted')) {
      return 'Quyền camera chưa được cấp. Hãy cho phép camera rồi thử lại.';
    }
    return 'Camera hiện không khả dụng. Hãy thử lại.';
  }

  Future<void> _releaseCamera() async {
    _cameraGeneration++;
    final controller = _controller;
    _controller = null;
    _isInitializing = false;
    _flashEnabled = false;
    if (controller != null) await controller.dispose();
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || _flashUnavailable) return;

    final nextEnabled = !_flashEnabled;
    try {
      await controller.setFlashMode(
        nextEnabled ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() => _flashEnabled = nextEnabled);
    } on CameraException {
      if (mounted) {
        setState(() {
          _flashUnavailable = true;
          _flashEnabled = false;
        });
        _showMessage('Đèn flash không được hỗ trợ trên camera này.');
      }
    }
  }

  Future<void> _focusAt(
    Offset tapPosition,
    Size viewportSize,
    double previewAspectRatio,
  ) async {
    final controller = _controller;
    if (controller == null || !controller.value.focusPointSupported) {
      _showMessage('Chạm lấy nét không được hỗ trợ trên thiết bị này.');
      return;
    }

    final viewportRatio = viewportSize.width / viewportSize.height;
    final previewWidth = previewAspectRatio >= viewportRatio
        ? viewportSize.height * previewAspectRatio
        : viewportSize.width;
    final previewHeight = previewAspectRatio >= viewportRatio
        ? viewportSize.height
        : viewportSize.width / previewAspectRatio;
    final horizontalInset = (previewWidth - viewportSize.width) / 2;
    final verticalInset = (previewHeight - viewportSize.height) / 2;
    final point = Offset(
      ((tapPosition.dx + horizontalInset) / previewWidth)
          .clamp(0.0, 1.0)
          .toDouble(),
      ((tapPosition.dy + verticalInset) / previewHeight)
          .clamp(0.0, 1.0)
          .toDouble(),
    );

    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setFocusPoint(point);
    } on CameraException {
      if (mounted) _showMessage('Không thể lấy nét tại điểm đã chọn.');
    }
  }

  Future<void> _captureAndCrop() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _cameraError = null;
    });

    String? originalPath;
    try {
      final photo = await controller.takePicture();
      originalPath = photo.path;
      if (!mounted) return;

      await _cropAndRecognize(photo.path);
    } on CameraException catch (error) {
      if (mounted) _showMessage(_cameraErrorMessage(error));
    } on PlatformException {
      if (mounted) {
        _showMessage('Không thể cắt ảnh. Hãy thử chụp lại hóa đơn.');
      }
    } on FileSystemException {
      if (mounted) _showMessage('Không thể đọc ảnh vừa chụp. Hãy thử lại.');
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể xử lý ảnh hóa đơn. Hãy thử chụp lại.');
      }
    } finally {
      if (originalPath != null && originalPath != _croppedImagePath) {
        try {
          await File(originalPath).delete();
        } on FileSystemException {
          // The camera may already have removed its temporary capture.
        }
      }
      if (mounted) {
        setState(() => _isCapturing = false);
        if (_croppedImagePath == null && _controller == null) {
          unawaited(_initializeCamera());
        }
      }
    }
  }

  Future<void> _importFromGallery() async {
    if (_isCapturing || _isProcessing) return;

    setState(() {
      _isCapturing = true;
      _cameraError = null;
    });

    try {
      final selectedImage =
          await (widget.pickImage?.call() ??
              _imagePicker.pickImage(source: ImageSource.gallery));
      if (!mounted || selectedImage == null) return;

      final extension = path.extension(selectedImage.name).toLowerCase();
      if (!const {'.jpg', '.jpeg', '.png'}.contains(extension)) {
        throw const FormatException('Unsupported receipt image format.');
      }

      final selectedFile = File(selectedImage.path);
      if (!selectedFile.existsSync() || selectedFile.lengthSync() == 0) {
        throw FileSystemException(
          'Selected receipt image is unavailable',
          selectedImage.path,
        );
      }

      await _cropAndRecognize(selectedImage.path);
    } on PlatformException {
      if (mounted) _showMessage('Không thể mở thư viện ảnh. Hãy thử lại.');
    } on FileSystemException {
      if (mounted) {
        _showMessage('Không thể đọc ảnh đã chọn. Hãy chọn ảnh khác.');
      }
    } on FormatException {
      if (mounted) {
        _showMessage('Chỉ hỗ trợ ảnh JPG, JPEG hoặc PNG.');
      }
    } catch (_) {
      if (mounted) _showMessage('Không thể xử lý ảnh đã chọn. Hãy thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
        if (_croppedImagePath == null && _controller == null) {
          unawaited(_initializeCamera());
        }
      }
    }
  }

  Future<void> _cropAndRecognize(String sourcePath) async {
    final croppedFile =
        await (widget.cropImage?.call(sourcePath) ??
            _cropper.cropImage(
              sourcePath: sourcePath,
              compressFormat: ImageCompressFormat.jpg,
              compressQuality: 92,
              uiSettings: [
                AndroidUiSettings(
                  toolbarTitle: 'Cắt hóa đơn',
                  toolbarColor: Theme.of(context).colorScheme.primary,
                  toolbarWidgetColor: Colors.white,
                  activeControlsWidgetColor: Theme.of(context)
                      .colorScheme
                      .primary,
                  showCropGrid: true,
                  lockAspectRatio: false,
                  aspectRatioPresets: const [CropAspectRatioPreset.original],
                ),
              ],
            ));
    if (!mounted || croppedFile == null) return;

    final cropFile = File(croppedFile.path);
    if (!cropFile.existsSync() || cropFile.lengthSync() == 0) {
      throw const FileSystemException('Cropped receipt image was not found.');
    }

    setState(() => _croppedImagePath = cropFile.path);
    await _runOcr(cropFile.path);
  }

  Future<void> _runOcr(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _ocrError = null;
      _recognizedText = null;
      _parsedReceipt = null;
    });

    try {
      final recognizedText =
          await (widget.recognizeText?.call(imagePath) ??
              _ocrService.recognizeText(imagePath));
      final parsedReceipt = _receiptParser.parse(recognizedText);
      if (!mounted) return;

      setState(() {
        _recognizedText = recognizedText;
        _parsedReceipt = parsedReceipt;
      });

      if (recognizedText.isEmpty) {
        setState(
          () => _ocrError = 'Không nhận diện được chữ. Bạn có thể thử lại hoặc nhập thủ công.',
        );
        return;
      }

      await _openReview(parsedReceipt);
    } catch (_) {
      if (mounted) {
        setState(
          () => _ocrError =
              'Đọc hóa đơn thất bại. Hãy thử lại hoặc nhập thông tin thủ công.',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openManualReview() async {
    final parsedReceipt =
        _parsedReceipt ?? ParsedReceipt(rawText: _recognizedText ?? '');
    await _openReview(parsedReceipt);
  }

  Future<void> _openReview(ParsedReceipt parsedReceipt) async {
    final imagePath = _croppedImagePath;
    if (imagePath == null) return;

    await _releaseCamera();
    if (!mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReceiptReviewScreen(
          imagePath: imagePath,
          parsedReceipt: parsedReceipt,
          ocrError: _ocrError,
        ),
      ),
    );
    if (!mounted) return;

    if (saved != true) {
      await _discardCroppedImage();
      return;
    }
    await _discardCroppedImage(reopenCamera: false);
    if (mounted) widget.onSaved();
  }

  Future<void> _discardCroppedImage({bool reopenCamera = true}) async {
    final imagePath = _croppedImagePath;
    setState(() {
      _croppedImagePath = null;
      _recognizedText = null;
      _parsedReceipt = null;
      _ocrError = null;
    });
    if (imagePath != null) {
      try {
        await File(imagePath).delete();
      } on FileSystemException {
        // A removed or temporary image needs no further cleanup.
      }
    }
    if (mounted && reopenCamera && _controller == null) {
      unawaited(_initializeCamera());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _croppedImagePath;
    if (imagePath != null) {
      return _buildCroppedScreen(imagePath);
    }
    return _buildCameraScreen();
  }

  Widget _buildCameraScreen() {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Quét hóa đơn')),
      body: Column(
        children: [
          Expanded(
            child: controller != null && controller.value.isInitialized
                ? _buildCameraPreview(controller)
                : _buildCameraLoadingOrError(),
          ),
          if (controller != null && controller.value.isInitialized)
            _buildCameraControls(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCapturing || _isProcessing
                      ? null
                      : _importFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Chọn ảnh từ thư viện'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLoadingOrError() {
    final error = _cameraError;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 48),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isInitializing ? null : _initializeCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Đang mở camera…'),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;
        final aspectRatio = isPortrait
            ? 1 / controller.value.aspectRatio
            : controller.value.aspectRatio;
        final viewportRatio = viewportSize.width / viewportSize.height;
        final previewWidth = aspectRatio >= viewportRatio
            ? viewportSize.height * aspectRatio
            : viewportSize.width;
        final previewHeight = aspectRatio >= viewportRatio
            ? viewportSize.height
            : viewportSize.width / aspectRatio;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              _focusAt(details.localPosition, viewportSize, aspectRatio),
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: CameraPreview(controller),
                  ),
                ),
                const Positioned.fill(child: ReceiptFrameOverlay()),
                if (_isCapturing)
                  ColoredBox(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraControls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filledTonal(
              tooltip: _flashUnavailable
                  ? 'Flash không hỗ trợ'
                  : _flashEnabled
                  ? 'Tắt flash'
                  : 'Bật flash',
              onPressed: _flashUnavailable || _isCapturing
                  ? null
                  : _toggleFlash,
              icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
            ),
            IconButton.filled(
              tooltip: 'Chụp hóa đơn',
              onPressed: _isCapturing ? null : _captureAndCrop,
              iconSize: 32,
              icon: const Icon(Icons.camera_alt_outlined),
              style: IconButton.styleFrom(minimumSize: const Size(68, 68)),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCroppedScreen(String imagePath) {
    final error = _ocrError;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đọc hóa đơn'),
        leading: IconButton(
          tooltip: 'Chụp lại',
          onPressed: _isProcessing ? null : () => _discardCroppedImage(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ImagePreview(imagePath: imagePath),
          const SizedBox(height: 20),
          if (_isProcessing) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            const Text(
              'Đang nhận diện chữ trên ảnh đã cắt…',
              textAlign: TextAlign.center,
            ),
          ] else if (error != null) ...[
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _runOcr(imagePath),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử nhận diện lại'),
            ),
            FilledButton.icon(
              onPressed: _openManualReview,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Nhập thông tin thủ công'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final temporaryImage = _croppedImagePath;
    if (temporaryImage != null) {
      unawaited(_deleteTemporaryImage(temporaryImage));
    }
    unawaited(_releaseCamera());
    super.dispose();
  }

  Future<void> _deleteTemporaryImage(String imagePath) async {
    try {
      await File(imagePath).delete();
    } on FileSystemException {
      // The cropper may have already removed its cached file.
    }
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 340,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 40),
              SizedBox(height: 8),
              Text('Không thể hiển thị ảnh hóa đơn.'),
            ],
          ),
        ),
      ),
    );
  }
}
