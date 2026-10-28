import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/models/custom_input_def.dart';

/// Modal bottom sheet for configuring an input widget.
class InputConfigSheet extends StatefulWidget {
  const InputConfigSheet({
    super.key,
    this.initial,
    required this.existingVariableIds,
  });

  final CustomInputDef? initial;
  final Set<String> existingVariableIds;

  static Future<CustomInputDef?> show({
    required BuildContext context,
    CustomInputDef? initial,
    required Set<String> existingVariableIds,
  }) {
    return showModalBottomSheet<CustomInputDef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InputConfigSheet(
        initial: initial,
        existingVariableIds: existingVariableIds,
      ),
    );
  }

  @override
  State<InputConfigSheet> createState() => _InputConfigSheetState();
}

class _InputConfigSheetState extends State<InputConfigSheet> {
  late CustomInputType _selectedType;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _defaultCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _stepCtrl;
  late final TextEditingController _prefixCtrl;
  late final TextEditingController _suffixCtrl;
  late final TextEditingController _infoTextCtrl;

  String _durationUnit = 'years';
  final List<CustomChoiceOption> _dropdownOptions = [];
  bool _idManuallyEdited = false;
  String? _idError;
  String? _labelError;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _selectedType = init?.type ?? CustomInputType.currency;
    _labelCtrl = TextEditingController(text: init?.label ?? '');
    _idCtrl = TextEditingController(text: init?.id ?? '');
    _idManuallyEdited = init != null;
    _descCtrl = TextEditingController(text: init?.description ?? '');
    _defaultCtrl = TextEditingController(
      text: init?.defaultValue != null ? init!.defaultValue.toString() : '',
    );
    _minCtrl = TextEditingController(
      text: init?.min != null ? init!.min.toString() : '',
    );
    _maxCtrl = TextEditingController(
      text: init?.max != null ? init!.max.toString() : '',
    );
    _stepCtrl = TextEditingController(
      text: init?.step != null ? init!.step.toString() : '',
    );
    _prefixCtrl = TextEditingController(text: init?.prefix ?? '');
    _suffixCtrl = TextEditingController(text: init?.suffix ?? '');
    _infoTextCtrl = TextEditingController(text: init?.infoText ?? '');

    _durationUnit = init?.durationUnit ?? 'years';

    if (init != null && init.options.isNotEmpty) {
      _dropdownOptions.addAll(init.options);
    } else {
      _dropdownOptions.addAll(const [
        CustomChoiceOption(value: '1', label: 'Option 1'),
        CustomChoiceOption(value: '2', label: 'Option 2'),
      ]);
    }

