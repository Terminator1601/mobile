import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/event.dart';
import '../models/comment.dart';
import '../services/app_state.dart';
import '../services/event_service.dart';
import '../services/comment_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/avatar_stack.dart';
import 'create_event_screen.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  final CommentService _commentService = CommentService();
  Event? _event;
  bool _loading = true;
  bool _joining = false;
  bool _leaving = false;
  bool _bookmarking = false;
  bool _isBookmarked = false;

  List<Comment> _comments = [];
  final TextEditingController _commentCtrl = TextEditingController();
  bool _postingComment = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _event = await _eventService.getEvent(widget.eventId);
      _isBookmarked = _event?.isBookmarked ?? false;
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadComments() async {
    try {
      _comments = await _commentService.getComments(widget.eventId);
    } catch (_) {}
    if (mounted) setState(() {});
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

  Future<void> _openMediaUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  Future<void> _leave() async {
    setState(() => _leaving = true);
    try {
      await _eventService.leaveEvent(widget.eventId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left the event')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _leaving = false);
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarking) return;
    setState(() => _bookmarking = true);
    try {
      final result = await _eventService.toggleBookmark(widget.eventId);
      setState(() => _isBookmarked = result);
    } catch (_) {}
    if (mounted) setState(() => _bookmarking = false);
  }

  void _share() {
    if (_event == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: 'Check out this event: ${_event!.title}\nhttps://eventexplorer.app/events/${_event!.id}',
      ),
    );
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _postingComment = true);
    try {
      await _commentService.createComment(widget.eventId, text);
      _commentCtrl.clear();
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _postingComment = false);
  }

  void _openChat() {
    if (_event == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        eventId: widget.eventId,
        eventTitle: _event!.title,
      ),
    ));
  }

  bool get _isCreator {
    final user = context.read<AppState>().currentUser;
    return user != null && _event != null && _event!.createdBy == user.id;
  }

  void _showCreatorMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Event'),
              onTap: () {
                Navigator.pop(ctx);
                _editEvent();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Delete Event', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editEvent() async {
    if (_event == null) return;
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => CreateEventScreen(editingEvent: _event),
    ));
    if (result == true) _load();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _eventService.deleteEvent(widget.eventId);
                if (mounted) Navigator.of(context).pop(true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openCreatorProfile() {
    if (_event?.creator == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => UserProfileScreen(userId: _event!.creator!.id),
    ));
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (ev.interestTag != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    margin: const EdgeInsets.only(right: 8),
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
                                if (ev.averageRating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${ev.averageRating} (${ev.reviewCount})',
                                        style: TextStyle(fontSize: 12, color: muted),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Text(ev.title,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 14),

                            _infoRow(Icons.calendar_today,
                                dateFmt.format(ev.startTime.toLocal()), muted),
                            _infoRow(Icons.access_time,
                                timeFmt.format(ev.startTime.toLocal()), muted),
                            if (ev.distanceMeters != null)
                              _infoRow(
                                  Icons.place,
                                  '${(ev.distanceMeters! / 1000).toStringAsFixed(1)} km away',
                                  muted),
                            const SizedBox(height: 16),

                            Divider(color: theme.colorScheme.outline),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Participants',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: muted)),
                                Text(
                                    '${ev.participantCount} / ${ev.maxParticipants}',
                                    style: TextStyle(fontSize: 13, color: muted)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AvatarStack(totalCount: ev.participantCount, max: 8, size: 36),
                            const SizedBox(height: 14),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: fillPct,
                                minHeight: 8,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: const AlwaysStoppedAnimation<Color>(kGradientPurple),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (ev.creator != null)
                              GestureDetector(
                                onTap: _openCreatorProfile,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage:
                                            ev.creator!.profilePicture != null
                                                ? NetworkImage(ev.creator!.profilePicture!)
                                                : null,
                                        child: ev.creator!.profilePicture == null
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Hosted by',
                                              style: TextStyle(fontSize: 11, color: muted)),
                                          Text(ev.creator!.name,
                                              style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            if (ev.isUserParticipant) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _openChat,
                                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                  label: const Text('Event Chat'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kGradientPurple,
                                    side: BorderSide(color: kGradientPurple.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
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
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(ev.description!,
                                  style: TextStyle(
                                      fontSize: 14, color: muted, height: 1.6)),
                            ],
                          ),
                        ),
                      ],
                      if (ev.mediaUrls.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Media',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Column(
                                children: ev.mediaUrls
                                    .map((url) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: _mediaTile(url, theme),
                                        ))
                                    .toList(),
                              ),
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
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.example.event_discovery',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(ev.latitude, ev.longitude),
                                            width: 40,
                                            height: 40,
                                            child: const Icon(Icons.location_pin,
                                                color: Colors.red, size: 40),
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

                      const SizedBox(height: 16),
                      _buildCommentsSection(theme, muted),
                    ],
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

  Widget _buildCommentsSection(ThemeData theme, Color muted) {
    final user = context.watch<AppState>().currentUser;
    final relFmt = DateFormat('MMM d, h:mm a');

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comments (${_comments.length})',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (user != null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                _postingComment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.send, color: kGradientPurple),
                        onPressed: _postComment,
                      ),
              ],
            ),
          if (_comments.isNotEmpty) const SizedBox(height: 12),
          ..._comments.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: c.user.profilePicture != null
                          ? NetworkImage(c.user.profilePicture!)
                          : null,
                      child: c.user.profilePicture == null
                          ? const Icon(Icons.person, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(c.user.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                              const SizedBox(width: 6),
                              Text(relFmt.format(c.createdAt.toLocal()),
                                  style: TextStyle(
                                      fontSize: 10, color: muted)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(c.text, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _heroImage(Event ev, ThemeData theme) {
    final height = MediaQuery.of(context).size.height * 0.38;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ev.coverImage != null
              ? Hero(
                  tag: 'event-${ev.id}',
                  child: Image.network(ev.coverImage!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _heroPlaceholder()),
                )
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
                    _circleButton(Icons.share, _share),
                    const SizedBox(width: 8),
                    _circleButton(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      _toggleBookmark,
                    ),
                    if (_isCreator) ...[
                      const SizedBox(width: 8),
                      _circleButton(Icons.more_vert, _showCreatorMenu),
                    ],
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

  Widget _mediaTile(String url, ThemeData theme) {
    final isVideo = _isVideoUrl(url);
    if (!isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _mediaErrorTile(theme)),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openMediaUrl(url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kGradientPurple.withValues(alpha: 0.25),
              kGradientPink.withValues(alpha: 0.25),
            ],
          ),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, size: 36, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Video uploaded. Tap to play',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaErrorTile(ThemeData theme) {
    return Container(
      decoration:
          BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
      child: Center(
        child: Text('Unable to load media',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      ),
    );
  }

  bool _isVideoUrl(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.mp4') || clean.endsWith('.mov');
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
        child: isJoined
            ? Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: 'Joined',
                      icon: Icons.check_circle,
                      onPressed: null,
                    ),
                  ),
                  if (!_isCreator) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: OutlinedButton(
                        onPressed: _leaving ? null : _leave,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _leaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.red))
                            : const Text('Leave'),
                      ),
                    ),
                  ],
                ],
              )
            : GradientButton(
                label: 'Join Event',
                isLoading: _joining,
                onPressed: _join,
              ),
      ),
    );
  }
}
