import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/providers/client_provider.dart';
import 'package:spese_cliente_app/screens/client_detail_screen.dart';
import 'package:spese_cliente_app/widgets/client_form.dart';
import 'package:spese_cliente_app/widgets/confirm_delete_dialog.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
    });
  }

  Future<void> _showClientDialog({Client? initial}) async {
    final provider = context.read<ClientProvider>();
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClientForm(
            initial: initial,
            onSubmit: (client) {
              Navigator.of(context).pop();
              if (initial == null) {
                provider.addClient(client);
              } else {
                provider.editClient(client);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Client client) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete client',
      message: 'Delete ${client.name} ${client.surname} and all their materials?',
    );
    if (confirmed && mounted) {
      await context.read<ClientProvider>().deleteClient(client.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Consumer<ClientProvider>(
        builder: (context, provider, _) {
          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final message = provider.errorMessage;
              if (message == null) return;
              provider.clearError();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            });
          }
          if (provider.clients.isEmpty && !provider.isLoading) {
            return const Center(child: Text('No clients yet — tap + to add one.'));
          }
          return ListView.builder(
            itemCount: provider.clients.length,
            itemBuilder: (context, index) {
              final entry = provider.clients[index];
              return ListTile(
                title: Text('${entry.client.name} ${entry.client.surname}'),
                subtitle: Text('Total: ${entry.total.toStringAsFixed(2)}'),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClientDetailScreen(client: entry.client),
                    ),
                  );
                  if (context.mounted) {
                    context.read<ClientProvider>().loadClients();
                  }
                },
                onLongPress: () async {
                  final action = await showModalBottomSheet<String>(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit'),
                          onTap: () => Navigator.of(context).pop('edit'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Delete'),
                          onTap: () => Navigator.of(context).pop('delete'),
                        ),
                      ],
                    ),
                  );
                  if (action == 'edit') {
                    await _showClientDialog(initial: entry.client);
                  } else if (action == 'delete') {
                    await _confirmDelete(entry.client);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClientDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
