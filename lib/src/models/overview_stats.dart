// Headline numbers for the Overview screen, from the dashboard's `GET /api/analytics/overview`
// (the same figures the web Overview shows, so the two always agree).

class OverviewStats {
  final double? avgResponseSeconds;
  final double? conversionRate;
  final double? automationRate;
  final int activeLeads;
  final String? firstName;

  const OverviewStats({
    this.avgResponseSeconds,
    this.conversionRate,
    this.automationRate,
    this.activeLeads = 0,
    this.firstName,
  });

  factory OverviewStats.fromJson(Map<String, dynamic> j) {
    double? num_(dynamic v) => v is num ? v.toDouble() : null;
    final profile = (j['member_profile'] ?? j['profile']);
    final first = profile is Map ? profile['first_name']?.toString().trim() : null;
    return OverviewStats(
      avgResponseSeconds: num_(j['avg_response_time_seconds']),
      conversionRate: num_(j['conversion_rate']),
      automationRate: num_(j['automation_rate']),
      activeLeads: (j['active_leads'] as num?)?.toInt() ?? 0,
      firstName: (first == null || first.isEmpty) ? null : first,
    );
  }
}
