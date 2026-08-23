import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../app/config/theme/app_constants.dart';
import '../../../../../shared/models/service_model.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';

class WalkInSheet extends StatefulWidget {
  final DateTime selectedDay;
  final List<ServiceModel> services;
  final Future<void> Function({
    required String clientName,
    required ServiceModel service,
    required DateTime startTime,
  }) onSubmit;

  const WalkInSheet({
    super.key,
    required this.selectedDay,
    required this.services,
    required this.onSubmit,
  });

  @override
  State<WalkInSheet> createState() => _WalkInSheetState();
}

class _WalkInSheetState extends State<WalkInSheet> {
  final _nameController = TextEditingController();
  ServiceModel? _service;
  TimeOfDay _time = TimeOfDay.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final active = widget.services.where((s) => s.isActive).toList();
    if (active.isNotEmpty) _service = active.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _service == null || _submitting) return;

    setState(() => _submitting = true);
    final start = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _time.hour,
      _time.minute,
    );
    try {
      await widget.onSubmit(
        clientName: name,
        service: _service!,
        startTime: start,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('owner.calendar.walk_in_error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final activeServices = widget.services.where((s) => s.isActive).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.padL),
            Text(
              'owner.calendar.walk_in_title'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.padL),
            if (activeServices.isEmpty)
              Text(
                'owner.calendar.walk_in_no_services'.tr(),
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              TextField(
                controller: _nameController,
                enabled: !_submitting,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'owner.calendar.walk_in_name_label'.tr(),
                  hintText: 'owner.calendar.walk_in_name_hint'.tr(),
                ),
              ),
              const SizedBox(height: AppConstants.padM),
              DropdownButtonFormField<ServiceModel>(
                initialValue: _service,
                decoration: InputDecoration(
                  labelText: 'owner.calendar.walk_in_service_label'.tr(),
                ),
                items: activeServices
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _service = value),
              ),
              const SizedBox(height: AppConstants.padM),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('owner.calendar.walk_in_time_label'.tr()),
                subtitle: Text(_time.format(context)),
                trailing: Icon(
                  Icons.schedule,
                  color: theme.colorScheme.primary,
                ),
                onTap: _submitting ? null : _pickTime,
              ),
              const SizedBox(height: AppConstants.padL),
              PrimaryGradientButton(
                text: 'owner.calendar.walk_in_save'.tr(),
                isLoading: _submitting,
                onPressed: _save,
              ),
            ],
            const SizedBox(height: AppConstants.padM),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showWalkInSheet(
  BuildContext context, {
  required DateTime selectedDay,
  required List<ServiceModel> services,
  required Future<void> Function({
    required String clientName,
    required ServiceModel service,
    required DateTime startTime,
  }) onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => WalkInSheet(
      selectedDay: selectedDay,
      services: services,
      onSubmit: onSubmit,
    ),
  );
}
