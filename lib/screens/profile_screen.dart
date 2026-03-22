import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/event.dart';
import '../services/app_state.dart';
import '../services/user_service.dart';
import '../services/event_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'event_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final EventService _eventService = EventService();
  final ImagePicker _picker = ImagePicker();

  bool _editing = false;
  bool _saving = false;
  bool _uploadingImage = false;
  late TextEditingController _nameCtrl;
  late String _gender;
  List<Event> _userEvents = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _gender = user?.gender ?? 'other';
    _loadUserEvents();
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

  Future<void> _refresh() async {
    await context.read<AppState>().refreshUser();
    await _loadUserEvents();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
          SliverToBoxAdapter(child: _gradientHeader(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: GlassCard(
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
                                      color: theme.colorScheme.surface,
                                      width: 4),
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
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
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
                                fillColor: theme
                                    .colorScheme.surfaceContainerHighest,
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
                                fillColor: theme
                                    .colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: theme.colorScheme.outline),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'female', child: Text('Female')),
                                DropdownMenuItem(
                                    value: 'other', child: Text('Other')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _gender = v!),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _nameCtrl.text = user.name;
                                      _gender = user.gender;
                                      setState(() => _editing = false);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: theme.colorScheme.outline),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(100)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
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
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              user.gender[0].toUpperCase() +
                                  user.gender.substring(1),
                              style: TextStyle(fontSize: 13, color: muted),
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(child: _statCard(
                                  '0',
                                  'Events Created',
                                  [
                                    kGradientPurple.withValues(alpha: 0.15),
                                    kGradientPink.withValues(alpha: 0.15),
                                  ],
                                  kGradientPurplePink,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _statCard(
                                  '0',
                                  'Events Attended',
                                  [
                                    kGradientPink.withValues(alpha: 0.15),
                                    kGradientOrange.withValues(alpha: 0.15),
                                  ],
                                  const LinearGradient(
                                      colors: [kGradientPink, kGradientOrange]),
                                )),
                              ],
                            ),
                            const SizedBox(height: 20),

                            GradientButton(
                              label: 'Edit Profile',
                              onPressed: () =>
                                  setState(() => _editing = true),
                              height: 48,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_userEvents.isNotEmpty && !_editing) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: const Offset(0, -24),
                        child: Text('My Upcoming Events',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: Column(
                        children: _userEvents
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _compactEventCard(context, e),
                                ))
                            .toList(),
                      ),
                    ),
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

  Widget _gradientHeader(BuildContext context) {
    return Container(
      height: 160 + MediaQuery.of(context).padding.top,
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
                    _headerButton(Icons.settings, () {}),
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
      padding: const EdgeInsets.all(16),
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(height: 4),
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
