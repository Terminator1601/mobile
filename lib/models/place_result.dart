class PlaceResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String type;

  PlaceResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      displayName: json['display_name'] ?? '',
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      type: json['type'] ?? '',
    );
  }
}
