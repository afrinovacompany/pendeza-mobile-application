import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';
import 'package:pendeza/shared/models/promotion_model.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/text_form_field.dart';

class AdminManagePromotionsScreen extends StatelessWidget {
  const AdminManagePromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Platform Promotions'),
        backgroundColor:
        isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
        elevation: 1,
      ),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : theme.scaffoldBackgroundColor.withAlpha(245),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppConstants.padM),
                  Text(state.message),
                  const SizedBox(height: AppConstants.padM),
                  ElevatedButton(
                    onPressed: () => context.read<AdminBloc>().add(LoadAdminData()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AdminLoaded) {
            if (state.promotions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: AppConstants.padM),
                    Text(
                      'No promotions yet',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: AppConstants.padS),
                    Text(
                      'Create a promotion to engage users',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }
            return _PromotionsList(promotions: state.promotions, adminBloc: context.read<AdminBloc>());
          }
          return const Center(child: Text('Unknown state.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPromotionDialog(context, context.read<AdminBloc>()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PromotionsList extends StatelessWidget {
  final List<PromotionModel> promotions;
  final AdminBloc adminBloc;

  const _PromotionsList({required this.promotions, required this.adminBloc});

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) {
      return const Center(child: Text('No active promotions.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padM),
      itemCount: promotions.length,
      itemBuilder: (context, index) {
        final promo = promotions[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: AppConstants.padM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (promo.imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: promo.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox(
                    height: 150,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ListTile(
                title: Text(promo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(promo.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(promo.isActive ? 'Active' : 'Inactive'),
                          backgroundColor: promo.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                          labelStyle: TextStyle(color: promo.isActive ? Colors.green : Colors.grey, fontSize: 10),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        if (promo.promoCode != null)
                          Chip(
                            label: Text('Code: ${promo.promoCode}'),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(color: Colors.blue, fontSize: 10),
                          ),
                        if (promo.action != PromotionAction.none)
                          Chip(
                            label: Text('Action: ${promo.action.name.split('.').last}'),
                            backgroundColor: Colors.orange.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(color: Colors.orange, fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _showAddPromotionDialog(context, adminBloc, promotion: promo);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        // Confirm delete
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Promotion?'),
                            content: const Text('This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  adminBloc.add(DeletePlatformPromotion(promo.id));
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showAddPromotionDialog(BuildContext context, AdminBloc adminBloc, {PromotionModel? promotion}) {
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

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _image = image);
    }
  }

  void _submit() {
    // If editing, image is optional (can use existing). If new, image is required.
    if (_formKey.currentState!.validate() && (_image != null || widget.promotion != null)) {
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
        promoCode: _codeController.text.isNotEmpty ? _codeController.text : null,

        // Advanced Discount Logic
        discountType: _discountType,
        discountValue: discountVal,

        // Advanced Action Logic
        action: _action,
        actionValue: _actionValueController.text.isNotEmpty ? _actionValueController.text : null,

        startDate: widget.promotion?.startDate ?? DateTime.now(),
        endDate: widget.promotion?.endDate ?? DateTime.now().add(const Duration(days: 30)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminLoaded) {
          Navigator.of(context).pop();
        }
        if (state is AdminError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: AlertDialog(
        title: Text(widget.promotion == null ? 'New Promotion' : 'Edit Promotion'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- IMAGE PICKER ---
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      image: _image != null
                          ? DecorationImage(image: FileImage(File(_image!.path)), fit: BoxFit.cover)
                          : (widget.promotion?.imageUrl.isNotEmpty == true
                              ? DecorationImage(image: NetworkImage(widget.promotion!.imageUrl), fit: BoxFit.cover)
                              : null),
                    ),
                    child: (_image == null && (widget.promotion?.imageUrl.isEmpty ?? true))
                        ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey))
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // --- BASIC INFO ---
                const Text('Basic Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                CustomTextFormField(
                  controller: _titleController,
                  labelText: 'Title (e.g., Summer Sale)',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: _descController,
                  labelText: 'Description',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),

                const Divider(height: 30),

                // --- DISCOUNT LOGIC ---
                const Text('Discount Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<DiscountType>(
                        initialValue: _discountType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: DiscountType.values.map((e) {
                          return DropdownMenuItem(value: e, child: Text(e.name));
                        }).toList(),
                        onChanged: (v) => setState(() => _discountType = v!),
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
                  labelText: 'Promo Code (Optional)',
                ),

                const Divider(height: 30),

                // --- ACTION LOGIC ---
                const Text('On Tap Action', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                DropdownButtonFormField<PromotionAction>(
                  initialValue: _action,
                  decoration: const InputDecoration(labelText: 'Navigate To'),
                  items: const [
                    DropdownMenuItem(value: PromotionAction.none, child: Text('No Action')),
                    DropdownMenuItem(value: PromotionAction.openDiscover, child: Text('Open Discovery')),
                    DropdownMenuItem(value: PromotionAction.openCategory, child: Text('Open Category')),
                    DropdownMenuItem(value: PromotionAction.openSalon, child: Text('Open Salon')),
                  ],
                  onChanged: (v) => setState(() => _action = v!),
                ),
                if (_action == PromotionAction.openCategory || _action == PromotionAction.openSalon) ...[
                  const SizedBox(height: 12),
                  CustomTextFormField(
                    controller: _actionValueController,
                    labelText: _action == PromotionAction.openCategory
                        ? 'Category ID (e.g., massage, nails)'
                        : 'Salon ID (from database)',
                    validator: (v) => v?.isEmpty == true ? 'Required for this action' : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          PrimaryGradientButton(
            onPressed: _submit,
            text: widget.promotion == null ? 'Create Promotion' : 'Save Changes',
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}