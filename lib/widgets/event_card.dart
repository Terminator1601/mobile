import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/event.dart';
import 'avatar_stack.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateFmt = DateFormat('h:mm a');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'event-${event.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: event.coverImage != null
                    ? Image.network(
                        event.coverImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.interestTag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        gradient: kGradientPurplePink,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        event.interestTag!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: muted),
                      const SizedBox(width: 4),
                      Text(dateFmt.format(event.startTime.toLocal()),
                          style: TextStyle(fontSize: 11, color: muted)),
                      if (event.distanceMeters != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('·',
                              style: TextStyle(fontSize: 11, color: muted)),
                        ),
                        Icon(Icons.place, size: 12, color: muted),
                        const SizedBox(width: 2),
                        Text(
                          '${(event.distanceMeters! / 1000).toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      AvatarStack(
                        totalCount: event.participantCount,
                        max: 3,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${event.participantCount}/${event.maxParticipants}',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                      if (event.averageRating != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text('${event.averageRating}',
                            style: TextStyle(fontSize: 11, color: muted)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kGradientPurple.withValues(alpha: 0.3),
            kGradientPink.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.event, color: Colors.white54, size: 32),
    );
  }
}
