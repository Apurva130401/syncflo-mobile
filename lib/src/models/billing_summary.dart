// Data behind the Billing screen, from the dashboard's `GET /api/billing/summary`
// (the same response the web Billing page renders).

String? _str(dynamic v) => v?.toString();

String? _cap(String? s) => s == null || s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class BillingSub {
  final String? planId;
  final String? currentPlan;
  final String? billingCycle;
  final String? status;
  final String? endDate;
  final String? paymentProvider;
  final bool cancelAtPeriodEnd;
  final String? scheduledPlanId;
  final String? scheduledPlanName;
  final String? scheduledBillingCycle;
  final String? scheduledChangeAt;

  BillingSub({
    this.planId,
    this.currentPlan,
    this.billingCycle,
    this.status,
    this.endDate,
    this.paymentProvider,
    this.cancelAtPeriodEnd = false,
    this.scheduledPlanId,
    this.scheduledPlanName,
    this.scheduledBillingCycle,
    this.scheduledChangeAt,
  });

  factory BillingSub.fromJson(Map<String, dynamic> j) => BillingSub(
        planId: _str(j['plan_id']),
        currentPlan: _str(j['current_plan']),
        billingCycle: _str(j['billing_cycle']),
        status: _str(j['subscription_status']),
        endDate: _str(j['subscription_end_date']) ?? _str(j['current_period_end']),
        paymentProvider: _str(j['payment_provider']),
        cancelAtPeriodEnd: j['cancel_at_period_end'] == true,
        scheduledPlanId: _str(j['scheduled_plan_id']),
        scheduledPlanName: _str(j['scheduled_plan_name']),
        scheduledBillingCycle: _str(j['scheduled_billing_cycle']),
        scheduledChangeAt: _str(j['scheduled_change_at']),
      );
}

class BillingPayment {
  final String id;
  final String planName;
  final String? billingCycle;
  final double amount;
  final String? currency;
  final String status;
  final String? paymentStatus;
  final String createdAt;

  BillingPayment({
    required this.id,
    required this.planName,
    this.billingCycle,
    required this.amount,
    this.currency,
    required this.status,
    this.paymentStatus,
    required this.createdAt,
  });

  bool get isPaid => status == 'paid' || status == 'succeeded' || paymentStatus == 'paid';

  factory BillingPayment.fromJson(Map<String, dynamic> j) => BillingPayment(
        id: _str(j['id']) ?? '',
        planName: _str(j['plan_name']) ?? '',
        billingCycle: _str(j['billing_cycle']),
        amount: double.tryParse(_str(j['amount']) ?? '') ?? 0,
        currency: _str(j['currency']),
        status: _str(j['status']) ?? '',
        paymentStatus: _str(j['payment_status']),
        createdAt: _str(j['created_at']) ?? '',
      );
}

class BillingMethod {
  final String? methodType;
  final String? cardNetwork;
  final String? cardLastFour;
  final String? cardType;
  final String? upiVpa;
  final String? mandateType;
  final bool isDefault;

  BillingMethod({
    this.methodType,
    this.cardNetwork,
    this.cardLastFour,
    this.cardType,
    this.upiVpa,
    this.mandateType,
    this.isDefault = false,
  });

  factory BillingMethod.fromJson(Map<String, dynamic> j) => BillingMethod(
        methodType: _str(j['method_type']),
        cardNetwork: _str(j['card_network']),
        cardLastFour: _str(j['card_last_four']),
        cardType: _str(j['card_type']),
        upiVpa: _str(j['upi_vpa']),
        mandateType: _str(j['mandate_type']),
        isDefault: j['is_default'] == true,
      );

  String get label {
    if (cardLastFour != null && cardLastFour!.isNotEmpty) {
      return '${_cap(cardNetwork) ?? 'Card'} ending $cardLastFour';
    }
    final type = (methodType ?? '').toLowerCase().trim().replaceAll(RegExp(r'[\s-]+'), '_');
    if (type.startsWith('upi')) {
      if (upiVpa != null && upiVpa!.contains('@')) {
        final parts = upiVpa!.split('@');
        final handle = parts.first;
        return 'UPI ${handle.length >= 2 ? handle.substring(0, 2) : handle}•••@${parts.last}';
      }
      return 'UPI';
    }
    if (type.isEmpty) return 'Saved method';
    final words = type.split('_').where((w) => w.isNotEmpty).toList();
    return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String? get detail {
    final parts = [_cap(cardType), _cap(mandateType)].whereType<String>().where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class BillingSummary {
  final BillingSub? sub;
  final List<BillingPayment> payments;
  final List<BillingMethod> methods;

  BillingSummary({this.sub, this.payments = const [], this.methods = const []});

  factory BillingSummary.fromJson(Map<String, dynamic> j) {
    final details = j['subscriptionDetails'];
    final history = j['paymentHistory'];
    final methods = j['paymentMethods'];
    return BillingSummary(
      sub: details is Map<String, dynamic> ? BillingSub.fromJson(details) : null,
      payments: history is List
          ? history.whereType<Map<String, dynamic>>().map(BillingPayment.fromJson).toList()
          : const [],
      methods: methods is List
          ? methods.whereType<Map<String, dynamic>>().map(BillingMethod.fromJson).toList()
          : const [],
    );
  }
}
