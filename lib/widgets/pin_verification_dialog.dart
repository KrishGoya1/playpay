import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinVerificationDialog extends StatefulWidget {
  const PinVerificationDialog({super.key});

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  final _pinController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Enter your 6-digit PIN',
              counterText: '',
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_pinController.text.length != 6) {
              setState(() => _errorMessage = 'Please enter a 6-digit PIN');
              return;
            }
            Navigator.of(context).pop(_pinController.text);
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }
} 