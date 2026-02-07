import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/helpers/contact_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  final bool showFAQ;

  const HelpSupportScreen({
    super.key,
    this.showFAQ = true, // Default to true for Owner/Admin
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('help.title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.padL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppConstants.radiusL,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.question_circle_fill,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppConstants.padM),
                  Text(
                    'help.header_title'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'help.header_subtitle'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.padXL),

            // Contact Support Section
            _buildSectionTitle(theme, 'help.contact_section'.tr()),
            const SizedBox(height: AppConstants.padM),

            _ContactCard(
              icon: CupertinoIcons.mail_solid,
              title: 'help.email_support'.tr(),
              subtitle: 'alphatechlab@gmail.com',
              color: AppColors.primary,
              onTap: () => _launchEmail(context),
            ),
            const SizedBox(height: AppConstants.padM),
            _ContactCard(
              icon: CupertinoIcons.chat_bubble_2_fill,
              title: 'help.whatsapp_support'.tr(),
              subtitle: '+255 792 747 056',
              color: const Color(0xFF25D366),
              onTap: () => _launchWhatsApp(context),
            ),
            const SizedBox(height: AppConstants.padM),
            _ContactCard(
              icon: CupertinoIcons.phone_fill,
              title: 'help.call_support'.tr(),
              subtitle: '+255 710 698 702',
              color: AppColors.accent2,
              onTap: () => _launchPhone(context),
            ),

            const SizedBox(height: AppConstants.padXL),

            // FAQs Section - Conditionally rendered based on showFAQ
            if (showFAQ) ...[
              _buildSectionTitle(theme, 'help.faq_section'.tr()),
              const SizedBox(height: AppConstants.padM),

              _FAQItem(
                question: 'help.faq1_question'.tr(),
                answer: 'help.faq1_answer'.tr(),
              ),
              _FAQItem(
                question: 'help.faq2_question'.tr(),
                answer: 'help.faq2_answer'.tr(),
              ),
              _FAQItem(
                question: 'help.faq3_question'.tr(),
                answer: 'help.faq3_answer'.tr(),
              ),
              _FAQItem(
                question: 'help.faq4_question'.tr(),
                answer: 'help.faq4_answer'.tr(),
              ),
              _FAQItem(
                question: 'help.faq5_question'.tr(),
                answer: 'help.faq5_answer'.tr(),
              ),

              const SizedBox(height: AppConstants.padXL),
            ],

            // App Info Section (Simplified: Only Icon + Version)
            _buildSectionTitle(theme, 'help.about_section'.tr()),
            const SizedBox(height: AppConstants.padM),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.padL),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppConstants.radiusL,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.sparkles,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppConstants.padM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pendeza',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'help.app_version'.tr(args: ['1.0.0']),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'alphatechlab@gmail.com',
      queryParameters: {
        'subject': 'Support Request - Pendeza App',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  void _launchWhatsApp(BuildContext context) async {
    ContactHelper.openWhatsApp(
      phone: '+255793747056',
      message: 'Hello, I need help with the Pendeza app.',
    );
  }

  void _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '+255710698702');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone app')),
        );
      }
    }
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.padM),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppConstants.radiusL,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppConstants.padM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppConstants.radiusL,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.padM,
            vertical: AppConstants.padXS,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppConstants.padM,
            right: AppConstants.padM,
            bottom: AppConstants.padM,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.question,
              color: theme.colorScheme.primary,
              size: 18,
            ),
          ),
          title: Text(
            widget.question,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          children: [
            Text(
              widget.answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}