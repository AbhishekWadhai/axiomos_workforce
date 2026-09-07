import 'dart:convert';

import 'package:axiomos_workforce/model/attendance/qr_model.dart';
import 'package:axiomos_workforce/services/encryption.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPlaceholder extends StatefulWidget {
  const QRScannerPlaceholder({super.key});

  @override
  State<QRScannerPlaceholder> createState() => _QRScannerPlaceholderState();
}

class _QRScannerPlaceholderState extends State<QRScannerPlaceholder> {
  late final MobileScannerController scannerController;

  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    print("QRScannerPlaceholder initState called");
    scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    WorkerQrData? workerqrDecryptedValue;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;

    if (value == null || value.isEmpty) return;

    debugPrint('QR CODE DETECTED: $value');

    try {
      final decrypted = await EncryptionService().decryptQrData(value);

      debugPrint('Decrypted QR: $decrypted');

      final dataParsed = WorkerQrData.fromJson(jsonDecode(decrypted));

      debugPrint(
        '-------'
        '${dataParsed.id} '
        '${dataParsed.firstName} '
        '${dataParsed.lastName} '
        '${dataParsed.labourCode}'
        '---------',
      );
      workerqrDecryptedValue = dataParsed;
      // Stop scanning
      await scannerController.stop();
      Navigator.pop(context, dataParsed);
      // Send WorkerQrData back to the bottom sheet caller
    } catch (e, stackTrace) {
      debugPrint('QR decryption failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .78,
      decoration: const BoxDecoration(
        color: Color(0xFF11152D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),

                  const Expanded(
                    child: Text(
                      'Scan Labour QR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // SCANNER
            SizedBox(
              width: 270,
              height: 270,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: scannerController,
                      onDetect: _onDetect,
                    ),

                    // DARK OVERLAY
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),

                    // CORNERS
                    const _ScannerCorners(),

                    // SCANNING LINE
                    const _ScanningLine(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Position the QR code inside the frame',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'The labour attendance will be marked automatically',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),

            const Spacer(),

            // FLASH BUTTON
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: scannerController,
              builder: (context, state, child) {
                final torchState = state.torchState;

                if (torchState == TorchState.unavailable) {
                  return const SizedBox(height: 50);
                }

                final isTorchOn = torchState == TorchState.on;

                return IconButton(
                  onPressed: () {
                    scannerController.toggleTorch();
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .12),
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: Icon(
                    isTorchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: _Corner(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(25)),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _Corner(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(25),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: _Corner(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _Corner(
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(25),
            ),
          ),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final BorderRadius borderRadius;

  const _Corner({required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 4),
        borderRadius: borderRadius,
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, -0.85 + (controller.value * 1.7)),
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: .6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
