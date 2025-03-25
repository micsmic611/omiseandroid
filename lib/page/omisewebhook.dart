import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ฟังก์ชันสำหรับส่งข้อมูลการชำระเงินไปยัง backend
  Future<void> createCharge() async {
    // ข้อมูลที่คุณต้องการส่งไปที่ backend (API)
    final Map<String, dynamic> paymentData = {
      'amount': 1000,  // จำนวนเงินที่ชำระ
      'currency': 'thb', // สกุลเงิน
      'description': 'Payment for product X',
      // สามารถเพิ่มข้อมูลเพิ่มเติมได้
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.37.59:3000/charge'),  // URL ของ backend (อาจจะเปลี่ยนไปตามที่ตั้งของเซิร์ฟเวอร์)
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(paymentData),
      );

      if (response.statusCode == 200) {
        // ถ้าการส่ง request สำเร็จ
        print('Payment success: ${response.body}');
        // สามารถแสดงข้อความ หรือไปยังหน้าถัดไป
      } else {
        print('Payment failed: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: createCharge,  // เรียกฟังก์ชันเมื่อกดปุ่ม
          child: Text('Pay Now'),
        ),
      ),
    );
  }
}
