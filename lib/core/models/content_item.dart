import 'member.dart';
import 'parameter.dart';
import 'recipe_variant.dart';

enum ContentType {
  recipe,
  sop;

  static ContentType parse(String? value) {
    return switch (value) {
      'recipe' => ContentType.recipe,
      'sop' => ContentType.sop,
      _ => throw FormatException('Unknown content type: $value'),
    };
  }
}

enum ContentStatus {
  draft,
  published;

  static ContentStatus parse(String? value) {
    return switch (value) {
      'draft' => ContentStatus.draft,
      'published' => ContentStatus.published,
      _ => throw FormatException('Unknown content status: $value'),
    };
  }
}

class ValidationIssue {
  const ValidationIssue({required this.field, required this.message});

  final String field;
  final String message;
}

class RecipeContent {
  const RecipeContent({
    required this.recipeType,
    required this.parameters,
    required this.steps,
    required this.variants,
  });

  factory RecipeContent.empty() {
    return const RecipeContent(
      recipeType: 'other',
      parameters: <Parameter>[],
      steps: <String>[],
      variants: <RecipeVariant>[],
    );
  }

  factory RecipeContent.fromJson(Map<String, Object?> json) {
    return RecipeContent(
      recipeType: (json['recipeType'] as String? ?? '').trim(),
      parameters: _readParameters(json['parameters']),
      steps: _readSteps(json['steps']),
      variants: _readVariants(json['variants']),
    );
  }

  final String recipeType;
  final List<Parameter> parameters;
  final List<String> steps;
  final List<RecipeVariant> variants;

  bool get hasContent {
    return parameters.isNotEmpty ||
        steps.isNotEmpty ||
        variants.any((variant) => variant.hasContent);
  }

  List<ValidationIssue> validate() {
    final issues = <ValidationIssue>[];
    if (recipeType.isEmpty) {
      issues.add(
        const ValidationIssue(
          field: 'recipe.recipeType',
          message: 'Recipe type is required.',
        ),
      );
    }

    if (!hasContent) {
      issues.add(
        const ValidationIssue(
          field: 'recipe',
          message: 'Recipe needs at least one parameter or step.',
        ),
      );
    }

    if (recipeType == 'drink') {
      final variantKeys = variants.map((variant) => variant.key).toSet();
      if (!variantKeys.containsAll(<String>{'hot', 'cold'})) {
        issues.add(
          const ValidationIssue(
            field: 'recipe.variants',
            message: 'Drink recipes must include hot and cold variants.',
          ),
        );
      }
    }

    for (final variant in variants) {
      if (variant.key.isEmpty || variant.name.isEmpty) {
        issues.add(
          const ValidationIssue(
            field: 'recipe.variants',
            message: 'Every variant needs a key and display name.',
          ),
        );
      }

      if (!variant.hasContent) {
        issues.add(
          ValidationIssue(
            field: 'recipe.variants.${variant.key}',
            message: 'Variant ${variant.name} needs a parameter or step.',
          ),
        );
      }
    }

    return issues;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'recipeType': recipeType,
      'parameters': parameters.map((parameter) => parameter.toJson()).toList(),
      'steps': steps,
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }
}

class SopContent {
  const SopContent({
    required this.sopType,
    required this.parameters,
    required this.steps,
  });

  factory SopContent.empty() {
    return const SopContent(
      sopType: 'other',
      parameters: <Parameter>[],
      steps: <String>[],
    );
  }

  factory SopContent.fromJson(Map<String, Object?> json) {
    return SopContent(
      sopType: (json['sopType'] as String? ?? '').trim(),
      parameters: _readParameters(json['parameters']),
      steps: _readSteps(json['steps']),
    );
  }

  final String sopType;
  final List<Parameter> parameters;
  final List<String> steps;

  bool get hasContent => parameters.isNotEmpty || steps.isNotEmpty;

