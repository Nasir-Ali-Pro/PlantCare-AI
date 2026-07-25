import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_card.dart';

class LegalScreen extends StatelessWidget {
  final bool isPrivacyPolicy;
  const LegalScreen({super.key, this.isPrivacyPolicy = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isPrivacyPolicy ? 'Privacy Policy' : 'Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPrivacyPolicy ? Icons.privacy_tip_rounded : Icons.gavel_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isPrivacyPolicy ? 'Privacy Policy' : 'Terms of Service',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Last updated: July 2026',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const Divider(color: Colors.white12, height: 28),
                      Text(
                        isPrivacyPolicy ? _privacyPolicyText : _termsText,
                        style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const String _privacyPolicyText = '''
Welcome to PlantCareAI. We are committed to protecting your personal information and your right to privacy.

1. INFORMATION WE COLLECT

Account Information: When you register, we collect your name and email address, stored securely via Supabase.

Plant & Garden Data: Your plant collection, care schedules, and growth journal are stored locally on your device and optionally synced to our secure cloud.

Diagnostic Images: Photos you take for plant diagnosis are processed by Google Gemini AI and are not permanently stored on our servers.

Usage Analytics: We collect anonymized usage data to improve the App.

2. HOW WE USE YOUR INFORMATION

We use your information to:
• Provide and operate the App and its features
• Send you care reminders and notifications you authorize
• Improve our AI diagnosis and recommendations
• Respond to your support requests

3. DATA SHARING

We do not sell your personal data. We share data only with:
• Google Gemini AI (for plant analysis) — processed ephemerally
• Supabase (for cloud storage) — GDPR and SOC 2 compliant

4. DATA SECURITY

We implement industry-standard encryption for your data at rest (AES-256) and in transit (TLS 1.3). Your diagnosis history is encrypted locally using device-level security.

5. YOUR RIGHTS

You have the right to access, correct, or delete your personal data at any time. You may delete your account from the Profile screen. We will remove all associated data within 30 days of your request.

6. CHILDREN'S PRIVACY

Our App is not directed to children under 13. We do not knowingly collect personal information from children under 13.

7. CONTACT US

For questions, contact us at privacy@plantcareai.app
''';

  static const String _termsText = '''
By using PlantCareAI ("App"), you agree to these Terms of Service.

1. ACCEPTANCE OF TERMS

By downloading, installing, or using PlantCareAI, you agree to be bound by these Terms.

2. USE OF THE APP

You may use PlantCareAI for personal, non-commercial use. You agree not to:
• Use the App for any unlawful purpose
• Attempt to reverse engineer or copy the App
• Upload harmful, illegal, or inappropriate content
• Use the App to harass other community members

3. AI DISCLAIMER

PlantCareAI uses AI for plant diagnosis. Results are informational only and should not replace professional agricultural advice. We make no guarantees about the accuracy of AI-generated diagnoses.

4. AFFILIATE DISCLOSURE

The Shop section contains affiliate links to third-party products. We may earn a commission when you purchase through these links at no extra cost to you.

5. INTELLECTUAL PROPERTY

All content, trademarks, and features of PlantCareAI are owned by or licensed to us.

6. LIMITATION OF LIABILITY

To the maximum extent permitted by law, PlantCareAI shall not be liable for any indirect, incidental, or consequential damages from your use of the App.

7. CONTACT US

For questions, contact us at legal@plantcareai.app
''';
}
