/// One WhatsApp AI call, as returned by `GET /api/whatsapp/calling/calls`.
class CallRecord {
  final String id;
  final String direction; // 'inbound' | 'outbound'
  final String status; // ringing | in_progress | completed | failed | no_answer | rejected
  final String? callerNumber;
  final String? calleeNumber;
  final String? contactName;
  final String? startedAt;
  final String? answeredAt;
  final String? endedAt;
  final int? durationSeconds;
  final String? summary;
  final String? outcome;
  final String? transcript;
  final String createdAt;

  const CallRecord({
    required this.id,
    required this.direction,
    required this.status,
    this.callerNumber,
    this.calleeNumber,
    this.contactName,
    this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds,
    this.summary,
    this.outcome,
    this.transcript,
    required this.createdAt,
  });

  factory CallRecord.fromJson(Map<String, dynamic> j) {
    return CallRecord(
      id: j['id'].toString(),
      direction: (j['direction'] ?? 'inbound').toString(),
      status: (j['status'] ?? 'ringing').toString(),
      callerNumber: j['caller_number']?.toString(),
      calleeNumber: j['callee_number']?.toString(),
      contactName: j['contact_name']?.toString(),
      startedAt: j['started_at']?.toString(),
      answeredAt: j['answered_at']?.toString(),
      endedAt: j['ended_at']?.toString(),
      durationSeconds: (j['duration_seconds'] as num?)?.toInt(),
      summary: j['summary']?.toString(),
      outcome: j['outcome']?.toString(),
      transcript: j['transcript']?.toString(),
      createdAt: (j['created_at'] ?? '').toString(),
    );
  }

  bool get isInbound => direction == 'inbound';
  bool get isLive => status == 'ringing' || status == 'in_progress';

  /// The customer's number (the other party).
  String get otherNumber => (isInbound ? callerNumber : calleeNumber) ?? '';

  /// Saved contact name, falling back to the number.
  String get displayName => (contactName != null && contactName!.isNotEmpty)
      ? contactName!
      : (otherNumber.isEmpty ? 'Unknown' : otherNumber);
}

class CallTotals {
  final int calls;
  final double minutes;
  const CallTotals({this.calls = 0, this.minutes = 0});

  factory CallTotals.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const CallTotals();
    return CallTotals(
      calls: (j['calls'] as num?)?.toInt() ?? 0,
      minutes: (j['minutes'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Per-number AI Calling state from `GET /api/whatsapp/calling/status`.
class CallingNumber {
  final String id;
  final String label;
  final String? phoneNumber;
  final bool callingEnabled;
  final String callingStatus;
  final String? lastError;

  const CallingNumber({
    required this.id,
    required this.label,
    this.phoneNumber,
    required this.callingEnabled,
    required this.callingStatus,
    this.lastError,
  });

  factory CallingNumber.fromJson(Map<String, dynamic> j) {
    return CallingNumber(
      id: j['id'].toString(),
      label: (j['label'] ?? j['phoneNumber'] ?? 'Number').toString(),
      phoneNumber: j['phoneNumber']?.toString(),
      callingEnabled: j['callingEnabled'] == true,
      callingStatus: (j['callingStatus'] ?? 'not_connected').toString(),
      lastError: j['lastError']?.toString(),
    );
  }
}
