import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/event.dart';
import '../services/app_state.dart';
import '../services/user_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'event_detail_screen.dart';

const _interestOptions = [
  'Party', 'Music', 'Art', 'Food', 'Sports', 'Wellness', 'Networking', 'Other'
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  bool _editing = false;
  bool _saving = false;
  bool _uploadingImage = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late String _gender;
  List<String> _selectedInterests = [];
  List<Event> _createdEvents = [];
  List<Event> _joinedEvents = [];
  List<Event> _bookmarkedEvents = [];
  UserStats? _stats;
  String _eventsTab = 'created';

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _gender = user?.gender ?? 'other';
    _selectedInterests = List.from(user?.interests ?? []);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMyEvents(),
      _loadStats(),
      _loadBookmarks(),
    ]);
  }

  Future<void> _loadMyEvents() async {
    try {
      final created = await _userService.getMyEvents(type: 'created');
      final joined = await _userService.getMyEvents(type: 'joined');
      if (mounted) {
        setState(() {
          _createdEvents = created;
          _joinedEvents = joined;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _userService.getUserStats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await _userService.getMyBookmarks();
      if (mounted) setState(() => _bookmarkedEvents = bookmarks);
    } catch (_) {}
  }

  Future<void> refresh() async {
    await context.read<AppState>().refreshUser();
    await _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploadingImage = true);
    try {
      await _userService.uploadProfilePicture(file);
      await context.read<AppState>().refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
    if (mounted) setState(() => _uploadingImage = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _userService.updateProfile(
        name: _nameCtrl.text.trim(),
        gender: _gender,
        bio: _bioCtrl.text.trim(),
        interests: _selectedInterests.map((e) => e.toLowerCase()).toList(),
      );
      await context.read<AppState>().refreshUser();
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  void _showSettings() {
    final theme = Theme.of(context);
    final appState = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Settings',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _settingsItem(
                icon: Icons.dark_mode,
                title: 'Theme',
                subtitle: _themeModeLabel(appState.themeMode),
                onTap: () => _showThemePicker(appState),
              ),
              const Divider(height: 1),
              _settingsItem(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Event Explorer v1.0.0',
                onTap: () => _showAboutDialog(),
              ),
              const Divider(height: 1),
              _settingsItem(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: Colors.red,
                titleColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  context.read<AppState>().logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  void _showThemePicker(AppState appState) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(
                  mode == ThemeMode.dark
                      ? Icons.dark_mode
                      : mode == ThemeMode.light
                          ? Icons.light_mode
                          : Icons.settings_brightness,
                ),
                title: Text(_themeModeLabel(mode)),
                trailing:
                    appState.themeMode == mode ? const Icon(Icons.check) : null,
                onTap: () {
                  appState.setThemeMode(mode);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w500, color: titleColor)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant))
          : null,
      trailing:
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Event Explorer'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 12),
            Text(
              'Discover and join events happening around you. '
              'Create your own events and connect with people who share your interests.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(
          slivers: [
          SliverToBoxAdapter(child: _gradientHeader(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: theme.colorScheme.surface, width: 4),
                                gradient: kGradientPurplePink,
                              ),
                              child: ClipOval(
                                child: user.profilePicture != null
                                    ? Image.network(user.profilePicture!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _avatarPlaceholder())
                                    : _avatarPlaceholder(),
                              ),
                            ),
                            GestureDetector(
                              onTap: _editing ? _pickImage : null,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  gradient: kGradientPurplePink,
                                  shape: BoxShape.circle,
                                ),
                                child: _uploadingImage
                                    ? const Padding(
                                        padding: EdgeInsets.all(9),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.edit,
                                        size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_editing) ...[
                          TextFormField(
                            controller: _nameCtrl,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Your name',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outline),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bioCtrl,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Bio (optional)',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outline),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outline),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (v) => setState(() => _gender = v!),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Interests',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: muted)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _interestOptions.map((tag) {
                              final selected = _selectedInterests
                                  .contains(tag.toLowerCase());
                              return ChoiceChip(
                                label: Text(tag),
                                selected: selected,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedInterests.add(tag.toLowerCase());
                                    } else {
                                      _selectedInterests
                                          .remove(tag.toLowerCase());
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _nameCtrl.text = user.name;
                                    _bioCtrl.text = user.bio ?? '';
                                    _gender = user.gender;
                                    _selectedInterests =
                                        List.from(user.interests);
                                    setState(() => _editing = false);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: theme.colorScheme.outline),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(100)),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GradientButton(
                                  label: 'Save',
                                  isLoading: _saving,
                                  onPressed: _save,
                                  height: 48,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(user.name,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            user.gender[0].toUpperCase() +
                                user.gender.substring(1),
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(user.bio!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: muted)),
                          ],
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                  child: _statCard(
                                '${_stats?.eventsCreated ?? 0}',
                                'Created',
                                [
                                  kGradientPurple.withValues(alpha: 0.15),
                                  kGradientPink.withValues(alpha: 0.15),
                                ],
                                kGradientPurplePink,
                              )),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _statCard(
                                '${_stats?.eventsAttended ?? 0}',
                                'Attended',
                                [
                                  kGradientPink.withValues(alpha: 0.15),
                                  kGradientOrange.withValues(alpha: 0.15),
                                ],
                                const LinearGradient(
                                    colors: [kGradientPink, kGradientOrange]),
                              )),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _statCard(
                                '${_stats?.followersCount ?? 0}',
                                'Followers',
                                [
                                  kGradientOrange.withValues(alpha: 0.15),
                                  kGradientPurple.withValues(alpha: 0.15),
                                ],
                                const LinearGradient(
                                    colors: [kGradientOrange, kGradientPurple]),
                              )),
                            ],
                          ),
                          const SizedBox(height: 20),

                          GradientButton(
                            label: 'Edit Profile',
                            onPressed: () => setState(() => _editing = true),
                            height: 48,
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (!_editing) ...[
                    const SizedBox(height: 20),
                    _buildEventsSection(theme, muted),
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

  Widget _buildEventsSection(ThemeData theme, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _tabButton('Created', 'created', theme),
            const SizedBox(width: 8),
            _tabButton('Joined', 'joined', theme),
            const SizedBox(width: 8),
            _tabButton('Saved', 'saved', theme),
          ],
        ),
        const SizedBox(height: 12),
        ..._currentEvents.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _compactEventCard(context, e),
            )),
        if (_currentEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('No events here yet',
                  style: TextStyle(fontSize: 13, color: muted)),
            ),
          ),
      ],
    );
  }

  List<Event> get _currentEvents {
    switch (_eventsTab) {
      case 'joined':
        return _joinedEvents;
      case 'saved':
        return _bookmarkedEvents;
      default:
        return _createdEvents;
    }
  }

  Widget _tabButton(String label, String tab, ThemeData theme) {
    final active = _eventsTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _eventsTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? kGradientPurplePink : null,
          color: active ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? Colors.white : theme.colorScheme.onSurfaceVariant,
            )),
      ),
    );
  }

  Widget _gradientHeader(BuildContext context) {
    return Container(
      height: 140 + MediaQuery.of(context).padding.top,
      decoration: const BoxDecoration(gradient: kGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _headerButton(Icons.settings, _showSettings),
                    const SizedBox(width: 8),
                    _headerButton(
                        Icons.logout, () => context.read<AppState>().logout()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
      child: const Icon(Icons.person, size: 48, color: Colors.white),
    );
  }

  Widget _statCard(
    String value,
    String label,
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
            child: Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
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
                      width: 56, height: 56, fit: BoxFit.cover,
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
                      if (event.averageRating != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 11, color: Colors.amber),
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
