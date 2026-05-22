import 'package:flutter/material.dart';

import '../core/models/content_item.dart';
import '../theme/app_colors.dart';

class ContentTypeChip extends StatelessWidget {
  const ContentTypeChip({required this.item, super.key});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        item.isRecipe ? Icons.local_cafe : Icons.assignment_outlined,
        size: 16,
      ),
      label: Text(item.kindLabel),
      visualDensity: VisualDensity.compact,
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final ContentStatus status;

  @override
  Widget build(BuildContext context) {
    final isPublished = status == ContentStatus.published;
    return Chip(
      backgroundColor: isPublished ? AppColors.success : AppColors.surfaceHigh,
      label: Text(isPublished ? 'Published' : 'Draft'),
      visualDensity: VisualDensity.compact,
    );
  }
}
