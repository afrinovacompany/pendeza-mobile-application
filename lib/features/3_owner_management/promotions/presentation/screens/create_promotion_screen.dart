import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/payment_service.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/services/firestore_service.dart'; // 🔥 ADD THIS
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/shared/models/promotion_model.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/text_form_field.dart';
import '../bloc/owner_promotions_bloc.dart';
import '../bloc/owner_promotions_event.dart';
import '../bloc/owner_promotions_state.dart';
import '../widgets/payment_webview.dart';

class CreatePromotionScreen extends StatefulWidget {
  final String? salonId; // 🔥 MAKE IT OPTIONAL (nullable)

  const CreatePromotionScreen({
    super.key,
    this.salonId, // 🔥 OPTIONAL - will be fetched if not provided
  });

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _discountValueController = TextEditingController();

  // State
  XFile? _imageFile;
  DiscountType _discountType = DiscountType.percentage;
  DateTimeRange? _dateRange;
  bool _isBoostEnabled = false;
  bool _isLoading = false;

  // 🔥 NEW: Salon ID state
  String? _cachedSalonId;
  bool _isFetchingSalonId = false;

  // Constants
  static const double _boostPrice = 10000.0;

  @override
  void initState() {
    super.initState();
    _cachedSalonId = widget.salonId; // Use provided ID if available
    if (_cachedSalonId == null) {
      _fetchSalonId(); // Fetch it if not provided
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  // 🔥 NEW: Fetch salon ID from Firestore
  Future<void> _fetchSalonId() async {
    if (_isFetchingSalonId) return;

    setState(() => _isFetchingSalonId = true);

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final salon = await sl<FirestoreService>().getSalonForOwner(
        ownerId: authState.user.uid,
      );

      if (salon == null) {
        throw Exception('No salon found for this owner');
      }

      setState(() {
        _cachedSalonId = salon.id;
        _isFetchingSalonId = false;
      });
    } catch (e) {
      setState(() => _isFetchingSalonId = false);
      if (mounted) {
        _showError('Failed to load salon data: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _handleSubmit() {
    // 🔥 VALIDATE SALON ID FIRST
    if (_cachedSalonId == null) {
      _showError('Salon ID not available. Please try again.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showError('Please select an image');
      return;
    }
    if (_dateRange == null) {
      _showError('Please select dates');
      return;
    }

    final double? discountVal = double.tryParse(_discountValueController.text);

    final promotion = PromotionModel(
      id: '',
      type: PromotionType.salon,
      title: _titleController.text,
      description: _descController.text,
      imageUrl: '',
      discountType: _discountType,
      discountValue: discountVal,
      promoCode: null,
      startDate: _dateRange!.start,
      endDate: _dateRange!.end,
      createdAt: DateTime.now(),
      isActive: true,
      isFeatured: false,
    );

    if (_isBoostEnabled) {
      _handlePayByLink(promotion);
    } else {
      _createDirectly(promotion);
    }
  }

  void _createDirectly(PromotionModel promotion) {
    context.read<OwnerPromotionsBloc>().add(
      CreateSalonPromotion(
        salonId: _cachedSalonId!, // 🔥 USE CACHED ID
        promotion: promotion,
        imageFile: File(_imageFile!.path),
        shouldBoost: false,
      ),
    );
  }

  Future<void> _handlePayByLink(PromotionModel promotion) async {
    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthBloc>().state;
      String name = 'Owner';
      String email = 'owner@pendeza.app';
      String phone = '255000000000';

      if (authState is Authenticated) {
        name = authState.user.fullName;
        email = authState.user.email;
        phone = (authState.user.phoneNumber ?? '255000000000').replaceAll('+', '');
      }

      final orderId = 'BOOST-${DateTime.now().millisecondsSinceEpoch}';

      final paymentService = sl<PaymentService>();
      final paymentLink = await paymentService.createPaymentLink(
        orderId: orderId,
        amount: _boostPrice,
        name: name,
        email: email,
        phone: phone,
      );

      if (!mounted) return;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebView(
            paymentUrl: paymentLink,
            title: 'Pay to Boost',
          ),
        ),
      );

      if (result == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifying payment...')),
        );

        final isConfirmed = await paymentService.verifyTransaction(orderId);

        if (isConfirmed) {
          if (!mounted) return;
          context.read<OwnerPromotionsBloc>().add(
            CreateSalonPromotion(
              salonId: _cachedSalonId!, // 🔥 USE CACHED ID
              promotion: promotion.copyWith(isFeatured: true),
              imageFile: File(_imageFile!.path),
            ),
          );
        } else {
          _showError('Payment verification failed. Order ID: $orderId');
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Payment initialization failed: $e');
    }
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 SHOW LOADING IF FETCHING SALON ID
    if (_isFetchingSalonId || _cachedSalonId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Promotion')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading salon information...'),
            ],
          ),
        ),
      );
    }

    return BlocListener<OwnerPromotionsBloc, OwnerPromotionsState>(
      listener: (context, state) {
        if (state is OwnerPromotionsLoading) {
          setState(() => _isLoading = true);
        } else if (state is PromotionOperationSuccess) {
          setState(() => _isLoading = false);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        } else if (state is OwnerPromotionsError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Promotion')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: AppConstants.radiusM,
                      image: _imageFile != null
                          ? DecorationImage(
                        image: FileImage(File(_imageFile!.path)),
                        fit: BoxFit.cover,
                      )
                          : null,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _imageFile == null
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Add Cover Image', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: AppConstants.padL),

                // Basic Info
                CustomTextFormField(
                  controller: _titleController,
                  labelText: 'Title (e.g., Summer Glow)',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: AppConstants.padM),
                CustomTextFormField(
                  controller: _descController,
                  labelText: 'Description',
                  maxLines: 3,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: AppConstants.padL),

                // Discount Section
                const Text('Discount Details', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppConstants.padS),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<DiscountType>(
                      initialValue: _discountType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: DiscountType.values
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name.toUpperCase()),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _discountType = v!),
                    ),
                    const SizedBox(height: AppConstants.padM),
                    CustomTextFormField(
                      controller: _discountValueController,
                      labelText: _discountType == DiscountType.percentage
                          ? 'Percent (%)'
                          : 'Amount (TZS)',
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.padL),

                // Date Picker
                InkWell(
                  onTap: _pickDateRange,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dateRange == null
                          ? 'Select Dates'
                          : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.padL),

                // Monetization Toggle
                Container(
                  padding: const EdgeInsets.all(AppConstants.padM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: AppConstants.radiusM,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Boost Visibility',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'Feature on home screen for 7 days (10,000 TZS)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isBoostEnabled,
                        onChanged: (val) => setState(() => _isBoostEnabled = val),
                        activeThumbColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.padXL),

                // Submit Button
                PrimaryGradientButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  text: _isBoostEnabled ? 'Pay & Create' : 'Create Promotion',
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppConstants.padL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}