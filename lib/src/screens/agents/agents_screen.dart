import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

const _siteUrl = 'https://dashboard.syncflo.xyz';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Agent> _agents = [];
  String? _error;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final agents = await _supabaseService.getAgents();
      if (!mounted) return;
      setState(() {
        _agents = agents;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _open(String path) async {
    final ok = await launchUrl(Uri.parse('$_siteUrl$path'), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Agents'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(icon: Icon(LucideIcons.refresh_cw, size: 20), onPressed: _loadAgents),
        ],
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/agents'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _loadAgents(silent: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _hero(),
                      if (_agents.isNotEmpty)
                        _column([
                          for (final agent in _agents) _agentSection(agent),
                          const SizedBox(height: 48),
                        ]),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We couldn’t load your agents',
                style: TextStyle(color: AppColors.text, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
              ),
              const SizedBox(height: 12),
              Text(
                'Nothing has changed with your agents. $_error',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: 24),
              _button('Try again', _loadAgents, fill: AppColors.primary, label: AppColors.textInverse),
            ],
          ),
        ),
      ),
    );
  }

  /// Readable column, same side margins everywhere, centred on wide screens.
  Widget _column(List<Widget> children) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // First screen: how many agents are answering customers
  // ---------------------------------------------------------------------------

  Widget _hero() {
    final ink = AppColors.textInverse;
    final soft = ink.withValues(alpha: 0.8);
    final live = _agents.where((a) => a.isActive).length;

    final String headline;
    final String body;
    final String action;
    final String path;
    if (_agents.isEmpty) {
      headline = 'No AI agent yet';
      body = 'Set up your first agent on the web dashboard and it starts answering customers on WhatsApp.';
      action = 'Set up an agent';
      path = '/dashboard/whatsapp/onboarding';
    } else if (live == 0) {
      headline = 'Your agent is paused';
      body = 'Customers get no AI replies until you switch it back on in the web dashboard.';
      action = 'Open on the web';
      path = '/dashboard/whatsapp/prompts';
    } else {
      headline = live == 1 ? '1 agent is answering customers' : '$live agents are answering customers';
      body = 'Prompts and rules are edited on the web dashboard. This screen shows what each agent is set up to do.';
      action = 'Edit on the web';
      path = '/dashboard/whatsapp/prompts';
    }

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(color: ink, fontSize: 44, fontWeight: FontWeight.w800, height: 1.02, letterSpacing: -1.5),
                ),
                const SizedBox(height: 14),
                Text(body, style: TextStyle(color: soft, fontSize: 17, height: 1.45)),
                const SizedBox(height: 26),
                _button(action, () => _open(path), fill: ink, label: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // One agent
  // ---------------------------------------------------------------------------

  Widget _agentSection(Agent agent) {
    final open = _expanded.contains(agent.id);
    final prompt = agent.systemPrompt.trim();
    final long = prompt.length > 280;

    return Padding(
      padding: const EdgeInsets.only(top: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            agent.name.isEmpty ? 'Unnamed agent' : agent.name,
            style: TextStyle(color: AppColors.text, fontSize: 30, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.8),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: agent.isActive ? 'Live' : 'Paused',
                  style: TextStyle(
                    color: agent.isActive ? AppColors.success : AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' · ${_cap(agent.tone)} tone',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 17),
          ),
          if (agent.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              agent.description,
              style: TextStyle(color: AppColors.text, fontSize: 17, height: 1.5),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Instructions',
            style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 12),
          if (prompt.isEmpty)
            Text(
              'No instructions have been written for this agent yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45),
            )
          else
            Container(
              width: double.infinity,
              color: AppColors.surfaceLight,
              padding: const EdgeInsets.all(18),
              child: Text(
                prompt,
                maxLines: open ? null : 7,
                overflow: open ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.text, fontSize: 16, height: 1.5),
              ),
            ),
          if (long)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => setState(() => open ? _expanded.remove(agent.id) : _expanded.add(agent.id)),
                child: Text(
                  open ? 'Show less' : 'Read all instructions',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Filled button, square corners, no border and no shadow.
  Widget _button(String text, VoidCallback onTap, {required Color fill, required Color label}) {
    return Material(
      color: fill,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Text(text, style: TextStyle(color: label, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
