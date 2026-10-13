import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/l10n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';
import 'customer_login_screen.dart';
import 'verify_email_screen.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  final _pincode = TextEditingController();
  final _city = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedTerms = false;
  bool _busy = false;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _addressError;
  String? _pincodeError;
  String? _termsError;

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _password,
      _confirmPassword,
      _address,
      _landmark,
      _pincode,
      _city,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validateForm() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _addressError = null;
      _pincodeError = null;
      _termsError = null;
    });

    bool valid = true;

    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = 'Full name is required');
      valid = false;
    }

    final email = _email.text.trim().toLowerCase();
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      valid = false;
    }

    final phone = _phone.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.length != 10) {
      setState(() => _phoneError = 'Please enter a valid 10-digit mobile number');
      valid = false;
    }

    final pwd = _password.text;
    if (pwd.length < 8 || !RegExp(r'[a-zA-Z]').hasMatch(pwd) || !RegExp(r'[0-9]').hasMatch(pwd)) {
      setState(() => _passwordError = 'Password must be 8+ chars and contain both letters & numbers');
      valid = false;
    }

    if (_confirmPassword.text != pwd) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      valid = false;
    }

    if (_address.text.trim().isEmpty) {
      setState(() => _addressError = 'House / Flat & Street address is required');
      valid = false;
    }

    final pin = _pincode.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() => _pincodeError = 'Enter a valid 6-digit PIN code');
      valid = false;
    }

    if (!_agreedTerms) {
      setState(() => _termsError = 'Please agree to the Terms of Service & Privacy Policy');
      valid = false;
    }

    return valid;
  }

  Future<void> _handleRegister() async {
    if (!_validateForm()) return;

    setState(() => _busy = true);
    final state = context.read<AppState>();
    final cleanEmail = _email.text.trim().toLowerCase();
    final cleanPhone = _phone.text.trim().replaceAll(RegExp(r'\D'), '');

    try {
      final res = await Api.signUpWithPassword(
        email: cleanEmail,
        password: _password.text,
        data: {
          'name': _name.text.trim(),
          'role': 'customer',
          'phone': cleanPhone,
        },
      );

      if (res.user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      // If user session is active immediately (Email Confirmation is OFF in Supabase)
      if (res.session != null) {
        await Api.createCustomerProfile(
          name: _name.text.trim(),
          email: cleanEmail,
          contactPhone: cleanPhone,
          lang: state.lang,
          pincode: _pincode.text.trim(),
          addressLine: _address.text.trim(),
          landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        );

        await state.setSelectedRole('customer');
        await state.refresh();

        if (mounted) {
          Navigator.popUntil(context, (r) => r.isFirst);
        }
      } else {
        // Email confirmation is required
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(
                email: cleanEmail,
                role: 'customer',
              ),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') || e.code == 'user_already_exists') {
        setState(() => _emailError = 'This email is already registered. Please sign in.');
      } else if (e.message.toLowerCase().contains('weak') || e.code == 'weak_password') {
        setState(() => _passwordError = 'Password is too weak. Please use letters, numbers & symbols.');
      } else {
        if (mounted) toast(context, e.message, isError: true);
      }
    } catch (e) {
      if (mounted) toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MilkColors.milkWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: MilkColors.charcoal),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.read<AppState>().clearRole();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<AppState>().clearRole(),
            child: Text(
              t(context, 'change_role'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: MilkColors.dairyBlue),
            ),
          ),
          const LangMenu(),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Header
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: MilkColors.dairyBlueLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: MilkColors.dairyBlue.withValues(alpha: 0.2), width: 2),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, size: 42, color: MilkColors.dairyBlue),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Customer Registration',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: MilkColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create your account to get fresh farm milk delivered daily',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: MilkColors.charcoalLight, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Form Card: Personal & Account Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MilkColors.border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Account Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: t(context, 'name'),
                      hintText: 'Ramesh Patil',
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: t(context, 'email_address'),
                      hintText: 'ramesh@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Contact Mobile (For Delivery Calls)',
                      hintText: '9876543210',
                      prefixText: '+91 ',
                      counterText: '',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      errorText: _phoneError,
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Create Password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  PasswordStrengthMeter(password: _password.text),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _confirmPassword,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_clock_outlined),
                      errorText: _confirmPasswordError,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Form Card: Delivery Address
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MilkColors.border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _address,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'House / Flat No., Society, Street',
                      hintText: 'Flat 402, Shiv Shrushti Apts, Main Road',
                      prefixIcon: const Icon(Icons.home_outlined),
                      errorText: _addressError,
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _landmark,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: t(context, 'landmark'),
                      hintText: 'Opposite Maruti Temple',
                      prefixIcon: const Icon(Icons.near_me_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pincode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            labelText: t(context, 'pincode'),
                            hintText: '411001',
                            counterText: '',
                            prefixIcon: const Icon(Icons.pin_drop_outlined),
                            errorText: _pincodeError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _city,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(
                            labelText: 'City / Village',
                            hintText: 'Pune',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Terms Checkbox
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _termsError != null ? const Color(0xFFFFEBEE) : MilkColors.creamLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _termsError != null ? MilkColors.error : MilkColors.butterYellow.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreedTerms,
                        activeColor: MilkColors.dairyBlue,
                        onChanged: (v) => setState(() {
                          _agreedTerms = v ?? false;
                          _termsError = null;
                        }),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'I agree to the Terms of Service and Privacy Policy for daily farm milk delivery.',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MilkColors.charcoal),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_termsError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(_termsError!, style: const TextStyle(color: MilkColors.error, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              label: 'Create Customer Account',
              icon: Icons.check_circle_rounded,
              onPressed: _handleRegister,
              busy: _busy,
              color: MilkColors.dairyBlue,
            ),
            const SizedBox(height: 16),

            // Link to Login
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: MilkColors.charcoalLight, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
                        );
                      }
                    },
                    child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w800, color: MilkColors.dairyBlue)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
