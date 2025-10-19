import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

// Custom formatter that allows paste but limits manual input to 1 character
class _OTPTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow paste (when new value has multiple characters)
    if (newValue.text.length > 1) {
      return newValue;
    }
    
    // For manual input, limit to 1 character
    if (newValue.text.length <= 1) {
      return newValue;
    }
    
    return oldValue;
  }
}

class OTPInputField extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool autoFocus;
  final bool enabled;

  const OTPInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.autoFocus = true,
    this.enabled = true,
  });

  @override
  State<OTPInputField> createState() => OTPInputFieldState();
}

class OTPInputFieldState extends State<OTPInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _otp;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _otp = List.filled(widget.length, '');

    // Add listeners to focus nodes
    for (int i = 0; i < widget.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _controllers[i].text.isEmpty) {
          _controllers[i].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[i].text.length),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste - fill from beginning regardless of which field was pasted into
      _handlePaste(value, index);
      return;
    }

    // Handle backspace - when value becomes empty
    if (value.isEmpty && _otp[index].isNotEmpty) {
      setState(() {
        _otp[index] = '';
      });
      widget.onChanged?.call(_otp.join());

      // Move to previous field if available
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    setState(() {
      _otp[index] = value;
    });

    widget.onChanged?.call(_otp.join());

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_otp.every((digit) => digit.isNotEmpty)) {
          widget.onCompleted(_otp.join());
        }
      }
    }
  }

  void _handlePaste(String pastedText, int pastedIndex) {
    final cleanText = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    final digits = cleanText.split('').toList();

    setState(() {
      // Fill all fields with pasted digits starting from first field
      for (int i = 0; i < widget.length; i++) {
        if (i < digits.length) {
          _controllers[i].text = digits[i];
          _otp[i] = digits[i];
        } else {
          _controllers[i].text = '';
          _otp[i] = '';
        }
      }
    });

    widget.onChanged?.call(_otp.join());

    // If all fields filled, trigger completion
    if (digits.length >= widget.length) {
      _focusNodes[widget.length - 1].unfocus();
      widget.onCompleted(_otp.join());
    } else {
      // Focus on next empty field
      final nextEmptyIndex =
          digits.length < widget.length ? digits.length : widget.length - 1;
      _focusNodes[nextEmptyIndex].requestFocus();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) => _buildOTPBox(index)),
    );
  }

  Widget _buildOTPBox(int index) {
    final isFocused = _focusNodes[index].hasFocus;
    final hasValue = _otp[index].isNotEmpty;

    return SizedBox(
      width: 40,
      height: 48,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _OTPTextInputFormatter(),
        ],
        enabled: widget.enabled,
        autofocus: widget.autoFocus && index == 0,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color:
                  isFocused || hasValue ? AppColors.primary : AppColors.border,
              width: isFocused ? 2 : 1,
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: hasValue ? AppColors.primary : AppColors.border,
              width: hasValue ? 2 : 1,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
          counterText: '',
        ),
        onChanged: (value) => _onChanged(index, value),
        onTap: () {
          _controllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[index].text.length),
          );
        },
        onEditingComplete: () {
          if (index < widget.length - 1) {
            _focusNodes[index + 1].requestFocus();
          } else {
            _focusNodes[index].unfocus();
          }
        },
      ),
    );
  }

  // Public method to clear all fields
  void clear() {
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].clear();
      _otp[i] = '';
    }
    _focusNodes[0].requestFocus();
  }

  // Public method to get current OTP
  String getOTP() => _otp.join();
}
