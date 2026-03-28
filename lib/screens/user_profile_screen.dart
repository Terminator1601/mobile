import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/user.dart';
import '../services/app_state.dart';
import '../services/user_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  UserStats? _stats;
  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _user = await _userService.getUser(widget.userId);
      final following = await _userService.getMyFollowing();
      _isFollowing = following.any((u) => u.id == widget.userId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleFollow() async {
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await _userService.unfollowUser(widget.userId);
        _isFollowing = false;
      } else {
        await _userService.followUser(widget.userId);
        _isFollowing = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final currentUser = context.read<AppState>().currentUser;
    final isOwnProfile = currentUser?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.name ?? 'Profile'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: theme.colorScheme.surface, width: 4),
                                gradient: kGradientPurplePink,
                              ),
                              child: ClipOval(
                                child: _user!.profilePicture != null
                                    ? Image.network(_user!.profilePicture!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _placeholder())
                                    : _placeholder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(_user!.name,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(_user!.bio!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: muted)),
                            ],
                            const SizedBox(height: 20),
                            if (!isOwnProfile)
                              GradientButton(
                                label: _isFollowing ? 'Following' : 'Follow',
                                icon: _isFollowing
                                    ? Icons.check
                                    : Icons.person_add,
                                isLoading: _followLoading,
                                onPressed: _toggleFollow,
                                height: 44,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(gradient: kGradientPurplePink),
      child: const Icon(Icons.person, size: 40, color: Colors.white),
    );
  }
}
