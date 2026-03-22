import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../main.dart';
import '../models/event.dart';
import '../models/place_result.dart';
import '../services/event_service.dart';
import '../services/geocoding_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final EventService _eventService = EventService();
  final GeocodingService _geocodingService = GeocodingService();

  LatLng _center = const LatLng(37.7749, -122.4194);
  LatLng? _lastEventLoadCenter;
  List<Marker> _markers = [];
  List<Event> _events = [];
  bool _loading = true;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  bool _searchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PlaceResult> _searchResults = [];
  Timer? _searchDebounce;
  Marker? _searchMarker;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        setState(() {
          _currentPosition = pos;
          _center = LatLng(pos.latitude, pos.longitude);
          _isTracking = true;
        });
        _mapController.move(_center, _mapController.camera.zoom);
        _startTracking();
      }
    } catch (_) {}
    await _loadEvents();
  }

  void _startTracking() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = position;
        _isTracking = true;
      });

      if (_lastEventLoadCenter != null) {
        final dist = const Distance().as(
          LengthUnit.Meter,
          _lastEventLoadCenter!,
          newPos,
        );
        if (dist > 500) {
          _center = newPos;
          _loadEvents();
        }
      }
    });
  }

  void _recenterOnUser() {
    if (_currentPosition == null) return;
    final userLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    _center = userLatLng;
    _mapController.move(userLatLng, 15.0);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    _lastEventLoadCenter = _center;
    try {
      _events = await _eventService.getNearbyEvents(
        lat: _center.latitude,
        lng: _center.longitude,
      );
      _buildMarkers();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _buildMarkers() {
    _markers = _events.map((event) {
      final color = event.isLive ? Colors.red : Colors.green;
      return Marker(
        point: LatLng(event.latitude, event.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _openDetail(event),
          child: Icon(Icons.location_pin, color: color, size: 40),
        ),
      );
    }).toList();
  }

  void _openDetail(Event event) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EventDetailScreen(eventId: event.id),
    ));
  }

  void _toggleSearch() {
    setState(() {
      _searchExpanded = !_searchExpanded;
      if (_searchExpanded) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _searchResults.clear();
        _searchFocusNode.unfocus();
      }
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 800), () async {
      final results = await _geocodingService.searchPlaces(query);
      if (mounted) setState(() => _searchResults = results);
    });
  }

  void _selectPlace(PlaceResult place) {
    final placeLatLng = LatLng(place.latitude, place.longitude);
    setState(() {
      _center = placeLatLng;
      _searchMarker = Marker(
        point: placeLatLng,
        width: 40,
        height: 40,
        child: const Icon(Icons.place, color: kGradientOrange, size: 40),
      );
      _searchResults.clear();
      _searchExpanded = false;
      _searchController.text = place.displayName;
    });
    _searchFocusNode.unfocus();
    _mapController.move(placeLatLng, 14.0);
    _loadEvents();
  }

  void _openCreate() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => CreateEventScreen(initialPosition: _center),
    ));
    if (created == true) _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveEvents = _events.where((e) => e.isLive).toList();
    final upcomingEvents = _events.where((e) => !e.isLive).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 13,
            onTap: (_, __) {
              if (_searchExpanded) _toggleSearch();
            },
            onPositionChanged: (pos, hasGesture) {
              if (!hasGesture) return;
              final newCenter = pos.center;
              if (newCenter == null) return;
              if ((_center.latitude - newCenter.latitude).abs() > 0.01 ||
                  (_center.longitude - newCenter.longitude).abs() > 0.01) {
                _center = newCenter;
                _loadEvents();
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.event_discovery',
            ),
            if (_currentPosition != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    radius: _currentPosition!.accuracy.clamp(20, 200),
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderColor: Colors.blue.withValues(alpha: 0.25),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            MarkerLayer(markers: [
              ..._markers,
              if (_searchMarker != null) _searchMarker!,
            ]),
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: _searchExpanded
                  ? _buildExpandedSearch()
                  : _buildCollapsedSearch(),
            ),
          ),
        ),

        if (_currentPosition != null)
          Positioned(
            right: 16,
            bottom: 248,
            child: GestureDetector(
              onTap: _recenterOnUser,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black26,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isTracking ? Icons.my_location : Icons.location_searching,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
            ),
          ),

        Positioned(
          right: 16,
          bottom: 188,
          child: GestureDetector(
            onTap: _openCreate,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: kGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kGradientPurple.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),

        _buildBottomSheet(context, liveEvents, upcomingEvents),
      ],
    );
  }

  Widget _buildCollapsedSearch() {
    return Row(
      key: const ValueKey('collapsed'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GlassCard(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 6),
              Text('Nearby',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
        GlassCard(
          onTap: _toggleSearch,
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.search,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildExpandedSearch() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('expanded'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.search,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search places...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.clear,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              GestureDetector(
                onTap: _toggleSearch,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close,
                      size: 20, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          GlassCard(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.colorScheme.outline,
                ),
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: Icon(Icons.location_on,
                        size: 20, color: kGradientOrange),
                    title: Text(
                      place.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    onTap: () => _selectPlace(place),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    List<Event> liveEvents,
    List<Event> upcomingEvents,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark
        ? const Color(0xFF1A1A24).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _loadEvents,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Text('Nearby Events',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('${_events.length} events happening around you',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),

              if (liveEvents.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: kLiveRed, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text('LIVE NOW',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
                const SizedBox(height: 10),
                ...liveEvents.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child:
                          EventCard(event: e, onTap: () => _openDetail(e)),
                    )),
                const SizedBox(height: 16),
              ],

              if (upcomingEvents.isNotEmpty) ...[
                Text('UPCOMING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 10),
                ...upcomingEvents.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child:
                          EventCard(event: e, onTap: () => _openDetail(e)),
                    )),
              ],

              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
