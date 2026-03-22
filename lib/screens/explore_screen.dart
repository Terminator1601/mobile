import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/category_chips.dart';
import '../widgets/event_card.dart';
import '../widgets/avatar_stack.dart';
import 'event_detail_screen.dart';

const _categories = [
  'All', 'Party', 'Music', 'Art', 'Food', 'Sports', 'Wellness', 'Networking'
];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Event> _events = [];
  String _selectedCategory = 'All';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      double lat = 37.7749, lng = -122.4194;
      try {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}

      _events = await _eventService.getNearbyEvents(
        lat: lat,
        lng: lng,
        radius: 15000,
      );
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Event> get _filteredEvents {
    var list = _events;
    if (_selectedCategory != 'All') {
      list = list
          .where((e) =>
              e.interestTag?.toLowerCase() ==
              _selectedCategory.toLowerCase())
          .toList();
    }
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((e) => e.title.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<Event> get _trending => _events.take(3).toList();

  void _openDetail(Event event) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EventDetailScreen(eventId: event.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(theme)),
              SliverToBoxAdapter(child: _categoryBar()),
              if (!_loading && _trending.isNotEmpty)
                SliverToBoxAdapter(child: _trendingSection(theme)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    _selectedCategory == 'All'
                        ? 'All Events'
                        : '$_selectedCategory Events',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: _filteredEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => EventCard(
                      event: _filteredEvents[i],
                      onTap: () => _openDetail(_filteredEvents[i]),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Explore',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: kGradientPurple, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: kGradientPurplePink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: CategoryChips(
        categories: _categories,
        selected: _selectedCategory,
        onSelected: (cat) => setState(() => _selectedCategory = cat),
      ),
    );
  }

  Widget _trendingSection(ThemeData theme) {
    final dateFmt = DateFormat('h:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: kGradientPink, size: 20),
              const SizedBox(width: 6),
              Text('Trending Now',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trending.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _trendingCard(theme, _trending[i], dateFmt),
          ),
        ),
      ],
    );
  }

  Widget _trendingCard(ThemeData theme, Event event, DateFormat dateFmt) {
    return GestureDetector(
      onTap: () => _openDetail(event),
      child: SizedBox(
        width: 240,
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                      child: event.coverImage != null
                          ? Image.network(event.coverImage!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _trendingPlaceholder())
                          : _trendingPlaceholder(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                    if (event.isLive)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kLiveRed,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 11, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(dateFmt.format(event.startTime.toLocal()),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AvatarStack(
                        totalCount: event.participantCount, max: 3, size: 28),
                    Text('${event.participantCount}',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trendingPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kGradientPurple.withValues(alpha: 0.4),
            kGradientPink.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: const Icon(Icons.event, size: 40, color: Colors.white38),
    );
  }
}
