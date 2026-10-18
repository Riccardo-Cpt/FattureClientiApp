import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/l10n/strings.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/models/material_item.dart';
import 'package:spese_cliente_app/providers/client_detail_provider.dart';
import 'package:spese_cliente_app/widgets/confirm_delete_dialog.dart';
import 'package:spese_cliente_app/widgets/material_form.dart';
import 'package:spese_cliente_app/widgets/year_selector.dart';

class ClientDetailScreen extends StatelessWidget {
  final Client client;
  final int? initialYear;

  const ClientDetailScreen({super.key, required this.client, this.initialYear});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClientDetailProvider>(
      create: (context) {
        final provider = ClientDetailProvider(
          context.read<MaterialRepository>(),
          client.id!,
          selectedYear: initialYear,
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
      title: S.of(context).deleteMaterial,
      message: S.of(context).deleteMaterialMessage,
    );
    if (confirmed && context.mounted) {
      await context.read<ClientDetailProvider>().deleteMaterial(item.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${client.name} ${client.surname}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ClientDetailProvider>(
        builder: (context, provider, _) {
          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              if (provider.errorMessage == null) return;
              provider.clearError();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.genericError)),
              );
            });
          }
          return Column(
            children: [
              YearSelector(
                years: provider.years,
                selected: provider.selectedYear,
                onChanged: provider.selectYear,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.total(provider.totalSpent),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: provider.materials.isEmpty && !provider.isLoading
                    ? Center(
                        child: Text(
                          provider.selectedYear == null ? s.noMaterials : s.noMaterialsYear,
                        ),
                      )
                    : ListView.separated(
                        itemCount: provider.materials.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = provider.materials[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              '${item.quantity} x ${s.money(item.unitPrice)} = ${s.money(item.totalPrice)}',
                            ),
                            trailing: IconButton(
                              key: Key('paid_toggle_${item.id}'),
                              icon: Icon(
                                item.paid ? Icons.check_circle : Icons.check_circle_outline,
                                color: item.paid ? Colors.green : null,
                              ),
                              tooltip: item.paid ? s.paid : s.markAsPaid,
                              onPressed: () =>
                                  context.read<ClientDetailProvider>().togglePaid(item),
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