  List<ValidationIssue> validate() {
    final issues = <ValidationIssue>[];
    if (sopType.isEmpty) {
      issues.add(
        const ValidationIssue(
          field: 'sop.sopType',
          message: 'SOP type is required.',
        ),
      );
    }

    if (!hasContent) {
      issues.add(
        const ValidationIssue(
          field: 'sop',
          message: 'SOP needs at least one parameter or step.',
        ),
      );
    }

    return issues;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sopType': sopType,
      'parameters': parameters.map((parameter) => parameter.toJson()).toList(),
      'steps': steps,
    };
  }
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.contentType,
    required this.status,
    required this.categoryId,
    required this.name,
    required this.notes,
    required this.imageUrl,
    required this.imagePath,
    required this.recipe,
    required this.sop,
    required this.order,
  });

  factory ContentItem.fromJson(String id, Map<String, Object?> json) {
    return ContentItem(
      id: id,
      contentType: ContentType.parse(json['contentType'] as String?),
      status: ContentStatus.parse(json['status'] as String?),
      categoryId: (json['categoryId'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      notes: (json['notes'] as String? ?? '').trim(),
      imageUrl: (json['imageUrl'] as String? ?? '').trim(),
      imagePath: (json['imagePath'] as String? ?? '').trim(),
      recipe: RecipeContent.fromJson(_readMap(json['recipe'])),
      sop: SopContent.fromJson(_readMap(json['sop'])),
      order: json['order'] as int? ?? 0,
    );
  }

  final String id;
  final ContentType contentType;
  final ContentStatus status;
  final String categoryId;
  final String name;
  final String notes;
  final String imageUrl;
  final String imagePath;
  final RecipeContent recipe;
  final SopContent sop;
  final int order;

  bool get isPublished => status == ContentStatus.published;
  bool get isRecipe => contentType == ContentType.recipe;
  bool get isSop => contentType == ContentType.sop;

  List<Parameter> get previewParameters {
    if (isSop) {
      return sop.parameters;
    }

    if (recipe.parameters.isNotEmpty) {
      return recipe.parameters;
    }

    if (recipe.variants.isNotEmpty) {
      return recipe.variants.first.parameters;
    }

    return const <Parameter>[];
  }

  List<String> get previewSteps {
    if (isSop) {
      return sop.steps;
    }

    if (recipe.steps.isNotEmpty) {
      return recipe.steps;
    }

    if (recipe.variants.isNotEmpty) {
      return recipe.variants.first.steps;
    }

    return const <String>[];
  }

  String get kindLabel => isRecipe ? 'Recipe' : 'SOP';

  String get subtypeLabel {
    return isRecipe ? recipe.recipeType : sop.sopType;
  }

  String get previewText {
    if (notes.isNotEmpty) {
      return notes;
    }

    if (previewSteps.isNotEmpty) {
      return previewSteps.first;
    }

    if (previewParameters.isNotEmpty) {
      final parameter = previewParameters.first;
      return '${parameter.name} ${parameter.formattedAmount} ${parameter.unit}';
    }

    return 'Draft content needs details.';
  }

  bool canBeSeenBy(Member member) {
    if (!member.isActive) {
      return false;
    }

    if (member.isAdmin) {
      return true;
    }

    return member.isStaff && isPublished;
  }

  List<ValidationIssue> validate() {
    final issues = <ValidationIssue>[];
    if (name.isEmpty) {
      issues.add(
        const ValidationIssue(field: 'name', message: 'Name is required.'),
      );
    }

    if (categoryId.isEmpty) {
      issues.add(
        const ValidationIssue(
          field: 'categoryId',
          message: 'Category is required.',
        ),
      );
    }

    if (isRecipe) {
      issues.addAll(recipe.validate());
    } else {
      issues.addAll(sop.validate());
    }

    return issues;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'contentType': contentType.name,
      'status': status.name,
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'notes': notes,
      'recipe': recipe.toJson(),
      'sop': sop.toJson(),
      'order': order,
    };
  }
}

Map<String, Object?> _readMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  return const <String, Object?>{};
}

List<Parameter> _readParameters(Object? value) {
  if (value is! List<Object?>) {
    return const <Parameter>[];
  }

  return value
      .whereType<Map<String, Object?>>()
      .map(Parameter.fromJson)
      .toList();
}

List<String> _readSteps(Object? value) {
  if (value is! List<Object?>) {
    return const <String>[];
  }

  return value.whereType<String>().map((step) => step.trim()).toList();
}

List<RecipeVariant> _readVariants(Object? value) {
  if (value is! List<Object?>) {
    return const <RecipeVariant>[];
  }

  return value
      .whereType<Map<String, Object?>>()
      .map(RecipeVariant.fromJson)
      .toList();
}
