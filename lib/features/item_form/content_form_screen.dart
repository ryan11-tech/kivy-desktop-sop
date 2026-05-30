import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/admin_api_models.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/staff_api_client.dart';
import '../../theme/app_colors.dart';

class ContentFormScreen extends StatefulWidget {
  const ContentFormScreen({super.key});

  @override
  State<ContentFormScreen> createState() => _ContentFormScreenState();
}

class _ContentFormScreenState extends State<ContentFormScreen> {
  final TextEditingController _searchController = TextEditingController();
  PortalContentKind _kind = PortalContentKind.sop;
  List<PortalContentItem> _items = const <PortalContentItem>[];
  List<PortalCategory> _categories = const <PortalCategory>[];
  List<PortalShop> _shops = const <PortalShop>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<StaffApiClient>();
      final items = await api.listPortalContent(_kind);
      final categories = await api.listPortalCategories(_kind);
      final shops = await api.listPortalShops();
      if (!mounted) return;
      setState(() {
        _items = items;
        _categories = categories;
        _shops = shops;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load content.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visible =
        query.isEmpty
            ? _items
            : _items.where((item) {
              return item.name.toLowerCase().contains(query) ||
                  item.publicId.toLowerCase().contains(query) ||
                  item.typeKey.toLowerCase().contains(query) ||
                  item.status.toLowerCase().contains(query);
            }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Content management'),
        actions: [
          IconButton(
            tooltip: 'Add category',
            onPressed: _loading ? null : _openCategoryDialog,
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shops.isEmpty ? null : () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(_kind == PortalContentKind.sop ? 'SOP' : 'Recipe'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
          children: [
            SegmentedButton<PortalContentKind>(
              segments: const [
                ButtonSegment(
                  value: PortalContentKind.sop,
                  label: Text('SOPs'),
                  icon: Icon(Icons.assignment_outlined),
                ),
                ButtonSegment(
                  value: PortalContentKind.recipe,
                  label: Text('Recipes'),
                  icon: Icon(Icons.local_cafe_outlined),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) {
                setState(() => _kind = selection.first);
                _load();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search name, id, type, or status',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              _StateCard(
                icon: Icons.error_outline,
                title: 'Could not load content',
                message: _error!,
                actionLabel: 'Retry',
                onAction: _load,
              )
            else if (visible.isEmpty)
              _StateCard(
                icon: Icons.library_books_outlined,
                title: 'No ${_kindLabelPlural.toLowerCase()} found',
                message: 'Create content or adjust the search.',
              )
            else
              ...visible.map(_buildContentCard),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(PortalContentItem item) {
    final assigned =
        item.assignedShops.isEmpty
            ? 'No shops assigned'
            : item.assignedShops.map((shop) => shop.name).join(', ');

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _Chip(text: item.status.toUpperCase()),
                const SizedBox(width: 6),
                _Chip(text: item.typeKey.toUpperCase()),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.publicId.isEmpty ? item.id : item.publicId,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (item.categoryName.isNotEmpty) item.categoryName,
                assigned,
              ].join(' • '),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _togglePublish(item),
                  icon: Icon(
                    item.status == 'published'
                        ? Icons.visibility_off_outlined
                        : Icons.public,
                    size: 18,
                  ),
                  label: Text(
                    item.status == 'published' ? 'Unpublish' : 'Publish',
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _openEditor(item),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Archive',
                  onPressed: () => _confirmArchive(item),
                  icon: const Icon(Icons.archive_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor([PortalContentItem? listItem]) async {
    PortalContentItem? detail = listItem;
    if (listItem != null) {
      final api = context.read<StaffApiClient>();
      final messenger = ScaffoldMessenger.of(context);
      try {
        detail = await api.getPortalContent(_kind, listItem.id);
      } on ApiException catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
    }

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (context) => _ContentEditorDialog(
            kind: _kind,
            item: detail,
            categories: _categories,
            shops: _shops,
          ),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _togglePublish(PortalContentItem item) async {
    final api = context.read<StaffApiClient>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (item.status == 'published') {
        await api.unpublishPortalContent(_kind, item.id);
      } else {
        await api.publishPortalContent(_kind, item.id);
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmArchive(PortalContentItem item) async {
    final api = context.read<StaffApiClient>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              'Archive ${item.kindLabel}?',
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              item.name,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Archive'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await api.archivePortalContent(_kind, item.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openCategoryDialog() async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    String? error;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text(
                    'New ${_kind == PortalContentKind.sop ? 'SOP' : 'recipe'} category',
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogField(controller: nameController, label: 'Name'),
                      const SizedBox(height: 10),
                      _DialogField(
                        controller: slugController,
                        label: 'Slug (optional)',
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          saving
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed:
                          saving
                              ? null
                              : () async {
                                if (nameController.text.trim().isEmpty) {
                                  setDialogState(
                                    () => error = 'Name is required.',
                                  );
                                  return;
                                }
                                setDialogState(() {
                                  saving = true;
                                  error = null;
                                });
                                final api = context.read<StaffApiClient>();
                                final navigator = Navigator.of(dialogContext);
                                try {
                                  await api.createPortalCategory(
                                    _kind,
                                    name: nameController.text,
                                    slug: slugController.text,
                                  );
                                  if (!dialogContext.mounted) return;
                                  navigator.pop();
                                  await _load();
                                } on ApiException catch (e) {
                                  setDialogState(() {
                                    error = e.message;
                                    saving = false;
                                  });
                                }
                              },
                      child:
                          saving ? const _TinyLoader() : const Text('Create'),
                    ),
                  ],
                ),
          ),
    );

    nameController.dispose();
    slugController.dispose();
  }

  String get _kindLabelPlural =>
      _kind == PortalContentKind.sop ? 'SOPs' : 'Recipes';
}

class _ContentEditorDialog extends StatefulWidget {
  const _ContentEditorDialog({
    required this.kind,
    required this.item,
    required this.categories,
    required this.shops,
  });

  final PortalContentKind kind;
  final PortalContentItem? item;
  final List<PortalCategory> categories;
  final List<PortalShop> shops;

  @override
  State<_ContentEditorDialog> createState() => _ContentEditorDialogState();
}

class _ContentEditorDialogState extends State<_ContentEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _publicIdController;
  late final TextEditingController _notesController;
  late final TextEditingController _stepsController;
  late final List<_ParameterDraft> _parameters;
  late final Set<String> _shopIds;
  late String _typeKey;
  late String _status;
  String? _categoryId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _publicIdController = TextEditingController(text: item?.publicId ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _stepsController = TextEditingController(
      text: item?.steps.join('\n') ?? '',
    );
    _parameters =
        (item?.parameters ?? const <PortalContentParameter>[])
            .map(_ParameterDraft.fromParameter)
            .toList();
    if (_parameters.isEmpty) {
      _parameters.add(_ParameterDraft());
    }
    _shopIds =
        (item?.assignedShops.map((shop) => shop.id) ?? const <String>[])
            .toSet();
    _typeKey =
        item?.typeKey ??
        (widget.kind == PortalContentKind.sop ? 'opening' : 'drink');
    _status = item?.status ?? 'draft';
    _categoryId = item?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _publicIdController.dispose();
    _notesController.dispose();
    _stepsController.dispose();
    for (final parameter in _parameters) {
      parameter.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeOptions =
        widget.kind == PortalContentKind.sop
            ? sopTypeOptions
            : recipeTypeOptions;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.item == null ? 'Create $_kindLabel' : 'Edit $_kindLabel',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DialogField(controller: _nameController, label: 'Name'),
              const SizedBox(height: 10),
              _DialogField(
                controller: _publicIdController,
                label: 'Public ID (optional)',
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                dropdownColor: AppColors.surface,
                decoration: _inputDecoration('Category'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No category'),
                  ),
                  ...widget.categories.map(
                    (category) => DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _typeKey,
                      dropdownColor: AppColors.surface,
                      decoration: _inputDecoration(
                        widget.kind == PortalContentKind.sop
                            ? 'SOP type'
                            : 'Recipe type',
                      ),
                      items:
                          typeOptions
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _typeKey = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      dropdownColor: AppColors.surface,
                      decoration: _inputDecoration('Status'),
                      items:
                          const ['draft', 'published', 'archived']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _DialogField(
                controller: _notesController,
                label: 'Notes',
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _SectionTitle(
                title: 'Parameters',
                actionLabel: 'Add',
                onAction:
                    () => setState(() {
                      _parameters.add(_ParameterDraft());
                    }),
              ),
              const SizedBox(height: 6),
              ..._parameters.asMap().entries.map((entry) {
                return _ParameterRow(
                  draft: entry.value,
                  onRemove:
                      _parameters.length == 1
                          ? null
                          : () => setState(() {
                            _parameters.removeAt(entry.key).dispose();
                          }),
                );
              }),
              const SizedBox(height: 12),
              _DialogField(
                controller: _stepsController,
                label: 'Steps (one per line)',
                maxLines: 5,
              ),
              const SizedBox(height: 14),
              const Text(
                'Assigned shops',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              ...widget.shops.map((shop) {
                return CheckboxListTile(
                  value: _shopIds.contains(shop.id),
                  onChanged:
                      (value) => setState(() {
                        if (value == true) {
                          _shopIds.add(shop.id);
                        } else {
                          _shopIds.remove(shop.id);
                        }
                      }),
                  title: Text(
                    shop.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              }),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const _TinyLoader() : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final steps =
        _stepsController.text
            .split('\n')
            .map((step) => step.trim())
            .where((step) => step.isNotEmpty)
            .toList();
    final parameters =
        _parameters
            .map((draft) => draft.toParameter())
            .where((parameter) => parameter.name.trim().isNotEmpty)
            .toList();

    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (_status == 'published' && steps.isEmpty) {
      setState(() => _error = 'Published content needs at least one step.');
      return;
    }
    if (_status == 'published' && _shopIds.isEmpty) {
      setState(() => _error = 'Published content needs at least one shop.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final payload = PortalContentMutation(
        kind: widget.kind,
        publicId: _publicIdController.text.trim(),
        name: name,
        categoryId: _categoryId,
        notes: _notesController.text.trim(),
        typeKey: _typeKey,
        status: _status,
        parameters: parameters,
        steps: steps,
        shopIds: _shopIds.toList(),
        sortOrder: widget.item?.sortOrder ?? 0,
        // This form does not edit Hot/Iced variants yet. Round-trip the
        // existing ones untouched so saving a recipe never wipes them.
        // A dedicated variant editor lands later.
        variants:
            widget.kind == PortalContentKind.recipe
                ? (widget.item?.variants ??
                    const <PortalRecipeVariantInput>[])
                : const <PortalRecipeVariantInput>[],
      );
      final api = context.read<StaffApiClient>();
      if (widget.item == null) {
        await api.createPortalContent(payload);
      } else {
        await api.updatePortalContent(widget.item!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not save content.';
        _saving = false;
      });
    }
  }

  String get _kindLabel =>
      widget.kind == PortalContentKind.sop ? 'SOP' : 'recipe';
}

class _ParameterDraft {
  _ParameterDraft({String name = '', String amount = '', String unit = ''})
    : nameController = TextEditingController(text: name),
      amountController = TextEditingController(text: amount),
      unitController = TextEditingController(text: unit);

  factory _ParameterDraft.fromParameter(PortalContentParameter parameter) {
    return _ParameterDraft(
      name: parameter.name,
      amount: parameter.amount == null ? '' : _formatNumber(parameter.amount!),
      unit: parameter.unit ?? '',
    );
  }

  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController unitController;

  PortalContentParameter toParameter() {
    return PortalContentParameter(
      name: nameController.text.trim(),
      amount: double.tryParse(amountController.text.trim()),
      unit:
          unitController.text.trim().isEmpty
              ? null
              : unitController.text.trim(),
    );
  }

  void dispose() {
    nameController.dispose();
    amountController.dispose();
    unitController.dispose();
  }
}

class _ParameterRow extends StatelessWidget {
  const _ParameterRow({required this.draft, this.onRemove});

  final _ParameterDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _DialogField(
              controller: draft.nameController,
              label: 'Name',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _DialogField(
              controller: draft.amountController,
              label: 'Amount',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _DialogField(
              controller: draft.unitController,
              label: 'Unit',
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(color: Colors.white70)),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.primary, fontSize: 10),
      ),
    );
  }
}

class _TinyLoader extends StatelessWidget {
  const _TinyLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: Colors.white24, size: 42),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.surfaceHigh,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
