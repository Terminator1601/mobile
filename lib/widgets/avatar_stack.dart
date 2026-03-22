import 'package:flutter/material.dart';

import '../main.dart';

class AvatarStack extends StatelessWidget {
  final int totalCount;
  final int max;
  final double size;
  final List<String?> avatarUrls;

  const AvatarStack({
    super.key,
    required this.totalCount,
    this.max = 4,
    this.size = 36,
    this.avatarUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final displayed = totalCount.clamp(0, max);
    final remaining = totalCount - displayed;

    return SizedBox(
      height: size,
      width: displayed * (size - 10) + (remaining > 0 ? size - 10 : 0) + 10,
      child: Stack(
        children: [
          for (var i = 0; i < displayed; i++)
            Positioned(
              left: i * (size - 10),
              child: _avatar(context, i),
            ),
          if (remaining > 0)
            Positioned(
              left: displayed * (size - 10),
              child: _overflowBadge(remaining),
            ),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context, int index) {
    final url = index < avatarUrls.length ? avatarUrls[index] : null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
        gradient: kGradientPurplePink,
      ),
      child: ClipOval(
        child: url != null
            ? Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderIcon())
            : _placeholderIcon(),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      decoration: const BoxDecoration(gradient: kGradientPurplePink),
      child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
    );
  }

  Widget _overflowBadge(int remaining) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: kGradientPurplePink,
      ),
      alignment: Alignment.center,
      child: Text(
        '+$remaining',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.33,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
