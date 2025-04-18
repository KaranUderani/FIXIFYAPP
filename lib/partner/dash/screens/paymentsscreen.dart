import 'package:flutter/material.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment history',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildPaymentHistoryItem(
                'RAJGAD GALAXY - 5th Floor',
                'Light Replace',
                'Completed',
                '₹220',
              ),
              _buildPaymentHistoryItem(
                'RAJGAD GALAXY - 4th Floor',
                'Bulb Fitting',
                'Completed',
                '₹220',
              ),
              _buildPaymentHistoryItem(
                'RAJGAD GALAXY - 4th Floor',
                'Bulb Fitting',
                'Completed',
                '₹220',
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Total Payment received :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹XXX',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tap To Withdraw',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Withdraw'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryItem(
      String location,
      String description,
      String status,
      String amount,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFFFFDE7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('DESCRIPTION : $description'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WithdrawMoneyScreen extends StatelessWidget {
  const WithdrawMoneyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDE7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/imagefixify.png', height: 30),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            Container(
            color: const Color(0xFFFFFDE7),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text(
              'Withdraw Money',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('₹XXX Available'),
            SizedBox(height: 32),
            Text(
              '₹0',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
          Container(
          padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 48,
      ),
    ),
    const SizedBox(height: 16),
    const Text(
    'successfully withdrawn amt.xxx',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    ),
    ),
    const SizedBox(height: 24),
    const Text(
    'Thanks for Withdrawing Your Money Will Shortly get reflected in your bank account',
    textAlign: TextAlign.center,
    ),
    const SizedBox(height: 16),
    ListTile(
    leading: Image.asset('assets/bank_icon.png', height: 32),
    title: const Text('HDFC Bank ....4499'),
    ),

    const SizedBox(height: 24),

    // Number pad
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
    _buildNumberButton('1'),
    _buildNumberButton('2', 'ABC'),
    _buildNumberButton('3', 'DEF'),
    ],
    ),
    const SizedBox(height: 16),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
    _buildNumberButton('4', 'GHI'),
    _buildNumberButton('5', 'JKL'),
    _buildNumberButton('6', 'MNO'),
    ],
    ),
    const SizedBox(height: 16),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
    _buildNumberButton('7', 'PQRS'),
    _buildNumberButton('8', 'TUV'),
    _buildNumberButton('9', 'WXYZ'),
    ],
    ),
    const SizedBox(height: 16),

      Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNumberButton('*'),
        _buildNumberButton('0'),
        _buildNumberButton('⌫'),
      ],
    ),
      const SizedBox(height: 24),

      ElevatedButton(
        onPressed: () {
          // Handle withdrawal confirmation
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Withdraw',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
    ),
    ),
    ],
    ),
    ),
    );
  }

  Widget _buildNumberButton(String number, [String? letters]) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (letters != null)
            Text(
              letters,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }
}