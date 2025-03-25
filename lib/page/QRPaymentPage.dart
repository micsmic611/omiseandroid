import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class QRPaymentPage extends StatefulWidget {
  @override
  _QRPaymentPageState createState() => _QRPaymentPageState();
}

class _QRPaymentPageState extends State<QRPaymentPage> {
  String? sourceId;
  String? qrCodeUrl;
  String? chargeId;
  bool isPaymentCompleted = false;
  bool isLoading = true; // Add loading state
  Timer? _timer;
  double amount = 50.00; // Default amount in THB

  @override
  void initState() {
    super.initState();
    // Start payment process immediately when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initiatePayment();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<String?> createPromptPaySource() async {
    const String secretKey = "skey_test_620l82392n1oq13zgd5";
    final Uri url = Uri.parse('https://api.omise.co/sources');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$secretKey:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': 'promptpay',
          'amount': (amount * 100).toInt(), // Convert to satang
          'currency': 'THB',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          sourceId = data['id'];
          qrCodeUrl = data['qr_code_uri'];
          isLoading = false;
        });
        return data['id'];
      } else {
        print("Error creating source: ${response.body}");
        setState(() => isLoading = false);
        return null;
      }
    } catch (e) {
      print("Exception occurred: $e");
      setState(() => isLoading = false);
      return null;
    }
  }

  Future<void> createCharge(String sourceId) async {
    const String secretKey = "skey_test_620l82392n1oq13zgd5";
    final Uri url = Uri.parse('https://api.omise.co/charges');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$secretKey:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(),
          'currency': 'THB',
          'source': sourceId,
          'return_uri': 'https://example.com/callback',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          chargeId = data['id'];
          qrCodeUrl = data['source']['scannable_code']['image']['download_uri'];
        });
        startCheckingPaymentStatus();
      } else {
        print("Error creating charge: ${response.body}");
      }
    } catch (e) {
      print("Exception occurred: $e");
    }
  }

  Future<void> checkPaymentStatus() async {
    if (chargeId == null) return;

    const String secretKey = "skey_test_620l82392n1oq13zgd5";
    final Uri url = Uri.parse('https://api.omise.co/charges/$chargeId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$secretKey:'))}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        setState(() {
          isPaymentCompleted = status == 'successful';
        });

        if (isPaymentCompleted) {
          _timer?.cancel();
          showPaymentSuccessDialog();
        }
      }
    } catch (e) {
      print("Error checking payment status: $e");
    }
  }

  void startCheckingPaymentStatus() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      checkPaymentStatus();
    });
  }

  Future<void> initiatePayment() async {
    setState(() => isLoading = true);
    final sourceId = await createPromptPaySource();
    if (sourceId != null) {
      await createCharge(sourceId);
    }
  }

  void showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Payment Successful',
          style: TextStyle(color: Colors.green),
        ),
        content: Text('Thank you for your payment of ฿$amount'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QR Payment"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.deepPurple, Colors.white],
                stops: [0.1, 0.1],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Text(
                            "Payment Amount",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "฿$amount",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  if (isLoading)
                    Container(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                    )
                  else if (qrCodeUrl != null && !isPaymentCompleted) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrCodeUrl!,
                              version: QrVersions.auto,
                              size: 250.0,
                              backgroundColor: Colors.white,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Scan QR Code to Pay",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Waiting for payment...",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        initiatePayment(); // Allow retry
                      },
                      child: Text(
                        "Regenerate QR Code",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                  if (isPaymentCompleted) ...[
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Payment Completed",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "฿$amount has been successfully paid",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "Done",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}