import 'package:flutter/material.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

/// A wrapper that groups [ProfileMenuTile]s into a visually distinct card.
class ProfileSectionCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileSectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                // Line up with the text, not the icon.
                padding: const EdgeInsets.only(left: 72, right: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: ClientTheme.border(context).withValues(alpha: 0.6),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
