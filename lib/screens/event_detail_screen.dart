import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/avatar_stack.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  Event? _event;
  bool _loading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _event = await _eventService.getEvent(widget.eventId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openDirections() async {
    if (_event == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_event!.latitude},${_event!.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await _eventService.joinEvent(widget.eventId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _joining = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Event not found')),
      );
    }

    final ev = _event!;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('EEE, MMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');
    final muted = theme.colorScheme.onSurfaceVariant;
    final fillPct = ev.maxParticipants > 0
        ? ev.participantCount / ev.maxParticipants
        : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              slivers: [
              SliverToBoxAdapter(child: _heroImage(ev, theme)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: Column(
                      children: [
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ev.interestTag != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: kGradientPurplePink,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(ev.interestTag!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),

                            Text(ev.title,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold)),
                            const SizedBox(height: 14),

                            _infoRow(Icons.calendar_today,
                                dateFmt.format(ev.startTime.toLocal()),
                                muted),
                            _infoRow(Icons.access_time,
                                timeFmt.format(ev.startTime.toLocal()),
                                muted),
                            if (ev.distanceMeters != null)
                              _infoRow(
                                  Icons.place,
                                  '${(ev.distanceMeters! / 1000).toStringAsFixed(1)} km away',
                                  muted),
                            const SizedBox(height: 16),

                            Divider(color: theme.colorScheme.outline),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Participants',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: muted)),
                                Text(
                                    '${ev.participantCount} / ${ev.maxParticipants}',
                                    style: TextStyle(
                                        fontSize: 13, color: muted)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AvatarStack(
                                totalCount: ev.participantCount,
                                max: 8,
                                size: 36),
                            const SizedBox(height: 14),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: fillPct,
                                minHeight: 8,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        kGradientPurple),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (ev.creator != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          ev.creator!.profilePicture !=
                                                  null
                                              ? NetworkImage(ev.creator!
                                                  .profilePicture!)
                                              : null,
                                      child:
                                          ev.creator!.profilePicture ==
                                                  null
                                              ? const Icon(Icons.person)
                                              : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Hosted by',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: muted)),
                                        Text(ev.creator!.name,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      if (ev.description != null) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('About',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(ev.description!,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: muted,
                                      height: 1.6)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Location',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                height: 140,
                                child: IgnorePointer(
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(ev.latitude, ev.longitude),
                                      initialZoom: 15,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.example.event_discovery',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(ev.latitude, ev.longitude),
                                            width: 40,
                                            height: 40,
                                            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openDirections,
                                icon: const Icon(Icons.directions, size: 18),
                                label: const Text('Get Directions'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kGradientPurple,
                                  side: BorderSide(
                                    color: kGradientPurple.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),

          _fixedBottomCTA(theme),
        ],
      ),
    );
  }

  Widget _heroImage(Event ev, ThemeData theme) {
    final height = MediaQuery.of(context).size.height * 0.42;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ev.coverImage != null
              ? Image.network(ev.coverImage!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _heroPlaceholder())
              : _heroPlaceholder(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  theme.colorScheme.surface.withValues(alpha: 0.2),
                  theme.colorScheme.surface,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          if (ev.isLive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Center(
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: kLiveRed, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text('LIVE NOW',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleButton(Icons.arrow_back, () => Navigator.pop(context)),
                Row(
                  children: [
                    _circleButton(Icons.share, () {}),
                    const SizedBox(width: 8),
                    _circleButton(Icons.bookmark_border, () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kGradientPurple.withValues(alpha: 0.5),
            kGradientPink.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: const Icon(Icons.event, size: 60, color: Colors.white38),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color muted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 14, color: muted)),
        ],
      ),
    );
  }

  Widget _fixedBottomCTA(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isJoined = _event?.isUserParticipant ?? false;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A24).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.7),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: GradientButton(
          label: isJoined ? 'Joined' : 'Join Event',
          icon: isJoined ? Icons.check_circle : null,
          isLoading: _joining,
          onPressed: isJoined ? null : _join,
        ),
      ),
    );
  }
}
