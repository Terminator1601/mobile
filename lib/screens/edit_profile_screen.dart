import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/user.dart';
import '../services/app_state.dart';
import '../services/user_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

const List<String> kInterestTags = [
  'Music',
  'Sports',
  'Tech',
  'Art',
  'Food & Drink',
  'Travel',
  'Gaming',
  'Fitness',
  'Photography',
  'Nightlife',
  'Outdoors',
  'Networking',
  'Film',
  'Reading',
  'Volunteering',
];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _twitterCtrl;
  late TextEditingController _linkedinCtrl;
  late String _gender;
  late Set<String> _selectedInterests;

  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser!;
    _nameCtrl = TextEditingController(text: user.name);
    _bioCtrl = TextEditingController(text: user.bio ?? '');
    _instagramCtrl =
        TextEditingController(text: user.socialLinks['instagram'] ?? '');
    _twitterCtrl =
        TextEditingController(text: user.socialLinks['twitter'] ?? '');
    _linkedinCtrl =
        TextEditingController(text: user.socialLinks['linkedin'] ?? '');
    _gender = user.gender;
    _selectedInterests = Set<String>.from(user.interests);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _instagramCtrl.dispose();
    _twitterCtrl.dispose();
    _linkedinCtrl.dispose();
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
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final socialLinks = <String, String>{};
    if (_instagramCtrl.text.trim().isNotEmpty) {
      socialLinks['instagram'] = _instagramCtrl.text.trim();
    }
    if (_twitterCtrl.text.trim().isNotEmpty) {
      socialLinks['twitter'] = _twitterCtrl.text.trim();
    }
    if (_linkedinCtrl.text.trim().isNotEmpty) {
      socialLinks['linkedin'] = _linkedinCtrl.text.trim();
    }

    try {
      await _userService.updateProfile(
        name: name,
        gender: _gender,
        bio: _bioCtrl.text.trim(),
        interests: _selectedInterests.toList(),
        socialLinks: socialLinks,
      );
      await context.read<AppState>().refreshUser();
      if (mounted) Navigator.pop(context, true);
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
    final user = context.watch<AppState>().currentUser!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Edit Profile'),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: kGradient),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatarSection(user, theme),
                  const SizedBox(height: 28),
                  _buildPersonalSection(theme, muted),
                  const SizedBox(height: 28),
                  _buildInterestsSection(theme, muted),
                  const SizedBox(height: 28),
                  _buildSocialSection(theme, muted),
                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Save Changes',
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(User user, ThemeData theme) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 110,
            height: 110,
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
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: kGradientPurplePink,
                shape: BoxShape.circle,
              ),
              child: _uploadingImage
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection(ThemeData theme, Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Info',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameCtrl,
            label: 'Name',
            icon: Icons.person_outline,
            theme: theme,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _bioCtrl,
            label: 'Bio',
            icon: Icons.edit_note,
            theme: theme,
            maxLines: 3,
            maxLength: 500,
            hint: 'Tell people about yourself...',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.wc, color: muted),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _gender = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(ThemeData theme, Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interests',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Select what you enjoy — shown on your profile',
              style: TextStyle(fontSize: 13, color: muted)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kInterestTags.map((tag) {
              final selected = _selectedInterests.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedInterests.remove(tag);
                    } else {
                      _selectedInterests.add(tag);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: selected ? kGradientPurplePink : null,
                    color: selected
                        ? null
                        : theme.colorScheme.surfaceContainerHighest,
                    border: selected
                        ? null
                        : Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection(ThemeData theme, Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Social Links',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Let people find you elsewhere',
              style: TextStyle(fontSize: 13, color: muted)),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _instagramCtrl,
            label: 'Instagram',
            icon: Icons.camera_alt_outlined,
            theme: theme,
            hint: '@username',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _twitterCtrl,
            label: 'X / Twitter',
            icon: Icons.alternate_email,
            theme: theme,
            hint: '@handle',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _linkedinCtrl,
            label: 'LinkedIn',
            icon: Icons.work_outline,
            theme: theme,
            hint: 'Profile URL or username',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    int maxLines = 1,
    int? maxLength,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: kGradientPurplePink),
      child: const Icon(Icons.person, size: 48, color: Colors.white),
    );
  }
}
