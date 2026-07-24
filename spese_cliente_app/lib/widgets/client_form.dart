import 'package:flutter/material.dart';
import 'package:spese_cliente_app/models/client.dart';

class ClientForm extends StatefulWidget {
  final Client? initial;
  final void Function(Client) onSubmit;

  const ClientForm({super.key, this.initial, required this.onSubmit});

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _surnameController = TextEditingController(text: widget.initial?.surname ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    widget.onSubmit(Client(
      id: widget.initial?.id,
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
    ));
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('client_name_field'),
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: _requiredValidator,
          ),
          TextFormField(
            key: const Key('client_surname_field'),
            controller: _surnameController,
            decoration: const InputDecoration(labelText: 'Surname'),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            child: Text(widget.initial == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}
