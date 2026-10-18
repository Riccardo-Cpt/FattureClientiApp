import 'package:flutter/material.dart';
import 'package:spese_cliente_app/l10n/strings.dart';
import 'package:spese_cliente_app/models/material_item.dart';

class MaterialForm extends StatefulWidget {
  final int clientId;
  final MaterialItem? initial;
  final void Function(MaterialItem) onSubmit;

  const MaterialForm({
    super.key,
    required this.clientId,
    this.initial,
    required this.onSubmit,
  });

  @override
  State<MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<MaterialForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.initial != null ? widget.initial!.quantity.toString() : '',
    );
    _unitPriceController = TextEditingController(
      text: widget.initial != null ? widget.initial!.unitPrice.toString() : '',
    );
    _date = widget.initial?.date ?? DateTime.now();

    _quantityController.addListener(_recompute);
    _unitPriceController.addListener(_recompute);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _recompute() => setState(() {});

  double get _liveTotal {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    return quantity * unitPrice;
  }

  String? _requiredValidator(String? value) {
    final s = S.of(context);
    if (value == null || value.trim().isEmpty) {
      return s.required;
    }
    return null;
  }

  String? _positiveQuantityValidator(String? value) {
    final s = S.of(context);
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) {
      return s.mustBeNumber;
    }
    if (parsed <= 0) {
      return s.mustBePositive;
    }
    return null;
  }

  String? _nonNegativePriceValidator(String? value) {
    final s = S.of(context);
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) {
      return s.mustBeNumber;
    }
    if (parsed < 0) {
      return s.mustBeNonNegative;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    widget.onSubmit(MaterialItem(
      id: widget.initial?.id,
      clientId: widget.clientId,
      name: _nameController.text.trim(),
      quantity: double.parse(_quantityController.text),
      unitPrice: double.parse(_unitPriceController.text),
      date: _date,
      paid: widget.initial?.paid ?? false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('material_name_field'),
            controller: _nameController,
            decoration: InputDecoration(labelText: s.name),
            validator: _requiredValidator,
          ),
          TextFormField(
            key: const Key('material_quantity_field'),
            controller: _quantityController,
            decoration: InputDecoration(labelText: s.quantity),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _positiveQuantityValidator,
          ),
          TextFormField(
            key: const Key('material_unit_price_field'),
            controller: _unitPriceController,
            decoration: InputDecoration(labelText: s.unitPrice),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _nonNegativePriceValidator,
          ),
          Text(s.total(_liveTotal)),
          ListTile(
            title: Text(s.date('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}')),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            child: Text(widget.initial == null ? s.add : s.save),
          ),
        ],
      ),
    );
  }
}
