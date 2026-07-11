import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/ripple_repository.dart';
import '../../../core/repositories/repository_providers.dart';

class PlansPage extends ConsumerStatefulWidget {
  const PlansPage({super.key});

  @override
  ConsumerState<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends ConsumerState<PlansPage> {
  bool _isYearly = false;

  void _showPaymentModal(BuildContext context, String planName, int basePrice, RippleUser user, IUserRepository userRepo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _PaymentSheet(
        planName: planName,
        basePrice: basePrice,
        isYearly: _isYearly,
        user: user,
        userRepo: userRepo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;

    final authRepo = ref.watch(authRepositoryProvider);
    final userRepo = ref.watch(userRepositoryProvider);

    return Container(
      decoration: RippleTheme.backgroundDecoration(isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.translate('plans')),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: FutureBuilder<RippleUser?>(
          future: authRepo.getCurrentUser(),
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;
            if (user == null) return const Center(child: CircularProgressIndicator());

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select the tier that fits your family coordination needs.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Billing toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Monthly', style: TextStyle(fontWeight: !_isYearly ? FontWeight.bold : FontWeight.normal)),
                      Switch(value: _isYearly, activeColor: primaryColor, onChanged: (val) => setState(() => _isYearly = val)),
                      Row(children: [
                        Text('Yearly', style: TextStyle(fontWeight: _isYearly ? FontWeight.bold : FontWeight.normal)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Save 20%', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildTierCard(context, title: 'Free', price: 0,
                    features: ['Profile setup & children cards', '1 match notification per week', 'View match overview cards'],
                    isCurrent: user.subscriptionTier == 'free', ctaText: 'Current Plan', onPressed: () {},
                    primaryColor: primaryColor, isDark: isDark),
                  const SizedBox(height: 20),
                  _buildTierCard(context, title: 'Premium', price: 5,
                    features: ['Unlimited match notifications', 'Full match details & swap maps', 'Direct in-app messaging', 'Interactive transfer insights'],
                    isCurrent: user.subscriptionTier == 'premium', ctaText: 'Upgrade Premium',
                    onPressed: () => _showPaymentModal(context, 'Premium', 5, user, userRepo),
                    primaryColor: primaryColor, isDark: isDark, isPopular: true),
                  const SizedBox(height: 20),
                  _buildTierCard(context, title: 'Insight+', price: 12,
                    features: ['Personalised chance calculator', 'Area density strategy guides', 'Waiting list rank tracker', 'Admissions expert Q&A board'],
                    isCurrent: user.subscriptionTier == 'insightplus', ctaText: 'Upgrade Insight+',
                    onPressed: () => _showPaymentModal(context, 'Insight+', 12, user, userRepo),
                    primaryColor: RippleTheme.accentCoral, isDark: isDark),

                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase history restored.'))),
                    child: const Text('Restore Purchases', style: TextStyle(decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, {
    required String title, required int price, required List<String> features,
    required bool isCurrent, required String ctaText, required VoidCallback onPressed,
    required Color primaryColor, required bool isDark, bool isPopular = false,
  }) {
    final showPrice = _isYearly ? (price * 12 * 0.8).toInt() : price;
    final billingCycle = _isYearly ? '/yr' : '/mo';

    return Stack(children: [
      RippleCard(
        borderColor: isPopular ? primaryColor : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
              if (isCurrent) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('£$showPrice', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              Text(billingCycle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...features.map((feat) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(child: Text(feat, style: const TextStyle(fontSize: 13))),
              ]),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Active Plan'))
                  : RippleButton(text: ctaText, onPressed: onPressed),
            ),
          ]),
        ),
      ),
      if (isPopular)
        Positioned(
          top: 0, right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: primaryColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6))),
            child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
          ),
        ),
    ]);
  }
}

// ─── Payment Sheet ────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final String planName;
  final int basePrice;
  final bool isYearly;
  final RippleUser user;
  final IUserRepository userRepo;

