import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  
  String _category = 'general';
  String _priority = 'medium';
  bool _isSubmitting = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I toggle human takeover mode?',
      'answer': 'Open a conversation in your Chats list and tap the "Assign to Me" or hand icon in the top right. This pauses the AI and routes messages directly to you. Tap "Release to AI" to hand control back.'
    },
    {
      'question': 'Can I edit my AI agents from the mobile app?',
      'answer': 'No, agent prompts and knowledge base configurations can only be updated from the desktop Web Dashboard to ensure accuracy and detail.'
    },
    {
      'question': 'What are credits and how are they charged?',
      'answer': 'Message credits are deducted whenever your account sends or receives WhatsApp messages. Auto-replies, templates, and human agent replies all count towards your monthly credit limits.'
    },
    {
      'question': 'Why is my chat list not loading?',
      'answer': 'Ensure your mobile device has active internet access. You can also tap the refresh icon in the app bar to reload the live streams from your database.'
    }
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _supabaseService.createSupportTicket(
        _subjectController.text,
        _descController.text,
        _category,
        _priority,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket submitted successfully!')),
        );
        _subjectController.clear();
        _descController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/support'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQs
            _buildHeader('FREQUENTLY ASKED QUESTIONS'),
            const SizedBox(height: 12),
            ..._faqs.map((faq) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(
                      faq['question']!,
                      style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                        child: Text(
                          faq['answer']!,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      )
                    ],
                  ),
                )),
            const SizedBox(height: 32),

            // Ticket Form
            _buildHeader('CREATE A SUPPORT TICKET'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _subjectController,
                        style: TextStyle(color: AppColors.text),
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Enter ticket subject',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        style: TextStyle(color: AppColors.text),
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe the issue or request in detail...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              style: TextStyle(color: AppColors.text),
                              dropdownColor: AppColors.surface,
                              decoration: const InputDecoration(labelText: 'Category'),
                              items: const [
                                DropdownMenuItem(value: 'general', child: Text('General')),
                                DropdownMenuItem(value: 'billing', child: Text('Billing')),
                                DropdownMenuItem(value: 'technical', child: Text('Technical')),
                                DropdownMenuItem(value: 'bug', child: Text('Report Bug')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _category = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _priority,
                              style: TextStyle(color: AppColors.text),
                              dropdownColor: AppColors.surface,
                              decoration: const InputDecoration(labelText: 'Priority'),
                              items: const [
                                DropdownMenuItem(value: 'low', child: Text('Low')),
                                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                DropdownMenuItem(value: 'high', child: Text('High')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _priority = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textInverse,
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textInverse),
                                  ),
                                )
                              : const Text('Submit Ticket'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
