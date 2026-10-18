import 'package:flutter/widgets.dart';

/// Minimal in-app translations (English / Italian). The language is taken
/// from the surrounding [Localizations] locale, falling back to English.
class S {
  final bool isItalian;

  const S(this.isItalian);

  static const supportedLocales = [Locale('en'), Locale('it')];

  static S of(BuildContext context) =>
      S(Localizations.maybeLocaleOf(context)?.languageCode == 'it');

  String _t(String en, String it) => isItalian ? it : en;

  /// Formats an amount with two decimals and the locale's decimal separator.
  String money(double value) {
    final text = value.toStringAsFixed(2);
    return isItalian ? text.replaceAll('.', ',') : text;
  }

  String get appTitle => _t('Spese Cliente', 'Spese Cliente');
  String get genericError =>
      _t('Something went wrong, please try again', 'Qualcosa è andato storto, riprova');

  // Common
  String get add => _t('Add', 'Aggiungi');
  String get save => _t('Save', 'Salva');
  String get edit => _t('Edit', 'Modifica');
  String get delete => _t('Delete', 'Elimina');
  String get cancel => _t('Cancel', 'Annulla');
  String get required => _t('Required', 'Obbligatorio');
  String get name => _t('Name', 'Nome');
  String get surname => _t('Surname', 'Cognome');
  String get language => _t('Language', 'Lingua');
  String get english => 'English';
  String get italian => 'Italiano';
  String get allYears => _t('All years', 'Tutti gli anni');

  // Client list
  String get clients => _t('Clients', 'Clienti');
  String get noClients =>
      _t('No clients yet — tap + to add one.', 'Nessun cliente — premi + per aggiungerne uno.');
  String grandTotal(double v) => _t('Grand total: ${money(v)}', 'Totale generale: ${money(v)}');
  String total(double v) => _t('Total: ${money(v)}', 'Totale: ${money(v)}');
  String get deleteClient => _t('Delete client', 'Elimina cliente');
  String deleteClientMessage(String fullName) => _t(
        'Delete $fullName and all their materials?',
        'Eliminare $fullName e tutti i suoi materiali?',
      );
  String get statistics => _t('Statistics', 'Statistiche');

  // Client detail / material form
  String get noMaterials =>
      _t('No materials yet for this client.', 'Nessun materiale per questo cliente.');
  String get noMaterialsYear =>
      _t('No materials in this period.', 'Nessun materiale in questo periodo.');
  String get deleteMaterial => _t('Delete material', 'Elimina materiale');
  String get deleteMaterialMessage =>
      _t('Delete this material entry?', 'Eliminare questo materiale?');
  String get paid => _t('Paid', 'Pagato');
  String get markAsPaid => _t('Mark as paid', 'Segna come pagato');
  String get quantity => _t('Quantity', 'Quantità');
  String get unitPrice => _t('Unit price', 'Prezzo unitario');
  String date(String formatted) => _t('Date: $formatted', 'Data: $formatted');
  String get mustBeNumber => _t('Must be a number', 'Deve essere un numero');
  String get mustBePositive => _t('Must be greater than 0', 'Deve essere maggiore di 0');
  String get mustBeNonNegative => _t('Must be 0 or greater', 'Deve essere 0 o maggiore');

  // Statistics
  String get expensesByMonth => _t('Expenses by month', 'Spese per mese');
  String get expensesByYear => _t('Expenses by year', 'Spese per anno');
  String get totalSpent => _t('Total spent', 'Totale speso');
  String get unpaid => _t('Unpaid', 'Da pagare');
  String get monthlyAverage => _t('Monthly average', 'Media mensile');
  String get bestMonth => _t('Highest month', 'Mese più alto');
  String get entries => _t('Entries', 'Voci');
  String get topClients => _t('Top clients', 'Clienti principali');
  String get noExpenses => _t('No expenses recorded.', 'Nessuna spesa registrata.');
  String monthDetail(String month, int year) =>
      _t('$month $year — expenses', '$month $year — spese');
  String get tapMonthHint => _t('Tap a month to see its expenses.',
      'Tocca un mese per vederne le spese.');

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsIt = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
  ];

  /// [month] is 1-based.
  String monthName(int month) => (isItalian ? _monthsIt : _monthsEn)[month - 1];
  String monthShort(int month) => monthName(month).substring(0, 3);
}
