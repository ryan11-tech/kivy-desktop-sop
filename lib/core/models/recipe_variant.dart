import 'parameter.dart';

class RecipeVariant {
  const RecipeVariant({
    required this.key,
    required this.name,
    required this.parameters,
    required this.steps,
  });

  factory RecipeVariant.fromJson(Map<String, Object?> json) {
    return RecipeVariant(
      key: (json['key'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      parameters: _readParameters(json['parameters']),
      steps: _readSteps(json['steps']),
    );
  }

  final String key;
  final String name;
  final List<Parameter> parameters;
  final List<String> steps;

  bool get hasContent => parameters.isNotEmpty || steps.isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key,
      'name': name,
      'parameters': parameters.map((parameter) => parameter.toJson()).toList(),
      'steps': steps,
    };
  }

  static List<Parameter> _readParameters(Object? value) {
    if (value is! List<Object?>) {
      return const <Parameter>[];
    }

    return value
        .whereType<Map<String, Object?>>()
        .map(Parameter.fromJson)
        .toList();
  }

  static List<String> _readSteps(Object? value) {
    if (value is! List<Object?>) {
      return const <String>[];
    }

    return value.whereType<String>().map((step) => step.trim()).toList();
  }
}
