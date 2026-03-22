import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/place_result.dart';
import '../services/event_service.dart';
import '../services/geocoding_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/category_chips.dart';

const _categories = [
  'Party', 'Music', 'Art', 'Food', 'Sports', 'Wellness', 'Networking', 'Other'
];
const int _maxMediaFiles = 3;
const int _maxMediaSizeBytes = 20 * 1024 * 1024;
const Set<String> _allowedMediaExtensions = {
  'jpg',
  'jpeg',
  'png',
  'mp4',
  'mov',
};

class _MediaUploadItem {
  final XFile file;
  bool isUploading;
  String? uploadedUrl;
  String? error;

  _MediaUploadItem({
    required this.file,
    this.isUploading = false,
    this.uploadedUrl,
    this.error,
  });
}

class CreateEventScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final VoidCallback? onCreated;

  const CreateEventScreen({
    super.key,
    this.initialPosition,
    this.onCreated,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final MapController _mapController = MapController();
  final EventService _eventService = EventService();
  final GeocodingService _geocodingService = GeocodingService();
  final ImagePicker _picker = ImagePicker();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxCtrl = TextEditingController(text: '50');
  final _locationSearchCtrl = TextEditingController();
  final _locationSearchFocus = FocusNode();

  late LatLng _pickedLocation;
  DateTime? _startTime;
  DateTime? _endTime;
  String? _selectedCategory;
  bool _submitting = false;
  final List<_MediaUploadItem> _mediaItems = [];
  List<PlaceResult> _locationSearchResults = [];
  Timer? _locationSearchDebounce;
  bool _mapReady = false;
  int _reverseLookupToken = 0;

  @override
  void initState() {
    super.initState();
    _pickedLocation =
        widget.initialPosition ?? const LatLng(37.7749, -122.4194);
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    if (widget.initialPosition != null) return;
    try {
      final pos = await Geolocator.getCurrentPosition();
      final current = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _pickedLocation = current);
      if (_mapReady) {
        _mapController.move(current, 14);
      }
      await _autofillLocationText(current);
    } catch (_) {}
  }

  Future<void> _autofillLocationText(LatLng location) async {
    final token = ++_reverseLookupToken;
    final label = await _geocodingService.reverseGeocode(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (!mounted || token != _reverseLookupToken) return;
    if (label == null || label.isEmpty) return;
    setState(() {
      _locationSearchCtrl.text = label;
      _locationSearchResults = [];
    });
  }

  void _onLocationSearchChanged(String query) {
    _locationSearchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _locationSearchResults = []);
      return;
    }

    _locationSearchDebounce =
        Timer(const Duration(milliseconds: 800), () async {
      final results = await _geocodingService.searchPlaces(query);
      if (!mounted) return;
      setState(() => _locationSearchResults = results);
    });
  }

  void _selectLocationFromSearch(PlaceResult place) {
    final selected = LatLng(place.latitude, place.longitude);
    setState(() {
      _pickedLocation = selected;
      _locationSearchCtrl.text = place.displayName;
      _locationSearchResults = [];
    });
    _locationSearchFocus.unfocus();
    if (_mapReady) {
      _mapController.move(selected, 14);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _maxCtrl.dispose();
    _locationSearchCtrl.dispose();
    _locationSearchFocus.dispose();
    _locationSearchDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _pickEventMedia() async {
    final remainingSlots = _maxMediaFiles - _mediaItems.length;
    if (remainingSlots <= 0) {
      _showError('You can upload up to $_maxMediaFiles files.');
      return;
    }

    final files = await _picker.pickMultipleMedia(limit: remainingSlots);
    if (files.isEmpty || !mounted) return;

    final validFiles = <XFile>[];
    for (final file in files) {
      final extension = _fileExtension(file.name);
      if (!_allowedMediaExtensions.contains(extension)) {
        _showError('${file.name}: Only JPG, PNG, MP4, and MOV files are allowed.');
        continue;
      }

      final fileSize = await File(file.path).length();
      if (fileSize > _maxMediaSizeBytes) {
        _showError('${file.name}: File must be 20MB or less.');
        continue;
      }

      validFiles.add(file);
    }

    if (validFiles.isEmpty) return;

    final newItems = validFiles
        .map((file) => _MediaUploadItem(file: file, isUploading: true))
        .toList();
    setState(() => _mediaItems.addAll(newItems));

    for (final item in newItems) {
      _uploadMediaItem(item);
    }
  }

  void _removeMediaAt(int index) {
    setState(() => _mediaItems.removeAt(index));
  }

  Future<void> _uploadMediaItem(_MediaUploadItem item) async {
    try {
      final mediaUrl = await _eventService.uploadMedia(item.file);
      if (!mounted) return;
      setState(() {
        item.uploadedUrl = mediaUrl;
        item.isUploading = false;
        item.error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        item.isUploading = false;
        item.error = '$e';
      });
      _showError('Failed to upload ${item.file.name}. Tap to retry.');
    }
  }

  Future<void> _retryUploadAt(int index) async {
    final item = _mediaItems[index];
    if (item.isUploading) return;
    setState(() {
      item.isUploading = true;
      item.error = null;
    });
    await _uploadMediaItem(item);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _fileExtension(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length < 2) return '';
    return parts.last;
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = dt;
      } else {
        _endTime = dt;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      String? coverImageUrl;
      if (_mediaItems.length > _maxMediaFiles) {
        throw Exception('You can upload up to $_maxMediaFiles files.');
      }

      for (final item in _mediaItems) {
        final extension = _fileExtension(item.file.name);
        if (!_allowedMediaExtensions.contains(extension)) {
          throw Exception('Only JPG, PNG, MP4, and MOV files are allowed.');
        }

        final size = await File(item.file.path).length();
        if (size > _maxMediaSizeBytes) {
          throw Exception('Each file must be 20MB or less.');
        }
      }

      if (_mediaItems.any((item) => item.isUploading)) {
        throw Exception('Please wait for media uploads to finish.');
      }

      if (_mediaItems.any((item) => item.uploadedUrl == null)) {
        throw Exception('Some media files failed to upload. Retry or remove them.');
      }

      final uploadedUrls = _mediaItems
          .map((item) => item.uploadedUrl!)
          .toList(growable: false);

      if (_mediaItems.isNotEmpty) {
        for (final item in _mediaItems) {
          final ext = _fileExtension(item.file.name);
          if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
            coverImageUrl = item.uploadedUrl;
            break;
          }
        }
        coverImageUrl ??= _mediaItems.first.uploadedUrl;
      }

      await _eventService.createEvent(
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        latitude: _pickedLocation.latitude,
        longitude: _pickedLocation.longitude,
        startTime: _startTime!,
        endTime: _endTime!,
        maxParticipants: int.tryParse(_maxCtrl.text) ?? 50,
        interestTag: _selectedCategory?.toLowerCase(),
        coverImage: coverImageUrl,
        mediaUrls: uploadedUrls,
      );
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onCreated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateFmt = DateFormat('EEE, MMM d · h:mm a');

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onCreated?.call();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('Create Event',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event Media',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickEventMedia,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kGradientPurple,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kGradientPurple.withValues(alpha: 0.1),
                            kGradientPink.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _mediaItems.isNotEmpty
                                  ? Icons.check_circle
                                  : Icons.image_outlined,
                              size: 40,
                              color: muted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _mediaItems.isNotEmpty
                                  ? '${_mediaItems.length}/$_maxMediaFiles file(s) selected'
                                  : 'Tap to upload image or video',
                              style: TextStyle(fontSize: 13, color: muted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Max $_maxMediaFiles files, 20MB each',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                            if (_mediaItems.any((item) => item.isUploading)) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Uploading media...',
                                    style: TextStyle(fontSize: 11, color: muted),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_mediaItems.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_mediaItems.length, (index) {
                        final item = _mediaItems[index];
                        return InputChip(
                          avatar: item.isUploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  item.uploadedUrl != null
                                      ? Icons.check_circle
                                      : Icons.error,
                                  size: 16,
                                  color: item.uploadedUrl != null
                                      ? Colors.green
                                      : Colors.red,
                                ),
                          label: Text(
                            item.file.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: (!item.isUploading && item.uploadedUrl == null)
                              ? () => _retryUploadAt(index)
                              : null,
                          onDeleted: item.isUploading
                              ? null
                              : () => _removeMediaAt(index),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap a failed file to retry upload',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event Title',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: _inputDecoration(
                        'Give your event a catchy name...', theme),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Title is required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: _inputDecoration(
                        "What's your event about?", theme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  CategoryChips(
                    categories: _categories,
                    selected: _selectedCategory,
                    onSelected: (c) =>
                        setState(() => _selectedCategory = c),
                    wrap: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => _pickDateTime(isStart: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: muted),
                            const SizedBox(width: 6),
                            Text('Date',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _startTime == null
                              ? 'Pick start'
                              : dateFmt.format(_startTime!),
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => _pickDateTime(isStart: false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: muted),
                            const SizedBox(width: 6),
                            Text('End Time',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _endTime == null
                              ? 'Pick end'
                              : dateFmt.format(_endTime!),
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place, size: 16, color: muted),
                      const SizedBox(width: 6),
                      Text('Location',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _locationSearchCtrl,
                            focusNode: _locationSearchFocus,
                            onChanged: _onLocationSearchChanged,
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
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        if (_locationSearchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _locationSearchCtrl.clear();
                              _onLocationSearchChanged('');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.clear,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_locationSearchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GlassCard(
                      borderRadius: 16,
                      padding: EdgeInsets.zero,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _locationSearchResults.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: theme.colorScheme.outline,
                          ),
                          itemBuilder: (context, index) {
                            final place = _locationSearchResults[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                size: 20,
                                color: kGradientOrange,
                              ),
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
                              onTap: () => _selectLocationFromSearch(place),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _pickedLocation,
                          initialZoom: 14,
                          onMapReady: () {
                            _mapReady = true;
                            _mapController.move(_pickedLocation, 14);
                            if (_locationSearchCtrl.text.trim().isEmpty) {
                              _autofillLocationText(_pickedLocation);
                            }
                          },
                          onTap: (tapPos, latLng) {
                            setState(() => _pickedLocation = latLng);
                            _autofillLocationText(latLng);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.event_discovery',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _pickedLocation,
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
                  const SizedBox(height: 6),
                  Text('Search or tap map to pick location',
                      style: TextStyle(fontSize: 11, color: muted)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, size: 16, color: muted),
                      const SizedBox(width: 6),
                      Text('Max Participants',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('50', theme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            GradientButton(
              label: 'Create Event',
              isLoading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, ThemeData theme) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kGradientPurple, width: 2),
      ),
    );
  }
}
