import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import '../widgets/skeleton_card.dart';
import 'event_detail_screen.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  static const int _pageSize = 50;

  final EventService _eventService = EventService();
  final ScrollController _scrollCtrl = ScrollController();

  final List<Event> _events = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });
    try {
      final results =
          await _eventService.getAllEvents(limit: _pageSize, offset: 0);
      if (!mounted) return;
      setState(() {
        _events
          ..clear()
          ..addAll(results);
        _offset = results.length;
        _hasMore = results.length >= _pageSize;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final results =
          await _eventService.getAllEvents(limit: _pageSize, offset: 0);
      if (!mounted) return;
      setState(() {
        _events
          ..clear()
          ..addAll(results);
        _offset = results.length;
        _hasMore = results.length >= _pageSize;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_events.isEmpty) _error = e;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh: $e')),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _initialLoading) return;
    setState(() => _loadingMore = true);
    try {
      final results = await _eventService.getAllEvents(
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        if (results.isEmpty) {
          _hasMore = false;
        } else {
          _events.addAll(results);
          _offset += results.length;
          if (results.length < _pageSize) {
            _hasMore = false;
          }
        }
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more events: $e')),
      );
    }
  }

  void _openDetail(Event event) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EventDetailScreen(eventId: event.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_initialLoading) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverToBoxAdapter(child: SkeletonList(count: 6)),
          ),
        ],
      );
    }

    if (_error != null && _events.isEmpty) {
      return _retryView(theme);
    }

    if (_events.isEmpty) {
      return _emptyView(theme);
    }

    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          sliver: SliverList.separated(
            itemCount: _events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => EventCard(
              event: _events[i],
              onTap: () => _openDetail(_events[i]),
            ),
          ),
        ),
        if (_loadingMore)
          const SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 16),
            sliver: SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _emptyView(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy,
                    size: 56, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  'No events yet',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check back soon for new events.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _retryView(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off,
                      size: 56, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'Couldn\'t load events',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_error',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadInitial,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
