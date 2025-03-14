import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinSetupDialog extends StatefulWidget {
  const PinSetupDialog({super.key});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _errorMessage;

  void _validateAndSubmit() {
    if (_pinController.text.length != 6) {
      setState(() => _errorMessage = 'PIN must be 6 digits');
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      setState(() => _errorMessage = 'PINs do not match');
      return;
    }

    Navigator.of(context).pop(_pinController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup Transaction PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter 6-digit PIN',
              counterText: '',
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
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
          onPressed: _validateAndSubmit,
          child: const Text('Set PIN'),
        ),
      ],
    );
  }
} 