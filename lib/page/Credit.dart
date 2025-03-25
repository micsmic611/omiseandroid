import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:omisewithandroid/component/showtitle.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:omise_flutter/omise_flutter.dart';
import 'package:http/http.dart' as http;

class Credit extends StatefulWidget {
  const Credit({super.key});

  @override
  State<Credit> createState() => _CreditState();
}

class _CreditState extends State<Credit> {
  // Create variable for store data.
  String? name,
      surname,
      idCard,
      expireDateStr,
      expireDateYear,
      expireDateMonth,
      cvc,
      amount;

  bool isLoading = false;

  // Declare MaskTextInputFormatter for format text.
  final idCardMask = MaskTextInputFormatter(mask: '#### - #### - #### - ####');
  final expireDateMask = MaskTextInputFormatter(mask: '## / ####');
  final cvcMask = MaskTextInputFormatter(mask: '###');
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Credit Card Payment"),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            behavior: HitTestBehavior.opaque,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTitle("Name - Surname"),
                    buildNameSurname(),
                    buildTitle("Card Number"),
                    formIDcard(),
                    buildExpireDateAndCVC(),
                    buildTitle("Amount"),
                    formAmount(),
                    const SizedBox(height: 80), // Space for bottom button
                  ],
                ),
              ),
            ),
          ),
          // Loading Indicator
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          // Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: buttonAddMoney(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buttonAddMoney() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : () {
          if (formKey.currentState!.validate()) {
            processPayment();
          }
        },
        child: Text(isLoading ? "Processing..." : "Process Payment"),
      ),
    );
  }

  Future<void> processPayment() async {
    try {
      setState(() => isLoading = true);

      // 1. Create token
      final token = await createOmiseToken();
      print('Token created: $token');

      // 2. Create charge
      final chargeResult = await createOmiseCharge(token!);
      print('Charge result: $chargeResult');

      // 3. Handle result
      handlePaymentResult(chargeResult);

    } catch (e) {
      handleError(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String?> createOmiseToken() async {
    final publicKey = 'pkey_test_620l822nzq0hx88f8qg';
    final omise = OmiseFlutter(publicKey);

    final tokenResult = await omise.token
        .create('$name $surname', idCard!, expireDateMonth!, expireDateYear!, cvc!);

    return tokenResult.id;
  }

  Future<Map<String, dynamic>> createOmiseCharge(String token) async {
    final secretKey = "skey_test_620l82392n1oq13zgd5";
    final url = "https://api.omise.co/charges";
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$secretKey:'))}';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': basicAuth,
        'Cache-Control': 'no-cache',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': '${amount}00', // Convert to smallest currency unit
        'currency': 'thb',
        'card': token,
      },
    );

    return json.decode(response.body);
  }

  void handlePaymentResult(Map<String, dynamic> result) {
    if (result['status'] == 'successful') {
      showSuccessDialog();
    } else {
      showErrorDialog('Payment failed: ${result['failure_message'] ?? 'Unknown error'}');
    }
  }

  void handleError(dynamic error) {
    String message = 'An error occurred';

    if (error.toString().contains('invalid_card')) {
      message = 'Invalid card number';
    } else if (error.toString().contains('network')) {
      message = 'Network error. Please try again.';
    }

    showErrorDialog(message);
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: const Text('Your payment has been processed successfully.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
          ),
        ],
      ),
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget formAmount() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextFormField(
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return "Please enter amount";
        }
        final numValue = double.tryParse(value!);
        if (numValue == null || numValue <= 0) {
          return "Please enter valid amount";
        }
        amount = value.trim();
        return null;
      },
      decoration: const InputDecoration(
        labelText: "Amount",
        hintText: "0.00",// กรอกเงินขั้นต่ำ20บาท
        suffixText: "THB",
        border: OutlineInputBorder(),
      ),
    ),
  );

  Container buildExpireDateAndCVC() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTitle("Expire Date"),
                formExpireDate(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTitle("CVC"),
                formCVC(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget formCVC() => TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [cvcMask],
    validator: (value) {
      if (value?.isEmpty ?? true) {
        return "Please enter CVC";
      }
      cvc = cvcMask.getUnmaskedText();
      if (cvc!.length != 3) {
        return "CVC must be 3 digits";
      }
      return null;
    },
    onChanged: (value) => cvc = cvcMask.getUnmaskedText(),
    decoration: const InputDecoration(
      hintText: "xxx",
      border: OutlineInputBorder(),
    ),
  );

  Widget formExpireDate() => TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [expireDateMask],
    validator: (value) {
      if (value?.isEmpty ?? true) {
        return "Please enter expiry date";
      }

      expireDateStr = expireDateMask.getUnmaskedText();
      if (expireDateStr!.length != 6) {
        return "Invalid expiry date format";
      }

      expireDateMonth = expireDateStr!.substring(0, 2);
      expireDateYear = expireDateStr!.substring(2, 6);

      final month = int.parse(expireDateMonth!);
      final year = int.parse(expireDateYear!);
      final now = DateTime.now();

      if (month > 12 || month < 1) {
        return "Invalid month";
      }

      if (year < now.year || (year == now.year && month < now.month)) {
        return "Card has expired";
      }

      expireDateMonth = month.toString();
      return null;
    },
    onChanged: (value) => expireDateStr = expireDateMask.getUnmaskedText(),
    decoration: const InputDecoration(
      hintText: "MM / YYYY",
      border: OutlineInputBorder(),
    ),
  );

  Widget formIDcard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextFormField(
      inputFormatters: [idCardMask],
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return "Please enter card number";
        }
        idCard = idCardMask.getUnmaskedText();
        if (idCard!.length != 16) {
          return "Card number must be 16 digits";
        }
        return null;
      },
      onChanged: (value) => idCard = idCardMask.getUnmaskedText(),
      decoration: const InputDecoration(
        hintText: "xxxx-xxxx-xxxx-xxxx",
        border: OutlineInputBorder(),
      ),
    ),
  );

  Container buildNameSurname() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: formName(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: formSurName(),
          ),
        ],
      ),
    );
  }

  Widget formName() => TextFormField(
    validator: (value) {
      if (value?.isEmpty ?? true) {
        return "Please enter name";
      }
      name = value!.trim();
      return null;
    },
    decoration: const InputDecoration(
      labelText: "Name",
      hintText: "Enter your name",
      border: OutlineInputBorder(),
    ),
  );

  Widget formSurName() => TextFormField(
    validator: (value) {
      if (value?.isEmpty ?? true) {
        return "Please enter surname";
      }
      surname = value!.trim();
      return null;
    },
    decoration: const InputDecoration(
      labelText: "Surname",
      hintText: "Enter your surname",
      border: OutlineInputBorder(),
    ),
  );

  Widget buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ShowTitle(
        title: title,
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}