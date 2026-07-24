import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/models/material_item.dart';
import 'package:spese_cliente_app/providers/client_detail_provider.dart';
import 'package:spese_cliente_app/widgets/confirm_delete_dialog.dart';
import 'package:spese_cliente_app/widgets/material_form.dart';

class ClientDetailScreen extends StatelessWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClientDetailProvider>(
      create: (context) {
        final provider = ClientDetailProvider(
          context.read<MaterialRepository>(),
          client.id!,
        );
        provider.loadMaterials();
        return provider;
      },
      child: _ClientDetailBody(client: client),
    );
  }
}

class _ClientDetailBody extends StatelessWidget {
  final Client client;

  const _ClientDetailBody({required this.client});

  Future<void> _showMaterialDialog(BuildContext context, {MaterialItem? initial}) async {
    final provider = context.read<ClientDetailProvider>();
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MaterialForm(
            clientId: client.id!,
            initial: initial,
            onSubmit: (item) {
              Navigator.of(context).pop();
              if (initial == null) {
                provider.addMaterial(item);
              } else {
                provider.editMaterial(item);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MaterialItem item) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete material',
      message: 'Delete this material entry?',
    );
    if (confirmed && context.mounted) {
      await context.read<ClientDetailProvider>().deleteMaterial(item.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${client.name} ${client.surname}')),
      body: Consumer<ClientDetailProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total: ${provider.totalSpent.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: provider.materials.isEmpty && !provider.isLoading
                    ? const Center(child: Text('No materials yet for this client.'))
                    : ListView.builder(
                        itemCount: provider.materials.length,
                        itemBuilder: (context, index) {
                          final item = provider.materials[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} = ${item.totalPrice.toStringAsFixed(2)}',
                            ),
                            onTap: () => _showMaterialDialog(context, initial: item),
                            onLongPress: () => _confirmDelete(context, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMaterialDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
