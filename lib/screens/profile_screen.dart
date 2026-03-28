import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/event.dart';
import '../services/app_state.dart';
import '../services/user_service.dart';
import '../services/event_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'event_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final EventService _eventService = EventService();

  List<Event> _userEvents = [];
  UserStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadUserEvents();
    _loadStats();
  }

  Future<void> _loadUserEvents() async {
    try {
      double lat = 37.7749, lng = -122.4194;
      try {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}
      final events = await _eventService.getNearbyEvents(
        lat: lat,
        lng: lng,
        radius: 50000,
      );
      if (mounted) setState(() => _userEvents = events.take(3).toList());
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _userService.getUserStats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    await context.read<AppState>().refreshUser();
    await _loadUserEvents();
    await _loadStats();
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openEditProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (result == true && mounted) {
      _refresh();
    }
  }

  Future<void> _launchSocial(String platform, String handle) async {
    Uri? uri;
    switch (platform) {
      case 'instagram':
        final clean = handle.replaceAll('@', '');
        uri = Uri.parse('https://instagram.com/$clean');
        break;
      case 'twitter':
        final clean = handle.replaceAll('@', '');
        uri = Uri.parse('https://x.com/$clean');
        break;
      case 'linkedin':
        if (handle.startsWith('http')) {
          uri = Uri.parse(handle);
        } else {
          uri = Uri.parse('https://linkedin.com/in/$handle');
        }
        break;
    }
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final memberSince = DateFormat('MMMM yyyy').format(user.createdAt.toLocal());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Gradient header with overlapping avatar
            SliverToBoxAdapter(child: _buildHeader(context, user, memberSince)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bio section
                    _buildBioSection(theme, muted, user),

                    const SizedBox(height: 20),

                    // Stats row
                    _buildStatsRow(theme, memberSince),

                    // Interests
                    if (user.interests.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildInterestsSection(theme, user),
                    ],

                    // Social links
                    if (user.socialLinks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSocialLinksSection(theme, muted, user),
                    ],

                    // Quick actions
                    const SizedBox(height: 20),
                    _buildQuickActions(theme),

                    // Upcoming events
                    if (_userEvents.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nearby Events',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${_userEvents.length} events',
                              style: TextStyle(fontSize: 12, color: muted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(_userEvents.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _compactEventCard(context, e),
                          ))),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, String memberSince) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient background
        Container(
          height: 180 + topPad,
          decoration: const BoxDecoration(gradient: kGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('My Profile',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        _headerButton(Icons.edit, _openEditProfile),
                        const SizedBox(width: 8),
                        _headerButton(Icons.settings, _openSettings),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Overlapping profile card
        Padding(
          padding: EdgeInsets.only(top: 120 + topPad, left: 16, right: 16),
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              children: [
                Text(user.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user.email,
                    style: TextStyle(fontSize: 13, color: muted)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month, size: 13, color: muted),
                    const SizedBox(width: 4),
                    Text('Member since $memberSince',
                        style: TextStyle(fontSize: 12, color: muted)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: kGradientPurplePink,
                      ),
                      child: Text(
                        user.gender[0].toUpperCase() +
                            user.gender.substring(1),
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Floating avatar
        Positioned(
          top: 80 + topPad,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 4),
                gradient: kGradientPurplePink,
              ),
              child: ClipOval(
                child: user.profilePicture != null
                    ? Image.network(user.profilePicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarPlaceholder())
                    : _avatarPlaceholder(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(ThemeData theme, Color muted, user) {
    final hasBio = user.bio != null && user.bio!.isNotEmpty;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    kGradientPurplePink.createShader(bounds),
                child: const Icon(Icons.format_quote,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Text('About',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          if (hasBio)
            Text(user.bio!, style: TextStyle(fontSize: 14, color: muted, height: 1.5))
          else
            GestureDetector(
              onTap: _openEditProfile,
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Tell people about yourself',
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, String memberSince) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            '${_stats?.eventsCreated ?? 0}',
            'Created',
            Icons.add_circle_outline,
            [
              kGradientPurple.withValues(alpha: 0.15),
              kGradientPink.withValues(alpha: 0.15),
            ],
            kGradientPurplePink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            '${_stats?.eventsAttended ?? 0}',
            'Attended',
            Icons.check_circle_outline,
            [
              kGradientPink.withValues(alpha: 0.15),
              kGradientOrange.withValues(alpha: 0.15),
            ],
            const LinearGradient(colors: [kGradientPink, kGradientOrange]),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            '${((_stats?.eventsCreated ?? 0) + (_stats?.eventsAttended ?? 0))}',
            'Total',
            Icons.star_outline,
            [
              kGradientOrange.withValues(alpha: 0.15),
              kGradientPurple.withValues(alpha: 0.15),
            ],
            const LinearGradient(colors: [kGradientOrange, kGradientPurple]),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(ThemeData theme, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  kGradientPurplePink.createShader(bounds),
              child:
                  const Icon(Icons.interests, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text('Interests',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (user.interests as List<String>).map((tag) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGradientPurple.withValues(alpha: 0.4)),
                color: kGradientPurple.withValues(alpha: 0.1),
              ),
              child: Text(tag,
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection(ThemeData theme, Color muted, user) {
    final links = user.socialLinks as Map<String, String>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  kGradientPurplePink.createShader(bounds),
              child: const Icon(Icons.link, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text('Social Links',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: links.entries.map((entry) {
            IconData icon;
            switch (entry.key) {
              case 'instagram':
                icon = Icons.camera_alt_outlined;
                break;
              case 'twitter':
                icon = Icons.alternate_email;
                break;
              case 'linkedin':
                icon = Icons.work_outline;
                break;
              default:
                icon = Icons.link;
            }
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => _launchSocial(entry.key, entry.value),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        entry.value.length > 18
                            ? '${entry.value.substring(0, 18)}...'
                            : entry.value,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: GradientButton(
            label: 'Edit Profile',
            icon: Icons.edit,
            onPressed: _openEditProfile,
            height: 46,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Settings'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.outline),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
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

  Widget _avatarPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: kGradientPurplePink),
      child: const Icon(Icons.person, size: 40, color: Colors.white),
    );
  }

  Widget _statCard(
    String value,
    String label,
    IconData icon,
    List<Color> bgColors,
    LinearGradient textGrad,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgColors,
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => textGrad.createShader(bounds),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (bounds) => textGrad.createShader(bounds),
            child: Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _compactEventCard(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateFmt = DateFormat('MMM d');

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: event.id),
      )),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: event.coverImage != null
                  ? Image.network(event.coverImage!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _miniPlaceholder())
                  : _miniPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 11, color: muted),
                      const SizedBox(width: 4),
                      Text(dateFmt.format(event.startTime.toLocal()),
                          style: TextStyle(fontSize: 11, color: muted)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: muted),
          ],
        ),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          kGradientPurple.withValues(alpha: 0.3),
          kGradientPink.withValues(alpha: 0.3),
        ]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.event, color: Colors.white38, size: 24),
    );
  }
}
