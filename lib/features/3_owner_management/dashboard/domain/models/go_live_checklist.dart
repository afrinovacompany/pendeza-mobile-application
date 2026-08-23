import 'package:equatable/equatable.dart';

import '../../../../../shared/models/salon_model.dart';
import '../../../../../shared/models/service_model.dart';

/// Listing readiness for an owner salon.
class GoLiveChecklist extends Equatable {
  final bool hasPhoto;
  final bool hasHours;
  final bool hasPhone;
  final bool hasService;
  final String verificationStatus;
  final String? rejectionReason;

  const GoLiveChecklist({
    required this.hasPhoto,
    required this.hasHours,
    required this.hasPhone,
    required this.hasService,
    required this.verificationStatus,
    this.rejectionReason,
  });

  bool get isComplete => hasPhoto && hasHours && hasPhone && hasService;

  bool get isPending => verificationStatus == 'pending';

  bool get isApproved => verificationStatus == 'approved';

  bool get isRejected => verificationStatus == 'rejected';

  /// Clients can discover/book only when approved.
  bool get isListed => isApproved;

  @override
  List<Object?> get props => [
        hasPhoto,
        hasHours,
        hasPhone,
        hasService,
        verificationStatus,
        rejectionReason,
      ];

  factory GoLiveChecklist.from({
    required SalonModel salon,
    required Iterable<ServiceModel> services,
  }) {
    final hasPhoto = (salon.primaryImage != null &&
            salon.primaryImage!.trim().isNotEmpty) ||
        (salon.imageGallery != null && salon.imageGallery!.isNotEmpty);
    final hasPhone =
        (salon.phoneNumber != null && salon.phoneNumber!.trim().isNotEmpty) ||
        (salon.whatsappNumber != null &&
            salon.whatsappNumber!.trim().isNotEmpty);

    return GoLiveChecklist(
      hasPhoto: hasPhoto,
      hasHours: salon.hasBusinessHours,
      hasPhone: hasPhone,
      hasService: services.any((s) => s.isActive),
      verificationStatus: salon.verificationStatus,
      rejectionReason: salon.rejectionReason,
    );
  }
}
