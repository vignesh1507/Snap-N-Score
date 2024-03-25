import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() {
    return _QRViewExampleState();
  }
}

class _QRViewExampleState extends State<QRViewExample> {
  bool showBottomSheet = false;
  bool? _checkboxValue = false;
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  //rk
  String? url;

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });

      int code = result!.code != null ? int.parse(result!.code!) : 0;

      if (await keyChecker(code)) {

        if (mounted) {

          if (result != null && !showBottomSheet) {

            showBottomSheet = true;
            // Show bottom sheet

            showModalBottomSheet(
              isDismissible: false,
              enableDrag: false,
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: ((context, setState) {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        height: 180,
                        width: Size.infinite.width,
                        child: Column(
                          children: [
                            const Text(
                              "Present ?",
                              style: TextStyle(fontSize: 25),
                            ),
                            Text(result!.code.toString()),
                            Checkbox(
                              value: _checkboxValue,
                              onChanged: (value) {
                                setState(() {
                                  _checkboxValue = value ?? false;
                                });
                              },
                            ),
                            // hardcodded
                            const SizedBox(
                              height: 27,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                FilledButton.tonal(
                                  onPressed: () {
                                    showBottomSheet = false;
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Submit"),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            );
          }
        }
      }
    });
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(flex: 4, child: _buildQrView(context)),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.white,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

Future<bool> keyChecker(int code) async {
  final result = await Supabase.instance.client.from('notes').select('key');
  print("result: $result");

  for (var row in result) {
    if (row['key'] == code) {
      print("Key found");
      return true;
    }
  }
  return false;
}