  const _PaymentSheet({
    required this.planName, required this.basePrice, required this.isYearly,
    required this.user, required this.userRepo,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> with TickerProviderStateMixin {
  // Step: 0 = card entry, 1 = processing, 2 = success
  int _step = 0;

  // Card form controllers
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Live card preview state
  String _previewNumber = '•••• •••• •••• ••••';
  String _previewExpiry = 'MM/YY';
  String _previewName = 'CARDHOLDER NAME';
  String _previewCvv = '•••';
  bool _showCvv = false;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));

    _cardNumberCtrl.addListener(() {
      final raw = _cardNumberCtrl.text.replaceAll(' ', '');
      final groups = <String>[];
      for (int i = 0; i < raw.length && i < 16; i += 4) {
        groups.add(raw.substring(i, math.min(i + 4, raw.length)));
      }
      final filled = groups.join(' ');
      final remaining = 4 - groups.length;
      final placeholders = List.generate(remaining, (_) => '••••').join(' ');
      setState(() => _previewNumber = remaining > 0 ? '$filled ${placeholders}' : filled);
    });
    _expiryCtrl.addListener(() {
      setState(() => _previewExpiry = _expiryCtrl.text.isEmpty ? 'MM/YY' : _expiryCtrl.text);
    });
    _nameCtrl.addListener(() {
      setState(() => _previewName = _nameCtrl.text.isEmpty ? 'CARDHOLDER NAME' : _nameCtrl.text.toUpperCase());
    });
    _cvvCtrl.addListener(() {
      setState(() => _previewCvv = _cvvCtrl.text.isEmpty ? '•••' : _cvvCtrl.text);
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  int get price => widget.isYearly ? (widget.basePrice * 12 * 0.8).toInt() : widget.basePrice;
  String get cycle => widget.isYearly ? '/year' : '/month';

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);
    await Future.delayed(const Duration(seconds: 3));
    final upgradedUser = widget.user.copyWith(subscriptionTier: widget.planName.toLowerCase().replaceAll('+', 'plus'));
    await widget.userRepo.saveUserProfile(upgradedUser);
    setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: _step == 2 ? _buildSuccess(primaryColor, isDark) : _step == 1 ? _buildProcessing(primaryColor) : _buildCardForm(primaryColor, isDark),
      ),
    );
  }

  // ─── Step 0: Card Entry ───────────────────────────────────────────────────

  Widget _buildCardForm(Color primaryColor, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Drag handle
      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Checkout: ${widget.planName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ]),
      Text('£$price$cycle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryColor)),
      const SizedBox(height: 20),

      // Glassmorphic card preview
      _buildCardPreview(primaryColor, isDark),
      const SizedBox(height: 24),

      const Text('Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 12),

      Form(key: _formKey, child: Column(children: [
        // Card Number
        _buildField(
          controller: _cardNumberCtrl,
          label: 'Card Number',
          hint: '1234 5678 9012 3456',
          icon: Icons.credit_card_rounded,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || v.replaceAll(' ', '').length < 16) ? 'Enter a valid 16-digit card number' : null,
        ),
        const SizedBox(height: 12),

        // Expiry + CVV row
        Row(children: [
          Expanded(child: _buildField(
            controller: _expiryCtrl,
            label: 'Expiry',
            hint: 'MM/YY',
            icon: Icons.calendar_month_rounded,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), _ExpiryFormatter()],
            keyboardType: TextInputType.number,
            validator: (v) => (v == null || v.length < 5) ? 'Invalid expiry' : null,
          )),
          const SizedBox(width: 12),
          Expanded(child: _buildField(
            controller: _cvvCtrl,
            label: 'CVV',
            hint: '•••',
            icon: Icons.lock_rounded,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            keyboardType: TextInputType.number,
            isObscure: true,
            onFocusChange: (focused) {
              if (focused) {
                _flipCtrl.forward();
                setState(() => _showCvv = true);
              } else {
                _flipCtrl.reverse();
                setState(() => _showCvv = false);
              }
            },
            validator: (v) => (v == null || v.length < 3) ? 'Invalid CVV' : null,
          )),
        ]),
        const SizedBox(height: 12),

        // Cardholder Name
        _buildField(
          controller: _nameCtrl,
          label: 'Cardholder Name',
          hint: 'John Smith',
          icon: Icons.person_rounded,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter cardholder name' : null,
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _processPayment,
            icon: const Icon(Icons.lock_rounded, size: 18, color: Colors.black),
            label: Text('Pay £$price Securely', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.security_rounded, size: 12, color: Colors.grey.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text('256-bit SSL encrypted payment', style: TextStyle(fontSize: 10, color: Colors.grey.withOpacity(0.6))),
        ])),
      ])),
    ]);
  }

  Widget _buildCardPreview(Color primaryColor, bool isDark) {
    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (context, child) {
        final angle = _flipAnim.value * math.pi;
        final isBack = angle > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateY(angle),
          child: Container(
            height: 185,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withBlue(200), const Color(0xFF0F172A)],
              ),
              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: isBack ? _buildCardBack() : _buildCardFront(primaryColor),
          ),
        );
      },
    );
  }

  Widget _buildCardFront(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('RIPPLE CARD', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Icon(Icons.contactless_rounded, color: Colors.white.withOpacity(0.7), size: 24),
        ]),
        Text(_previewNumber, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CARDHOLDER', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
            Text(_previewName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EXPIRES', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
            Text(_previewExpiry, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildCardBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 32),
        Container(width: double.infinity, height: 40, color: Colors.black54),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Expanded(child: Container(height: 35, color: Colors.white12)),
            const SizedBox(width: 12),
            Container(
              width: 60, height: 35,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.center,
              child: Text(_previewCvv, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('CVV', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
        ),
      ]),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool isObscure = false,
    String? Function(String?)? validator,
    void Function(bool)? onFocusChange,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ─── Step 1: Processing ────────────────────────────────────────────────────

  Widget _buildProcessing(Color primaryColor) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 40),
      SizedBox(
        width: 64, height: 64,
        child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
      ),
      const SizedBox(height: 28),
      const Text('Processing Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Connecting with payment gateway.\nPlease do not close this screen.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 12),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(children: [
          _buildProgressStep('Validating card details', true, primaryColor),
          _buildProgressStep('Authorising with bank', true, primaryColor),
          _buildProgressStep('Securing transaction', false, primaryColor),
        ]),
      ),
      const SizedBox(height: 40),
    ]);
  }

  Widget _buildProgressStep(String text, bool done, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16, color: done ? color : Colors.grey),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 12, color: done ? null : Colors.grey)),
      ]),
    );
  }

  // ─── Step 2: Success ───────────────────────────────────────────────────────

  Widget _buildSuccess(Color primaryColor, bool isDark) {
    return Column(children: [
      const SizedBox(height: 32),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor.withOpacity(0.1),
          border: Border.all(color: primaryColor, width: 2),
        ),
        child: Icon(Icons.check_rounded, color: primaryColor, size: 52),
      ),
      const SizedBox(height: 20),
      const Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(
        'You\'ve been upgraded to ${widget.planName}.\nAll premium features are now unlocked.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
      ),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          _buildReceiptRow('Plan', widget.planName, primaryColor),
          const Divider(height: 16),
          _buildReceiptRow('Amount', '£${widget.isYearly ? (widget.basePrice * 12 * 0.8).toInt() : widget.basePrice}${widget.isYearly ? '/yr' : '/mo'}', primaryColor),
          const Divider(height: 16),
          _buildReceiptRow('Status', 'Paid ✓', Colors.green),
        ]),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.go('/profile');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          child: const Text('Return to Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildReceiptRow(String label, String value, Color valueColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
    ]);
  }
}

// ─── Input Formatters ─────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length >= 2) {
      final formatted = '${text.substring(0, 2)}/${text.substring(2)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}
