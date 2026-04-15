// lib/features/booking/widgets/pay_method_card.dart
import 'package:flutter/material.dart';

import '../viewmodels/payment_view_model.dart';

class PayMethodCard extends StatelessWidget {
  const PayMethodCard({
    super.key,
    required this.method,
    required this.detailText,
    required this.selectedMethod,
    required this.onChanged,
  });

  final PayMethod method;
  final String detailText;
  final PayMethod selectedMethod;
  final ValueChanged<PayMethod> onChanged;

  bool get _isSelected => method == selectedMethod;

  IconData get _icon {
    switch (method) {
      case PayMethod.tng:
        return Icons.account_balance_wallet_outlined;
      case PayMethod.card:
        return Icons.credit_card_outlined;
      case PayMethod.banking:
        return Icons.account_balance_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isSelected
                ? const Color(0xFF1C894E)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon,
                  color: const Color(0xFF1C894E), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    detailText,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Radio<PayMethod>(
              value: method,
              groupValue: selectedMethod,
              onChanged: (v) => onChanged(v!),
              activeColor: const Color(0xFF1C894E),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
