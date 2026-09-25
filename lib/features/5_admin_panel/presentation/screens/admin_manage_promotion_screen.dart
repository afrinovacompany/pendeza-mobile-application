import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_ui.dart';
import 'package:pendeza/shared/models/promotion_model.dart';
import 'package:pendeza/shared/widgets/custom_snackbar.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/text_form_field.dart';

class AdminManagePromotionsScreen extends StatelessWidget {
  const AdminManagePromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final loaded = state is AdminLoaded ? state : null;
        final promotions = loaded?.promotions ?? const <PromotionModel>[];

        return AdminPage(
          title: 'Promotions',
          subtitle: loaded == null
              ? null
              : '${promotions.length} total · '
                  '${promotions.where((p) => p.isActive).length} active',
          icon: CupertinoIcons.tag_fill,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _showAddPromotionDialog(context, context.read<AdminBloc>()),
            icon: const Icon(CupertinoIcons.add),
            label: Text(
              'New promotion',
              style: AdminTheme.body(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          child: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminState state) {
    if (state is AdminLoading || state is AdminInitial) {
      return const AdminLoadingState(itemHeight: 220, count: 3);
    }
    if (state is AdminError) {
      return AdminErrorState(
        message: state.message,
        onRetry: () => context.read<AdminBloc>().add(LoadAdminData()),
      );
    }
    if (state is! AdminLoaded) return const SizedBox.shrink();

    if (state.promotions.isEmpty) {
      return AdminEmptyState(
        icon: CupertinoIcons.tag,
        title: 'No promotions yet',
        message: 'Create a promotion to engage users.',
        actionLabel: 'Create promotion',
        onAction: () =>
            _showAddPromotionDialog(context, context.read<AdminBloc>()),
      );
    }

    return _PromotionsList(
      promotions: state.promotions,
      adminBloc: context.read<AdminBloc>(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LIST + CARD
// ═════════════════════════════════════════════════════════════════════════════

class _PromotionsList extends StatelessWidget {
  final List<PromotionModel> promotions;
  final AdminBloc adminBloc;

  const _PromotionsList({required this.promotions, required this.adminBloc});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AdminTheme.gutter(width);
    final columns = width >= 1100 ? 3 : (width >= 720 ? 2 : 1);
    final rowCount = (promotions.length / columns).ceil();

    return ListView.builder(
      // Leave room for the extended FAB.
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 96),
      itemCount: rowCount,
      itemBuilder: (context, row) {
        final children = <Widget>[];
        for (var c = 0; c < columns; c++) {
          final index = row * columns + c;
          if (c > 0) children.add(const SizedBox(width: 12));
          children.add(
            Expanded(
              child: index < promotions.length
                  ? _PromotionCard(
                      promo: promotions[index],
                      adminBloc: adminBloc,
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionModel promo;
  final AdminBloc adminBloc;

  const _PromotionCard({required this.promo, required this.adminBloc});

  bool get _expired => promo.endDate.isBefore(DateTime.now());

  String? get _discountLabel {
    final value = promo.discountValue;
    switch (promo.discountType) {
      case DiscountType.percentage:
        if (value == null) return null;
        final text = value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(1);
        return '$text% off';
      case DiscountType.fixedAmount:
        if (value == null) return null;
        return 'TZS ${NumberFormat.decimalPattern().format(value)} off';
      case DiscountType.freebie:
        return 'Free add-on';
      case DiscountType.none:
        return null;
    }
  }

  String? get _actionLabel {
    switch (promo.action) {
      case PromotionAction.openDiscover:
        return 'Opens Discover';
      case PromotionAction.openCategory:
        return 'Opens category';
      case PromotionAction.openSalon:
        return 'Opens salon';
      case PromotionAction.openUrl:
        return 'Opens link';
      case PromotionAction.none:
        return null;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete promotion?',
      message: '"${promo.title}" will be removed for everyone. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      tone: AdminTone.danger,
      icon: CupertinoIcons.trash_fill,
    );
    if (confirmed) adminBloc.add(DeletePlatformPromotion(promo.id));
  }

  @override
  Widget build(BuildContext context) {
    final dates = DateFormat('d MMM');
    final discount = _discountLabel;
    final action = _actionLabel;

    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 8,
                child: promo.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: promo.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            ColoredBox(color: AdminTheme.inset(context)),
                        errorWidget: (_, _, _) => const _BannerFallback(),
                      )
                    : const _BannerFallback(),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AdminTheme.card(context),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: AdminPill(
                    label: _expired
                        ? 'Expired'
                        : (promo.isActive ? 'Active' : 'Inactive'),
                    tone: _expired
                        ? AdminTone.danger
                        : (promo.isActive
                            ? AdminTone.success
                            : AdminTone.neutral),
                  ),
                ),
              ),
            ],
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.heading(context),
                ),
                if (promo.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    promo.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTheme.caption(context),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (discount != null)
                      AdminPill(
                        label: discount,
                        tone: AdminTone.success,
                        icon: CupertinoIcons.percent,
                      ),
                    if (promo.promoCode != null)
                      AdminPill(
                        label: promo.promoCode!,
                        tone: AdminTone.info,
                        icon: CupertinoIcons.ticket_fill,
                      ),
                    if (action != null)
                      AdminPill(
                        label: action,
                        tone: AdminTone.accent,
                        icon: CupertinoIcons.arrow_turn_up_right,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 13,
                      color: AdminTheme.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${dates.format(promo.startDate)} – '
                      '${dates.format(promo.endDate)}',
                      style: AdminTheme.caption(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddPromotionDialog(
                          context,
                          adminBloc,
                          promotion: promo,
                        ),
                        icon: const Icon(CupertinoIcons.pencil, size: 16),
                        label: const Text('Edit'),
                        style: AdminTheme.outlinedButton(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(CupertinoIcons.trash, size: 18),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(46, 46),
                        backgroundColor:
                            AdminTheme.toneTint(context, AdminTone.danger),
                        foregroundColor:
                            AdminTheme.toneInk(context, AdminTone.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: Icon(
          CupertinoIcons.tag_fill,
          size: 40,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ADD / EDIT DIALOG
// ═════════════════════════════════════════════════════════════════════════════

void _showAddPromotionDialog(
  BuildContext context,
  AdminBloc adminBloc, {
  PromotionModel? promotion,
}) {
  showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: adminBloc,
      child: _AddPromotionDialog(promotion: promotion),
    ),
  );
}

class _AddPromotionDialog extends StatefulWidget {
  final PromotionModel? promotion;
  const _AddPromotionDialog({this.promotion});

  @override
  State<_AddPromotionDialog> createState() => _AddPromotionDialogState();
}

class _AddPromotionDialogState extends State<_AddPromotionDialog> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Discount Info
  final _codeController = TextEditingController();
  DiscountType _discountType = DiscountType.percentage;
  final _discountValueController = TextEditingController();

  // Action Info
  PromotionAction _action = PromotionAction.none;
  final _actionValueController = TextEditingController();

  XFile? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      final p = widget.promotion!;
      _titleController.text = p.title;
      _descController.text = p.description;
      _codeController.text = p.promoCode ?? '';
      _discountType = p.discountType;
      _discountValueController.text = p.discountValue?.toString() ?? '';
      _action = p.action;
      _actionValueController.text = p.actionValue ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _codeController.dispose();
    _discountValueController.dispose();
    _actionValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _image = image);
    }
  }

  void _submit() {
    // If editing, image is optional (can use existing). If new, image is required.
    if (_formKey.currentState!.validate() &&
        (_image != null || widget.promotion != null)) {
      setState(() => _isLoading = true);

      // Parse discount value safely
      double? discountVal;
      if (_discountValueController.text.isNotEmpty) {
        discountVal = double.tryParse(_discountValueController.text);
      }

      // Create new PromotionModel
      final promo = PromotionModel(
        id: widget.promotion?.id ?? '', // Placeholder if new
        type: PromotionType.platform,
        title: _titleController.text,
        description: _descController.text,
        imageUrl: widget.promotion?.imageUrl ?? '',
        promoCode:
            _codeController.text.isNotEmpty ? _codeController.text : null,

        // Advanced Discount Logic
        discountType: _discountType,
        discountValue: discountVal,

        // Advanced Action Logic
        action: _action,
        actionValue: _actionValueController.text.isNotEmpty
            ? _actionValueController.text
            : null,

        startDate: widget.promotion?.startDate ?? DateTime.now(),
        endDate: widget.promotion?.endDate ??
            DateTime.now().add(const Duration(days: 30)),
        createdAt: widget.promotion?.createdAt ?? DateTime.now(),
        isActive: widget.promotion?.isActive ?? true,
      );

      if (widget.promotion == null) {
        context.read<AdminBloc>().add(AddPlatformPromotion(
              promotion: promo,
              imagePath: _image!.path,
            ));
      } else {
        context.read<AdminBloc>().add(UpdatePlatformPromotion(
              promotion: promo,
              imagePath: _image?.path,
            ));
      }
    } else if (_image == null && widget.promotion == null) {
      CustomSnackBar.show(
        context,
        message: 'Please select an image',
        type: SnackBarType.warning,
      );
    }
  }

  String _discountTypeLabel(DiscountType type) {
    switch (type) {
      case DiscountType.percentage:
        return 'Percentage';
      case DiscountType.fixedAmount:
        return 'Fixed amount';
      case DiscountType.freebie:
        return 'Freebie';
      case DiscountType.none:
        return 'No discount';
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.promotion != null;

    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminLoaded) {
          Navigator.of(context).pop();
        }
        if (state is AdminError) {
          setState(() => _isLoading = false);
          CustomSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.error,
          );
        }
      },
      child: Dialog(
        backgroundColor: AdminTheme.card(context),
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
                child: Row(
                  children: [
                    AdminIconTile(
                      icon: editing
                          ? CupertinoIcons.pencil
                          : CupertinoIcons.sparkles,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        editing ? 'Edit promotion' : 'New promotion',
                        style: AdminTheme.heading(context)
                            .copyWith(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(CupertinoIcons.xmark, size: 18),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImagePicker(context),
                        const SizedBox(height: 22),
                        Text('BASIC INFO', style: AdminTheme.label(context)),
                        const SizedBox(height: 10),
                        CustomTextFormField(
                          controller: _titleController,
                          labelText: 'Title (e.g., Summer Sale)',
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        CustomTextFormField(
                          controller: _descController,
                          labelText: 'Description',
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 22),
                        Text('DISCOUNT', style: AdminTheme.label(context)),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _LabeledField(
                                label: 'Type',
                                child: DropdownButtonFormField<DiscountType>(
                                  initialValue: _discountType,
                                  isExpanded: true,
                                  items: [
                                    for (final e in DiscountType.values)
                                      DropdownMenuItem(
                                        value: e,
                                        child: Text(_discountTypeLabel(e)),
                                      ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _discountType = v!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextFormField(
                                controller: _discountValueController,
                                labelText: 'Value',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextFormField(
                          controller: _codeController,
                          labelText: 'Promo code (optional)',
                        ),
                        const SizedBox(height: 22),
                        Text('ON TAP', style: AdminTheme.label(context)),
                        const SizedBox(height: 10),
                        _LabeledField(
                          label: 'Navigate to',
                          child: DropdownButtonFormField<PromotionAction>(
                            initialValue: _action,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: PromotionAction.none,
                                child: Text('No action'),
                              ),
                              DropdownMenuItem(
                                value: PromotionAction.openDiscover,
                                child: Text('Open Discovery'),
                              ),
                              DropdownMenuItem(
                                value: PromotionAction.openCategory,
                                child: Text('Open Category'),
                              ),
                              DropdownMenuItem(
                                value: PromotionAction.openSalon,
                                child: Text('Open Salon'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _action = v!),
                          ),
                        ),
                        if (_action == PromotionAction.openCategory ||
                            _action == PromotionAction.openSalon) ...[
                          const SizedBox(height: 12),
                          CustomTextFormField(
                            controller: _actionValueController,
                            labelText: _action == PromotionAction.openCategory
                                ? 'Category ID (e.g., massage, nails)'
                                : 'Salon ID (from database)',
                            validator: (v) => v?.isEmpty == true
                                ? 'Required for this action'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: AdminTheme.textButton(context,
                          tone: AdminTone.neutral),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryGradientButton(
                        onPressed: _submit,
                        text: editing ? 'Save changes' : 'Create promotion',
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final existingUrl = widget.promotion?.imageUrl ?? '';
    final hasImage = _image != null || existingUrl.isNotEmpty;

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AdminTheme.inset(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.border(context)),
          image: _image != null
              ? DecorationImage(
                  image: FileImage(File(_image!.path)),
                  fit: BoxFit.cover,
                )
              : (existingUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(existingUrl),
                      fit: BoxFit.cover,
                    )
                  : null),
        ),
        child: hasImage
            ? Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AdminTheme.card(context),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.photo_on_rectangle, size: 14),
                          SizedBox(width: 6),
                          Text('Change',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AdminIconTile(
                    icon: CupertinoIcons.photo_on_rectangle,
                    size: 44,
                    tone: AdminTone.primary,
                  ),
                  const SizedBox(height: 10),
                  Text('Add a banner image', style: AdminTheme.body(context)),
                  Text('Tap to choose from your gallery',
                      style: AdminTheme.caption(context)),
                ],
              ),
      ),
    );
  }
}

/// Caption-above-field wrapper matching [CustomTextFormField]'s layout, so
/// dropdowns and text fields line up in the same form.
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
