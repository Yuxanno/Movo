import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_shell.dart';

class PinScreen extends StatefulWidget {
  final bool isConfirming; // If true, it means we are in the flow of setting a new pin and this is confirmation
  final String? firstPin;
  final VoidCallback? onSuccess; // If set, just verify and call this
  final String? title;

  const PinScreen({
    Key? key,
    this.isConfirming = false,
    this.firstPin,
    this.onSuccess,
    this.title,
  }) : super(key: key);

  @override State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = "";
  String? _cachedFirstPin;
  bool _isConfirmStage = false;
  bool _error = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _cachedFirstPin = widget.firstPin;
    _isConfirmStage = widget.isConfirming;
  }

  void _onKeyPress(String key) async {
    if (_pin.length >= 4) return;
    setState(() { _pin += key; _error = false; _errorMessage = ""; });

    if (_pin.length == 4) {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('pin_code');

      // 1. Verify Mode (onSuccess provided)
      if (widget.onSuccess != null) {
        if (_pin == savedPin) {
          if (mounted) {
            Navigator.pop(context);
            widget.onSuccess!();
          }
        } else {
          _handleError("Неверный PIN-код");
        }
        return;
      }

      // 2. Setting New PIN (Confirmation stage)
      if (_isConfirmStage) {
        if (_pin == _cachedFirstPin) {
          await prefs.setString('pin_code', _pin);
          if (mounted) {
            // If we came from Settings, we should just pop back
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
            }
          }
        } else {
          _handleError("PIN-коды не совпадают");
        }
        return;
      }

      // 3. Normal Login / Pre-setting Initial Entry
      if (savedPin != null) {
        if (_pin == savedPin) {
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
        } else {
          _handleError("Неверный PIN-код");
        }
      } else {
        // Start Creation flow: Move to confirmation stage on the same screen
        setState(() {
          _cachedFirstPin = _pin;
          _pin = "";
          _isConfirmStage = true;
        });
      }
    }
  }

  void _handleError(String msg) {
    setState(() {
      _pin = "";
      _error = true;
      _errorMessage = msg;
    });
  }

  void _onBack() {
    if (_pin.isNotEmpty) setState(() { _pin = _pin.substring(0, _pin.length - 1); });
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.title ?? "Введите PIN-код";
    if (_isConfirmStage) title = "Повторите PIN-код";
    if (_error) title = _errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: Column(
          children: [
            // Close Button (Now always available for settings/verify modes)
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF6b7280)),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _error ? const Color(0xFFef4444) : const Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                width: 16, height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _error ? const Color(0xFFef4444) : const Color(0xFF16a34a),
                    width: 2,
                  ),
                  color: _pin.length > index
                      ? (_error ? const Color(0xFFef4444) : const Color(0xFF16a34a))
                      : Colors.transparent,
                ),
              )),
            ),
            const Spacer(),
            _buildNumpad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) => _NumpadButton(text: key, onTap: () => _onKeyPress(key))).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72),
              _NumpadButton(text: '0', onTap: () => _onKeyPress('0')),
              _NumpadButton(icon: Icons.backspace_outlined, onTap: _onBack, isAction: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isAction;

  const _NumpadButton({this.text, this.icon, required this.onTap, this.isAction = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: isAction ? Colors.transparent : Colors.white,
          shape: BoxShape.circle,
          boxShadow: isAction ? null : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
        ),
        child: Center(
          child: text != null
            ? Text(text!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1f2937)))
            : Icon(icon, color: const Color(0xFF6b7280), size: 24),
        ),
      ),
    );
  }
}
