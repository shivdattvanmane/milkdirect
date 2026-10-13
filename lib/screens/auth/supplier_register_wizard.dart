import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/l10n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';
import 'supplier_login_screen.dart';
import 'verification_pending_screen.dart';
import 'verify_email_screen.dart';

class SupplierRegisterWizard extends StatefulWidget {
  final String? email;
  const SupplierRegisterWizard({super.key, this.email});

  @override
  State<SupplierRegisterWizard> createState() => _SupplierRegisterWizardState();
}

class _SupplierRegisterWizardState extends State<SupplierRegisterWizard> {
  int _currentStep = 0;
  bool _busy = false;

  // Step 1
  String _supplierType = 'farmer'; // 'farmer' | 'milkman'
  final _name = TextEditingController();
  final _shopName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 2
  final _village = TextEditingController();
  final _pincode = TextEditingController();
  final _servicePincodes = TextEditingController();

  // Step 3
  final _upi = TextEditingController();
  final _deliveryCharge = TextEditingController(text: '0');
  final _minOrder = TextEditingController(text: '0.5');
  final List<String> _selectedSlots = ['morning_5_8', 'morning_8_10', 'evening_5_8'];

  // Step 4
  final _fssai = TextEditingController();
  bool _agreedPurity = true;
  bool _agreedTerms = false;

  // Error States
  String? _step1Error;
  String? _step2Error;
  String? _step3Error;
  String? _step4Error;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _email.text = widget.email!;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _shopName,
      _email,
      _phone,
      _password,
      _confirmPassword,
      _village,
      _pincode,
      _servicePincodes,
      _upi,
      _deliveryCharge,
      _minOrder,
      _fssai,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validateCurrentStep() {
    setState(() {
      _step1Error = null;
      _step2Error = null;
      _step3Error = null;
      _step4Error = null;
    });

    if (_currentStep == 0) {
      if (_name.text.trim().isEmpty) {
        setState(() => _step1Error = 'Please enter your full name');
        return false;
      }
      if (_shopName.text.trim().isEmpty) {
        setState(() => _step1Error = 'Please enter your Dairy Farm or Business name');
        return false;
      }
      final em = _email.text.trim().toLowerCase();
      if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(em)) {
        setState(() => _step1Error = 'Please enter a valid email address');
        return false;
      }
      final ph = _phone.text.trim().replaceAll(RegExp(r'\D'), '');
      if (ph.length != 10) {
        setState(() => _step1Error = 'Please enter a valid 10-digit contact mobile number');
        return false;
      }
      final pwd = _password.text;
      if (pwd.length < 8 || !RegExp(r'[a-zA-Z]').hasMatch(pwd) || !RegExp(r'[0-9]').hasMatch(pwd)) {
        setState(() => _step1Error = 'Password must be 8+ chars with letters and numbers');
        return false;
      }
      if (_confirmPassword.text != pwd) {
        setState(() => _step1Error = 'Passwords do not match');
        return false;
      }
      return true;
    }

    if (_currentStep == 1) {
      if (_village.text.trim().isEmpty) {
        setState(() => _step2Error = 'Please enter your village or area');
        return false;
      }
      if (!RegExp(r'^\d{6}$').hasMatch(_pincode.text.trim())) {
        setState(() => _step2Error = 'Please enter a valid 6-digit PIN code');
        return false;
      }
      if (_servicePincodes.text.trim().isEmpty) {
        setState(() => _step2Error = 'Please enter at least one delivery service PIN code');
        return false;
      }
      return true;
    }

    if (_currentStep == 2) {
      if (_selectedSlots.isEmpty) {
        setState(() => _step3Error = 'Please select at least one delivery time slot');
        return false;
      }
      return true;
    }

    if (_currentStep == 3) {
      if (!_agreedPurity) {
        setState(() => _step4Error = 'Please accept the quality & purity declaration');
        return false;
      }
      if (!_agreedTerms) {
        setState(() => _step4Error = 'Please accept the Terms of Service & Privacy Policy');
        return false;
      }
      return true;
    }