    _labelCtrl.addListener(_onLabelChanged);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _idCtrl.dispose();
    _descCtrl.dispose();
    _defaultCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _stepCtrl.dispose();
    _prefixCtrl.dispose();
    _suffixCtrl.dispose();
    _infoTextCtrl.dispose();
    super.dispose();
  }

  void _onLabelChanged() {
    if (!_idManuallyEdited && _selectedType.isComputational) {
      final generated = _labelCtrl.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      _idCtrl.text = generated;
    }
  }

  bool _validate() {
    setState(() {
      _labelError = null;
      _idError = null;
    });

    if (_labelCtrl.text.trim().isEmpty) {
      setState(() => _labelError = 'Label is required');
      return false;
    }

    if (_selectedType.isComputational) {
      final id = _idCtrl.text.trim();
      if (id.isEmpty) {
        setState(() => _idError = 'Variable ID is required');
        return false;
      }
      if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(id)) {
        setState(() => _idError = 'ID must start with a letter and contain only letters, numbers, and underscores');
        return false;
      }
      // Check collision
      final isNewOrRenamed = widget.initial == null || widget.initial!.id != id;
      if (isNewOrRenamed && widget.existingVariableIds.contains(id)) {
        setState(() => _idError = 'Variable ID "$id" already exists in this calculator');
        return false;
      }
    }

    return true;
  }

  void _submit() {
    if (!_validate()) return;

    final id = _selectedType.isComputational
        ? _idCtrl.text.trim()
        : 'field_${DateTime.now().millisecondsSinceEpoch}';

    final def = CustomInputDef(
      id: id,
      label: _labelCtrl.text.trim(),
      type: _selectedType,
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      defaultValue: double.tryParse(_defaultCtrl.text.trim()),
      min: double.tryParse(_minCtrl.text.trim()),
      max: double.tryParse(_maxCtrl.text.trim()),
      step: double.tryParse(_stepCtrl.text.trim()),
      prefix: _prefixCtrl.text.trim().isNotEmpty ? _prefixCtrl.text.trim() : null,
      suffix: _suffixCtrl.text.trim().isNotEmpty ? _suffixCtrl.text.trim() : null,
      durationUnit: _durationUnit,
      options: _dropdownOptions,
      infoText: _infoTextCtrl.text.trim().isNotEmpty ? _infoTextCtrl.text.trim() : null,
    );

    Navigator.of(context).pop(def);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final isComputational = _selectedType.isComputational;

    return Material(
      color: p.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initial == null ? 'Add Input Widget' : 'Edit Input Widget',
                    style: t.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                shrinkWrap: true,
                children: [
                  Text('WIDGET TYPE', style: t.labelSmall?.copyWith(color: p.inkSubtle, letterSpacing: 1.1)),
                  const SizedBox(height: AppSpacing.xs),
                  _buildTypeSelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // Label
                  TextField(
                    controller: _labelCtrl,
                    decoration: InputDecoration(
                      labelText: _selectedType == CustomInputType.sectionHeader
                          ? 'Section Title'
                          : (_selectedType == CustomInputType.infoBlock ? 'Note Title' : 'Input Label'),
                      hintText: 'e.g. Monthly Revenue',
                      errorText: _labelError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Variable ID (for computational fields)
                  if (isComputational) ...[
                    TextField(
                      controller: _idCtrl,
                      onChanged: (_) => _idManuallyEdited = true,
                      decoration: InputDecoration(
                        labelText: 'Variable ID (used in formulas)',
                        hintText: 'e.g. monthly_revenue',
                        errorText: _idError,
                        helperText: 'Unique internal identifier for formula calculation.',
                        prefixIcon: const Icon(PhosphorIconsRegular.code, size: 18),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Description / Helper
                  if (_selectedType != CustomInputType.sectionHeader) ...[
                    TextField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Helper Description (optional)',
                        hintText: 'e.g. Enter revenue before platform cuts',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Default Value
                  if (isComputational && _selectedType != CustomInputType.date && _selectedType != CustomInputType.dropdown) ...[
                    TextField(
                      controller: _defaultCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: InputDecoration(
                        labelText: 'Default Value',
                        hintText: 'e.g. 5000',
                        suffixText: _selectedType == CustomInputType.percentage ? '%' : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Min & Max (for numbers, currencies, percentages, sliders)
                  if (_selectedType == CustomInputType.number ||
                      _selectedType == CustomInputType.currency ||
                      _selectedType == CustomInputType.percentage ||
                      _selectedType == CustomInputType.slider) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Min Value (optional)'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: _maxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Max Value (optional)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Duration Unit selection
                  if (_selectedType == CustomInputType.duration) ...[
                    Text('DURATION UNIT', style: t.labelSmall?.copyWith(color: p.inkSubtle, letterSpacing: 1.1)),
                    const SizedBox(height: AppSpacing.xs),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'days', label: Text('Days')),
                        ButtonSegment(value: 'months', label: Text('Months')),
                        ButtonSegment(value: 'years', label: Text('Years')),
                      ],
                      selected: {_durationUnit},
                      onSelectionChanged: (set) => setState(() => _durationUnit = set.first),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Dropdown Options
                  if (_selectedType == CustomInputType.dropdown) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SELECTABLE OPTIONS', style: t.labelSmall?.copyWith(color: p.inkSubtle, letterSpacing: 1.1)),
                        TextButton.icon(
                          icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                          label: const Text('Add Option'),
                          onPressed: _addDropdownOption,
                        ),
                      ],
                    ),
                    for (int i = 0; i < _dropdownOptions.length; i++)
                      _buildOptionTile(i),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Info Block Text
                  if (_selectedType == CustomInputType.infoBlock) ...[
                    TextField(
                      controller: _infoTextCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Disclaimer / Note Text',
                        hintText: 'Enter guidance or calculation assumptions here...',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Confirm button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(PhosphorIconsRegular.check, size: 18),
                    label: Text(widget.initial == null ? 'Add Input' : 'Save Changes'),
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTypeSelector() {
    final p = context.pal;
    const types = [
      (CustomInputType.currency, 'Currency', PhosphorIconsRegular.currencyDollar),
      (CustomInputType.number, 'Number', PhosphorIconsRegular.hash),
      (CustomInputType.percentage, 'Percentage', PhosphorIconsRegular.percent),
      (CustomInputType.duration, 'Duration', PhosphorIconsRegular.clock),
      (CustomInputType.dropdown, 'Dropdown', PhosphorIconsRegular.list),
      (CustomInputType.toggle, 'Toggle', PhosphorIconsRegular.toggleRight),
      (CustomInputType.slider, 'Slider', PhosphorIconsRegular.sliders),
      (CustomInputType.date, 'Date', PhosphorIconsRegular.calendar),
      (CustomInputType.sectionHeader, 'Header', PhosphorIconsRegular.textT),
      (CustomInputType.infoBlock, 'Info Note', PhosphorIconsRegular.info),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: types.map((t) {
        final isSelected = _selectedType == t.$1;
        return ChoiceChip(
          selected: isSelected,
          avatar: Icon(
            t.$3,
            size: 16,
            color: isSelected ? p.onPrimary : p.inkMuted,
          ),
          label: Text(t.$2),
          onSelected: (val) {
            if (val) {
              setState(() {
                _selectedType = t.$1;
                _onLabelChanged();
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildOptionTile(int index) {
    final opt = _dropdownOptions[index];
    final p = context.pal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: opt.label,
              decoration: const InputDecoration(labelText: 'Display Label', isDense: true),
              onChanged: (val) {
                _dropdownOptions[index] = CustomChoiceOption(value: opt.value, label: val);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: opt.value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Numeric Value', isDense: true),
              onChanged: (val) {
                _dropdownOptions[index] = CustomChoiceOption(value: val, label: opt.label);
              },
            ),
          ),
          if (_dropdownOptions.length > 1)
            IconButton(
              icon: Icon(PhosphorIconsRegular.trash, size: 16, color: p.loss),
              onPressed: () => setState(() => _dropdownOptions.removeAt(index)),
            ),
        ],
      ),
    );
  }

  void _addDropdownOption() {
    setState(() {
      final nextNum = _dropdownOptions.length + 1;
      _dropdownOptions.add(CustomChoiceOption(
        value: nextNum.toString(),
        label: 'Option $nextNum',
      ));
    });
  }
}
