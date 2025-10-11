import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/navigation.dart';
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
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isPasswordReset) {
        // For password reset, verify OTP first then navigate to change password
        final authService = AuthService();
        final request = OTPVerifyRequest(
          email: widget.email,
          otpCode: _otpController.text.trim(),
        );

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
            '/change-password?email=${widget.email}&otpCode=${_otpController.text.trim()}',
          );
        }
      } else {
        // Regular OTP verification for registration
        final authService = AuthService();
        final request = OTPVerifyRequest(
          email: widget.email,
          otpCode: _otpController.text.trim(),
        );

        await authService.verifyOTP(request);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account verified successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to home page
          NavigationHelper.goToAndClearStack(context, '/home');
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
      await authService.resendOTP(widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => NavigationHelper.goBack(context),
        ),
        title: Text('Verify OTP', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    color: AppColors.textOnPrimary,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Check Your Email',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  widget.isPasswordReset
                      ? 'We\'ve sent a password reset code to ${widget.email}'
                      : 'We\'ve sent a verification code to ${widget.email}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // OTP field
                CustomOTPField(
                  controller: _otpController,
                  validator: Validators.otp,
                ),

                const SizedBox(height: 24),

                // Verify button
                CustomButton(
                  text: 'Verify OTP',
                  onPressed: _verifyOTP,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: AppTextStyles.bodyMedium,
                    ),
                    CustomTextButton(
                      text: 'Resend',
                      onPressed: _isResending ? null : _resendOTP,
                      isLoading: _isResending,
                    ),
                  ],
                ),

                const Spacer(),

                // Back to login
                if (!widget.isPasswordReset)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Wrong email? ", style: AppTextStyles.bodyMedium),
                      CustomTextButton(
                        text: 'Go Back',
                        onPressed: () {
                          NavigationHelper.goBack(context);
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
