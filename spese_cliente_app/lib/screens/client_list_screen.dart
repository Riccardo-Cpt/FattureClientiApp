import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/l10n/strings.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/providers/client_provider.dart';
import 'package:spese_cliente_app/providers/locale_provider.dart';
import 'package:spese_cliente_app/screens/client_detail_screen.dart';
import 'package:spese_cliente_app/screens/stats_screen.dart';
import 'package:spese_cliente_app/widgets/client_form.dart';
import 'package:spese_cliente_app/widgets/confirm_delete_dialog.dart';
import 'package:spese_cliente_app/widgets/year_selector.dart';

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
      title: S.of(context).deleteClient,
      message: S.of(context).deleteClientMessage('${client.name} ${client.surname}'),
    );
    if (confirmed && mounted) {
      await context.read<ClientProvider>().deleteClient(client.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.clients,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            key: const Key('stats_button'),
            icon: const Icon(Icons.bar_chart),
            tooltip: s.statistics,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StatsScreen(
                  initialYear: context.read<ClientProvider>().selectedYear,
                ),
              ),
            ),
          ),
          PopupMenuButton<Locale>(
            key: const Key('language_button'),
            icon: const Icon(Icons.language),
            tooltip: s.language,
            onSelected: (locale) => context.read<LocaleProvider>().setLocale(locale),
            itemBuilder: (_) => [
              PopupMenuItem(value: const Locale('en'), child: Text(s.english)),
              PopupMenuItem(value: const Locale('it'), child: Text(s.italian)),
            ],
          ),
        ],
      ),
      body: Consumer<ClientProvider>(
        builder: (context, provider, _) {
          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (provider.errorMessage == null) return;
              provider.clearError();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.genericError)),
              );
            });
          }
          if (provider.clients.isEmpty && !provider.isLoading) {
            return Center(child: Text(s.noClients));
          }
          final grandTotal = provider.clients.fold(0.0, (sum, entry) => sum + entry.total);
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
                  s.grandTotal(grandTotal),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: provider.clients.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = provider.clients[index];
                    return ListTile(
                      title: Text('${entry.client.name} ${entry.client.surname}'),
                      subtitle: Text(
                        s.total(entry.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientDetailScreen(
                              client: entry.client,
                              initialYear: provider.selectedYear,
                            ),
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
                                title: Text(s.edit),
                                onTap: () => Navigator.of(context).pop('edit'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete),
                                title: Text(s.delete),
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
                ),
              ),
            ],
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
