import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

  Future<void> _shareInvoice() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final pdf = pw.Document();
      final orderId = widget.orderData['orderId'] ?? DateTime.now().millisecondsSinceEpoch;

      // Get items list
      final items = widget.orderData['items'] as List<dynamic>?;
      final hasItems = items != null && items.isNotEmpty;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // HEADER
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'GAS DELIVERY SERVICE',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'GSTIN: 36AAAAA0000A1Z5',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // ORDER DETAILS
                pw.Text('Order Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                _pdfRow('Order ID', widget.orderData['orderId'] ?? 'N/A'),
                _pdfRow('Date', _formatDate(widget.orderData['createdAt'])),
                _pdfRow('Status', widget.orderData['status'] ?? 'Pending'),
                _pdfRow('Payment Method', widget.orderData['paymentMethod'] ?? 'COD'),
                pw.SizedBox(height: 20),

                // CUSTOMER DETAILS
                pw.Text('Customer Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                _pdfRow('Name', widget.orderData['userName'] ?? 'N/A'),
                _pdfRow('Phone', widget.orderData['phone'] ?? 'N/A'),
                _pdfRow('Address', widget.orderData['address'] ?? 'N/A'),
                if (widget.orderData['area'] != null)
                  _pdfRow('Area', widget.orderData['area']),
                pw.SizedBox(height: 20),

                // ITEMS TABLE
                pw.Text('Items', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                    // Items
                    if (hasItems)
                      ...items.map((item) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(item['name'] ?? 'Product'),
                                    if (item['weight'] != null)
                                      pw.Text(item['weight'], style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                                  ],
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('${item['quantity'] ?? 1}', textAlign: pw.TextAlign.center),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Rs.${item['price'] ?? 0}', textAlign: pw.TextAlign.right),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Rs.${(item['price'] ?? 0) * (item['quantity'] ?? 1)}', textAlign: pw.TextAlign.right),
                              ),
                            ],
                          ))
                    else
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(widget.orderData['productName'] ?? 'Product'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${widget.orderData['quantity'] ?? 1}', textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Rs.${widget.orderData['price'] ?? 0}', textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Rs.${widget.orderData['price'] ?? 0}', textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // DELIVERY INFO
                pw.Text('Delivery Information', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                _pdfRow('Type', widget.orderData['deliveryType'] ?? 'Normal'),
                if (widget.orderData['deliverySlot'] != null)
                  _pdfRow('Slot', widget.orderData['deliverySlot']),
                pw.SizedBox(height: 20),

                pw.Divider(thickness: 2),
                pw.SizedBox(height: 10),

                // TOTAL
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Amount:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      'Rs.${widget.orderData['totalAmount'] ?? widget.orderData['price'] ?? '0'}',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                pw.Center(
                  child: pw.Text(
                    'Thank you for your order!',
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final fileName = 'invoice_$orderId.pdf';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Order Invoice #$orderId',
      );

    } catch (e) {
      print("Error sharing invoice: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Invoice"),
        backgroundColor: const Color(0xFFE50914),
        actions: [
          IconButton(
            onPressed: _isDownloading ? null : _shareInvoice,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share),
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
                    // HEADER WITH COMPANY INFO
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            "GAS DELIVERY SERVICE",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "TAX INVOICE",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE50914),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "GSTIN: 36AAAAA0000A1Z5",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 30, thickness: 2),
                    
                    // ORDER DETAILS
                    _buildSection("Order Details"),
                    _row("Order ID", widget.orderData['orderId'] ?? 'N/A'),
                    _row("Date", _formatDate(widget.orderData['createdAt'])),
                    _row("Status", widget.orderData['status'] ?? 'Pending'),
                    _row("Payment Method", widget.orderData['paymentMethod'] ?? 'COD'),
                    
                    const SizedBox(height: 20),
                    
                    // CUSTOMER DETAILS
                    _buildSection("Customer Details"),
                    _row("Name", widget.orderData['userName'] ?? 'N/A'),
                    _row("Phone", widget.orderData['phone'] ?? 'N/A'),
                    _row("Address", widget.orderData['address'] ?? 'N/A'),
                    if (widget.orderData['area'] != null)
                      _row("Area", widget.orderData['area']),
                    
                    const SizedBox(height: 20),
                    
                    // ITEMS TABLE
                    _buildSection("Items"),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "Item",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    "Qty",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Price",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Total",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Table Rows
                          if (widget.orderData['items'] != null && (widget.orderData['items'] as List).isNotEmpty)
                            ...((widget.orderData['items'] as List).map((item) => Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'] ?? 'Product',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            if (item['weight'] != null)
                                              Text(
                                                item['weight'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "${item['quantity'] ?? 1}",
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "₹${item['price'] ?? 0}",
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "₹${(item['price'] ?? 0) * (item['quantity'] ?? 1)}",
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                )))
                          else
                            // Fallback for old orders
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(widget.orderData['productName'] ?? 'Product'),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "${widget.orderData['quantity'] ?? 1}",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "₹${widget.orderData['price'] ?? 0}",
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "₹${widget.orderData['price'] ?? 0}",
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // DELIVERY INFO
                    _buildSection("Delivery Information"),
                    _row("Type", widget.orderData['deliveryType'] ?? 'Normal'),
                    if (widget.orderData['deliverySlot'] != null)
                      _row("Slot", widget.orderData['deliverySlot']),
                    
                    const Divider(height: 30, thickness: 2),
                    
                    // TOTAL AMOUNT
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
                          "₹${widget.orderData['totalAmount'] ?? widget.orderData['price'] ?? '0'}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE50914),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    const Center(
                      child: Text(
                        "Thank you for your order!",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 14,
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
