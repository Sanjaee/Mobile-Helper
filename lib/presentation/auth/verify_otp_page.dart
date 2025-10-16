import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/otp_input_field.dart';
import '../../core/utils/navigation.dart';
import '../../core/utils/storage_helper.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';

class VerifyOTPPage extends StatefulWidget {
  final String email;
  final bool isPasswordReset;

  const VerifyOTPPage({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  @override
  State<VerifyOTPPage> createState() => _VerifyOTPPageState();
}

class _VerifyOTPPageState extends State<VerifyOTPPage> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<OTPInputFieldState> _otpKey = GlobalKey<OTPInputFieldState>();
  bool _isLoading = false;
  bool _isResending = false;
  String _currentOTP = '';
  int _resendTimer = 0; // Start with 0 - button can be clicked immediately
  Timer? _timer;
  bool _hasResentOnce = false; // Track if user has clicked resend at least once

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _hasResentOnce = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP([String? otpCode]) async {
    final otp = otpCode ?? _currentOTP;

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isPasswordReset) {
        // For password reset, verify OTP first then navigate to change password
        final authService = AuthService();
        final request = OTPVerifyRequest(email: widget.email, otpCode: otp);

        await authService.verifyOTPResetPassword(request);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP verified successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to change password page with email and OTP
          NavigationHelper.pushTo(
            context,
            '/change-password?email=${widget.email}&otpCode=$otp',
          );
        }
      } else {
        // Regular OTP verification for registration
        final authService = AuthService();
        final request = OTPVerifyRequest(email: widget.email, otpCode: otp);

        final res = await authService.verifyOTP(request);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account verified successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to role-based home
          final type = (res.user.userType).toUpperCase();
          // Persist normalized type just in case
          await StorageHelper.saveUserType(type);
          final isService = type == 'SERVICE' || type == 'SERVICE_PROVIDER' || type == 'PROVIDER';
          final target = isService ? '/service-home' : '/client-home';
          NavigationHelper.goToAndClearStack(context, target);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        // Check if this is a password reset OTP error
        if (errorMessage.contains('OTP_FOR_PASSWORD_RESET') ||
            errorMessage.contains('password reset')) {
          // Redirect to password reset flow
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This OTP is for password reset. Redirecting...'),
              backgroundColor: AppColors.warning,
            ),
          );

          // Navigate to reset password page
          NavigationHelper.pushTo(context, '/reset-password');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
          // Clear OTP on error
          _otpKey.currentState?.clear();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      final authService = AuthService();
      final otpType = widget.isPasswordReset ? 'password_reset' : 'registration';
      await authService.resendOTP(widget.email, type: otpType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Clear current OTP input
        _otpKey.currentState?.clear();
        // Restart the timer
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => NavigationHelper.goBack(context),
                    ),
                  ],
                ),

                const Spacer(),

                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Icon(
                    widget.isPasswordReset
                        ? Icons.lock_reset
                        : Icons.sms_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Masukkan Kode Verifikasi',
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  widget.isPasswordReset
                      ? 'Kode verifikasi telah dikirimkan melalui email ke ${widget.email}'
                      : 'Kode verifikasi telah dikirimkan melalui email ke ${widget.email}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // OTP input field
                OTPInputField(
                  key: _otpKey,
                  length: 6,
                  onCompleted: _verifyOTP,
                  onChanged: (value) {
                    setState(() {
                      _currentOTP = value;
                    });
                  },
                ),

                const SizedBox(height: 48),

                // Verify button
                Container(
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        _currentOTP.length == 6 && !_isLoading
                            ? () => _verifyOTP(_currentOTP)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              'Verifikasi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 24),

                // Resend OTP with timer
                Center(
                  child: _resendTimer > 0
                      ? Text(
                          "Mohon menunggu ${_resendTimer} detik untuk mengirim ulang",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      : TextButton(
                          onPressed: _isResending ? null : _resendOTP,
                          child: _isResending
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              : Text(
                                  _hasResentOnce ? 'Kirim Ulang OTP' : 'Kirim Ulang OTP',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
