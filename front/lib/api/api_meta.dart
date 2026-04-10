class ApiMeta {
  final int? limit;
  final int? offset;
  final int? count;

  const ApiMeta({this.limit, this.offset, this.count});

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      limit: _intOrNull(json['limit']),
      offset: _intOrNull(json['offset']),
      count: _intOrNull(json['count']),
    );
  }
}
