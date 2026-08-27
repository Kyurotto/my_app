import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';

class _PaymentAccount {
  final String provider;
  final String accountNumber;

  const _PaymentAccount({
    required this.provider,
    required this.accountNumber,
  });
}

class PaymentModal extends StatefulWidget {
  final double total;
  final Function(String paymentMethod) onConfirm;

  const PaymentModal({
    super.key,
    required this.total,
    required this.onConfirm,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String _selectedMethod = 'physical'; // 'physical' or 'universal'

  static const _paymentAccounts = <_PaymentAccount>[
    _PaymentAccount(
      provider: 'GCash',
      accountNumber: '09676128378',
    ),
    _PaymentAccount(
      provider: 'Maya',
      accountNumber: '09676128378',
    ),
    _PaymentAccount(
      provider: 'MariBank',
      accountNumber: '16837903888',
    ),
  ];

  String _getQRData() {
    return [
      'Universal payment QR',
      ..._paymentAccounts.map(
        (account) => '${account.provider}: ${account.accountNumber}',
      ),
      'Amount: ${widget.total.toStringAsFixed(2)}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isQRMethod = _selectedMethod == 'universal';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.amberGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFFD97706),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select Payment Method',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1B18),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how the customer will pay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // Physical Payment Section
              const Text(
                'PHYSICAL PAYMENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Color(0xFF78716C),
                ),
              ),
              const SizedBox(height: 8),
              _buildOption(
                id: 'physical',
                title: 'Cash',
                subtitle: 'Physical cash payment',
                icon: Icons.attach_money_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
              ),
              const SizedBox(height: 16),

              // Online Payment Section
              const Text(
                'ONLINE PAYMENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Color(0xFF78716C),
                ),
              ),
              const SizedBox(height: 8),
              _buildOption(
                id: 'universal',
                title: 'Universal QR Payment',
                subtitle: 'One QR for GCash, Maya, and MariBank',
                icon: Icons.qr_code_scanner_rounded,
                iconBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
              ),

              // One QR code containing all supported payment accounts.
              if (isQRMethod) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF93C5FD).withValues(alpha: 0.6),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'SCAN UNIVERSAL QR TO PAY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _getQRData(),
                          version: QrVersions.auto,
                          size: 150.0,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1E293B),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Available payment accounts',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final account in _paymentAccounts)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${account.provider}: ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              Text(
                                account.accountNumber,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount: \$${widget.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Confirm the recipient name shown in your payment app before sending',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              // Total Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEFE8DB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total to Collect',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF78716C),
                      ),
                    ),
                    Text(
                      '\$${widget.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onConfirm(_selectedMethod);
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Confirm & Print'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.amberGold,
                        foregroundColor: AppTheme.primaryCoffee,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    final isSelected = _selectedMethod == id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = id),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.amberGold.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.amberDark : const Color(0xFFECE7DE),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B18),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