    return true;
  }

  void _next() {
    if (_validateCurrentStep()) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
      } else {
        _submit();
      }
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final state = context.read<AppState>();
    final cleanEmail = _email.text.trim().toLowerCase();
    final cleanPhone = _phone.text.trim().replaceAll(RegExp(r'\D'), '');

    try {
      final pinList = _servicePincodes.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final res = await Api.signUpWithPassword(
        email: cleanEmail,
        password: _password.text,
        data: {
          'name': _name.text.trim(),
          'role': 'supplier',
          'phone': cleanPhone,
        },
      );

      if (res.user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      if (res.session != null) {
        // Session active immediately
        await Api.createSupplierProfile(
          name: _name.text.trim(),
          email: cleanEmail,
          contactPhone: cleanPhone,
          lang: state.lang,
          type: _supplierType,
          shopName: _shopName.text.trim(),
          village: _village.text.trim(),
          pincode: _pincode.text.trim(),
          servicePincodes: pinList,
          upi: _upi.text.trim().isEmpty ? null : _upi.text.trim(),
          deliverySlots: _selectedSlots,
          deliveryCharge: double.tryParse(_deliveryCharge.text.trim()) ?? 0,
          minOrderL: double.tryParse(_minOrder.text.trim()) ?? 0.5,
          fssaiNo: _fssai.text.trim().isEmpty ? null : _fssai.text.trim(),
        );

        await state.setSelectedRole('supplier');
        await state.refresh();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VerificationPendingScreen()),
          );
        }
      } else {
        // Email confirmation is required
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(
                email: cleanEmail,
                role: 'supplier',
              ),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') || e.code == 'user_already_exists') {
        setState(() => _step1Error = 'This email is already registered. Please sign in.');
      } else {
        if (mounted) toast(context, e.message, isError: true);
      }
    } catch (e) {
      if (mounted) toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildStepIndicator() {
    final steps = ['Account', 'Location', 'Delivery', 'Purity'];
    return Row(
      children: List.generate(4, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 3, color: i == 0 ? Colors.transparent : (isDone ? MilkColors.primaryGreen : MilkColors.border))),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDone || isActive ? MilkColors.primaryGreen : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone || isActive ? MilkColors.primaryGreen : MilkColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isActive ? Colors.white : MilkColors.charcoalMuted,
                              ),
                            ),
                    ),
                  ),
                  Expanded(child: Container(height: 3, color: i == 3 ? Colors.transparent : (isDone ? MilkColors.primaryGreen : MilkColors.border))),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive ? MilkColors.primaryGreenDark : MilkColors.charcoalLight,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MilkColors.milkWhite,
      appBar: AppBar(
        title: Text(t(context, 'supplier_wizard_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: MilkColors.charcoal),
          onPressed: () {
            if (_currentStep > 0) {
              _prev();
            } else if (Navigator.canPop(context)) {
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: MilkColors.primaryGreen),
            ),
          ),
          const LangMenu(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: _buildStepIndicator(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // STEP 1: Type & Account
                  if (_currentStep == 0) ...[
                    const Text('Step 1: Supplier Type & Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Select your model and setup your login credentials', style: TextStyle(fontSize: 14, color: MilkColors.charcoalLight)),
                    const SizedBox(height: 18),

                    if (_step1Error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                        child: Text(_step1Error!, style: const TextStyle(color: MilkColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),

                    // Type Cards
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _supplierType = 'farmer'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _supplierType == 'farmer' ? MilkColors.creamLight : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _supplierType == 'farmer' ? MilkColors.primaryGreen : MilkColors.border,
                                  width: _supplierType == 'farmer' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.grass_rounded, color: MilkColors.primaryGreen, size: 32),
                                  const SizedBox(height: 8),
                                  const Text('Dairy Farmer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  const Text('Own Cattle', style: TextStyle(fontSize: 12, color: MilkColors.charcoalLight)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _supplierType = 'milkman'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _supplierType == 'milkman' ? MilkColors.creamLight : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _supplierType == 'milkman' ? MilkColors.primaryGreen : MilkColors.border,
                                  width: _supplierType == 'milkman' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.two_wheeler_rounded, color: MilkColors.dairyBlue, size: 32),
                                  const SizedBox(height: 8),
                                  const Text('Milkman', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  const Text('Village Sourced', style: TextStyle(fontSize: 12, color: MilkColors.charcoalLight)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    TextField(
                      controller: _name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: t(context, 'name'),
                        hintText: 'Ramesh Patil',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _shopName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: t(context, 'shop_farm_name'),
                        hintText: 'Shree Krishna Dairy Farm',
                        prefixIcon: const Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: t(context, 'email_address'),
                        hintText: 'farm@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        labelText: 'Contact Mobile (Customer Orders)',
                        hintText: '9876543210',
                        prefixText: '+91 ',
                        counterText: '',
                        prefixIcon: Icon(Icons.phone_outlined),
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
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                  ],

                  // STEP 2: Location & Delivery PINs
                  if (_currentStep == 1) ...[
                    const Text('Step 2: Farm Location & Service Areas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Specify where your farm is located and PIN codes you deliver to', style: TextStyle(fontSize: 14, color: MilkColors.charcoalLight)),
                    const SizedBox(height: 18),

                    if (_step2Error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                        child: Text(_step2Error!, style: const TextStyle(color: MilkColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),

                    TextField(
                      controller: _village,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: t(context, 'village'),
                        hintText: 'Khed Shivapur, Haveli',
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _pincode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: 'Farm PIN Code',
                        hintText: '412205',
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_drop_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _servicePincodes,
                      maxLines: 2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: t(context, 'service_pincodes'),
                        hintText: t(context, 'service_pincodes_hint'),
                        helperText: 'Separate multiple PIN codes with commas',
                        prefixIcon: const Icon(Icons.map_outlined),
                      ),
                    ),
                  ],

                  // STEP 3: Payout & Delivery Slots
                  if (_currentStep == 2) ...[
                    const Text('Step 3: Payout & Delivery Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Configure customer payment UPI and delivery slots', style: TextStyle(fontSize: 14, color: MilkColors.charcoalLight)),
                    const SizedBox(height: 18),

                    if (_step3Error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                        child: Text(_step3Error!, style: const TextStyle(color: MilkColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),

                    TextField(
                      controller: _upi,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: t(context, 'upi'),
                        hintText: 'ramesh@okhdfcbank',
                        prefixIcon: const Icon(Icons.payment_outlined),
                        helperText: 'Customers will pay directly to this UPI ID',
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text('Active Delivery Slots', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Morning (5:00 - 8:00 AM)'),
                          selected: _selectedSlots.contains('morning_5_8'),
                          selectedColor: MilkColors.primaryGreenLight,
                          checkmarkColor: MilkColors.primaryGreen,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _selectedSlots.add('morning_5_8');
                            } else {
                              _selectedSlots.remove('morning_5_8');
                            }
                          }),
                        ),
                        FilterChip(
                          label: const Text('Morning (8:00 - 10:00 AM)'),
                          selected: _selectedSlots.contains('morning_8_10'),
                          selectedColor: MilkColors.primaryGreenLight,
                          checkmarkColor: MilkColors.primaryGreen,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _selectedSlots.add('morning_8_10');
                            } else {
                              _selectedSlots.remove('morning_8_10');
                            }
                          }),
                        ),
                        FilterChip(
                          label: const Text('Evening (5:00 - 8:00 PM)'),
                          selected: _selectedSlots.contains('evening_5_8'),
                          selectedColor: MilkColors.primaryGreenLight,
                          checkmarkColor: MilkColors.primaryGreen,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _selectedSlots.add('evening_5_8');
                            } else {
                              _selectedSlots.remove('evening_5_8');
                            }
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _deliveryCharge,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(
                              labelText: 'Delivery Fee (₹)',
                              prefixText: '₹ ',
                              hintText: '0',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _minOrder,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(
                              labelText: 'Min Order (L)',
                              suffixText: 'L',
                              hintText: '0.5',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // STEP 4: Documents & Purity
                  if (_currentStep == 3) ...[
                    const Text('Step 4: Quality & Verification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('FSSAI certifications and farm quality declaration', style: TextStyle(fontSize: 14, color: MilkColors.charcoalLight)),
                    const SizedBox(height: 18),

                    if (_step4Error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                        child: Text(_step4Error!, style: const TextStyle(color: MilkColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),

                    TextField(
                      controller: _fssai,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: 'FSSAI License / Registration No. (Optional)',
                        hintText: '100XXXXXXXXXXX',
                        helperText: t(context, 'fssai_doc_hint'),
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MilkColors.cream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MilkColors.butterYellow),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedPurity,
                            activeColor: MilkColors.primaryGreen,
                            onChanged: (v) => setState(() => _agreedPurity = v ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'I declare that the milk supplied by my farm/business is 100% pure, unadulterated, and hygienically handled according to safety standards.',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MilkColors.charcoal, height: 1.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MilkColors.creamLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MilkColors.butterYellow.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedTerms,
                            activeColor: MilkColors.primaryGreen,
                            onChanged: (v) => setState(() => _agreedTerms = v ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'I agree to the MilkDirect Terms of Service, Supplier Guidelines, and Privacy Policy.',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MilkColors.charcoal, height: 1.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Navigation buttons
                  Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _prev,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: const BorderSide(color: MilkColors.border, width: 1.5),
                            ),
                            child: Text(t(context, 'back'), style: const TextStyle(fontWeight: FontWeight.w800, color: MilkColors.charcoal)),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: AppButton(
                          label: _currentStep == 3 ? 'Register as Supplier' : t(context, 'continue'),
                          onPressed: _next,
                          busy: _busy,
                          color: MilkColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already registered as Supplier? ', style: TextStyle(color: MilkColors.charcoalLight, fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const SupplierLoginScreen()),
                            );
                          },
                          child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w800, color: MilkColors.primaryGreen)),
                        ),
                      ],
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
}
