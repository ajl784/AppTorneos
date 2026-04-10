import 'package:front/api/api_meta.dart';

class ApiResponse<T> {
  final T data;
  final ApiMeta? meta;

  const ApiResponse({required this.data, this.meta});
}
