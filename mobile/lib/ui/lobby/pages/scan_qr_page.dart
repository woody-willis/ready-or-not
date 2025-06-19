import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({
    super.key,
  });

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  bool hasScanned = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: MobileScanner(
        onDetect: (result) {
          if (hasScanned) {
            return;
          }

          hasScanned = true;

          for (final barcode in result.barcodes) {
            if (barcode.rawValue == null) {
              continue;
            }
            
            final String url = result.barcodes.first.rawValue!;
            
            final Uri? upperUri = Uri.tryParse(url);
            if (upperUri == null) {
              return;
            }

            final Uri? lowerUri = Uri.tryParse(upperUri.query.substring(1));
            if (lowerUri == null) {
              return;
            }

            final String? code = lowerUri.queryParameters['code'];
            if (code != null) {
              Navigator.pop(context, code);
              return;
            }
          }

          hasScanned = false;
        },
        fit: BoxFit.cover,
      ),
    );
  }
}