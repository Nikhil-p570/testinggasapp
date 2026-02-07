import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class OrderInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderInvoiceScreen({super.key, required this.orderData});

  @override
  State<OrderInvoiceScreen> createState() => _OrderInvoiceScreenState();
}

class _OrderInvoiceScreenState extends State<OrderInvoiceScreen> {
  final GlobalKey _invoiceKey = GlobalKey();
  bool _isDownloading = false;

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
        date = (timestamp as dynamic).toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'N/A';
      }
      
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _downloadInvoice() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission denied'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isDownloading = false;
            });
            return;
          }
        }
      }

      RenderRepaintBoundary boundary = _invoiceKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final orderId = widget.orderData['orderId'] ?? DateTime.now().millisecondsSinceEpoch;
      final fileName = 'invoice_$orderId.png';
      final filePath = '${directory!.path}/$fileName';

      File imgFile = File(filePath);
      await imgFile.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice saved to: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print("Error downloading invoice: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isDownloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Invoice"),
        backgroundColor: const Color(0xFFE50914),
        actions: [
          IconButton(
            onPressed: _isDownloading ? null : _downloadInvoice,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _invoiceKey,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "ORDER INVOICE",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE50914),
                        ),
                      ),
                    ),
                    const Divider(height: 30, thickness: 2),
                    
                    _buildSection("Order Details"),
                    _row("Order ID", widget.orderData['orderId'] ?? 'N/A'),
                    _row("Date", _formatDate(widget.orderData['createdAt'])),
                    _row("Status", widget.orderData['status'] ?? 'Pending'),
                    
                    const SizedBox(height: 20),
                    
                    _buildSection("Product Information"),
                    _row("Product", widget.orderData['productName'] ?? 'N/A'),
                    _row("Price", "₹${widget.orderData['price'] ?? '0'}"),
                    _row("Quantity", widget.orderData['quantity']?.toString() ?? '1'),
                    
                    const SizedBox(height: 20),
                    
                    _buildSection("Delivery Information"),
                    _row("Type", widget.orderData['deliveryType'] ?? 'Standard'),
                    _row("Address", widget.orderData['address'] ?? 'N/A'),
                    _row("Phone", widget.orderData['phone'] ?? 'N/A'),
                    
                    const SizedBox(height: 20),
                    
                    _buildSection("Payment Information"),
                    _row("Method", widget.orderData['paymentMethod'] ?? 'N/A'),
                    
                    const Divider(height: 30, thickness: 2),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Amount:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "₹${widget.orderData['price'] ?? '0'}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE50914),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Center(
                      child: Text(
                        "Thank you for your order!",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE50914),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
