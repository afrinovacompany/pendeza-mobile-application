import 'package:flutter/material.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

class AdminSalonListItem extends StatelessWidget {
  final SalonModel salon;
  const AdminSalonListItem({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ProfileAvatar(
        imageUrl: salon.primaryImage,
        fullName: salon.salonName,
        radius: 20,
      ),
      title: Text(salon.salonName),
      subtitle: Text(salon.address),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // TODO: Navigate to a detailed admin salon view
      },
    );
  }
}