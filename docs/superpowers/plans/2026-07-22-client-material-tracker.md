# Client Material Expense Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter Android app that tracks materials purchased per client, with full add/edit/delete for both clients and material items, backed by local SQLite storage.

**Architecture:** Provider (`ChangeNotifier`) for state management, a `sqflite`-backed repository layer for persistence, and two screens (client list, client detail) built on top of that state. Layers: `models/` → `data/` (DB + repositories) → `providers/` → `screens/`/`widgets/`.

**Tech Stack:** Flutter 3.44.1 (already installed at `/home/luser/snap/flutter/common/flutter/bin/flutter`), Dart 3.12.1, `sqflite` + `path` packages, `provider` package, `intl` for date formatting.

## Global Constraints

- Platform: Android only (per spec). No cloud sync, no backend.
- Client fields: `name`, `surname` only — no contact info, no notes (per spec "Out of Scope").
- MaterialItem fields: `name`, `quantity` (double, > 0), `unitPrice` (double, ≥ 0), `totalPrice` (double, computed as `quantity * unitPrice`, stored), `date` (DateTime, defaults to today).
- Every delete (client or material) requires a confirmation dialog before it happens.
- All forms (client add/edit, material add/edit) share one widget each for add and edit — pre-filled when editing.
- Database errors are caught in the repository layer and surfaced via a snackbar, never crash the app.
- Empty states required: "No clients yet — tap + to add one." and "No materials yet for this client."
- This WSL2 environment has no `/dev/kvm`, so no Android emulator will be used. Verification is via `flutter test` (unit + widget tests) plus a real build (`flutter build apk`) for the user to install on their own physical Android device.
- The `flutter` command is not on PATH by default in this environment (`/snap/bin/flutter` is a broken shim) — every `flutter`/`dart` command in this plan must use the full path `/home/luser/snap/flutter/common/flutter/bin/flutter` or have that directory prepended to `PATH` first.

---

## Task 0: Android SDK setup (no emulator)

**Files:**
- Create: `~/android-sdk/` (cmdline-tools, platform-tools, build-tools — outside the project repo)
- Modify: `~/.bashrc` or equivalent shell profile (add `ANDROID_SDK_ROOT`, `PATH` entries) — only if the user confirms this is wanted; otherwise export inline per command.

**Interfaces:**
- Produces: a working `flutter build apk` command path for Task 8's manual verification step. No code interfaces (infrastructure-only task).

- [ ] **Step 1: Download Android command-line tools**

```bash
mkdir -p ~/android-sdk/cmdline-tools
cd /tmp
curl -o commandlinetools.zip "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
unzip -q commandlinetools.zip -d ~/android-sdk/cmdline-tools
mv ~/android-sdk/cmdline-tools/cmdline-tools ~/android-sdk/cmdline-tools/latest
```

Expected: `~/android-sdk/cmdline-tools/latest/bin/sdkmanager` exists.

- [ ] **Step 2: Verify sdkmanager runs**

```bash
~/android-sdk/cmdline-tools/latest/bin/sdkmanager --version
```

Expected: prints a version number (e.g. `11.0`), no Java errors. If Java is missing, install via `sudo apt install -y openjdk-17-jdk` first (already confirmed present on this machine — `openjdk 17.0.19`).

- [ ] **Step 3: Install platform-tools and one platform + build-tools**

```bash
yes | ~/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=$HOME/android-sdk "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

Expected: downloads complete without error; `~/android-sdk/platform-tools/adb` and `~/android-sdk/build-tools/34.0.0/aapt` exist afterward.

- [ ] **Step 4: Accept licenses**

```bash
yes | ~/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=$HOME/android-sdk --licenses
```

Expected: all licenses report as accepted (no "not accepted" lines at the end).

- [ ] **Step 5: Point Flutter at the SDK**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter config --android-sdk $HOME/android-sdk
/home/luser/snap/flutter/common/flutter/bin/flutter doctor
```

Expected: the "Android toolchain" section now shows `[✓]` instead of `[✗]` (a warning about missing licenses acceptance for a specific component is OK as long as the main checkmark is green; if not, re-run Step 4).

- [ ] **Step 6: No commit needed**

This task only sets up local machine tooling, not project files — nothing to commit.

---

## Task 1: Project scaffold

**Files:**
- Create: `spese_cliente_app/` (Flutter project, created via `flutter create`)
- Modify: `spese_cliente_app/pubspec.yaml` (add dependencies)

**Interfaces:**
- Produces: a runnable Flutter project skeleton with `sqflite`, `path`, `provider`, `intl` available for import in later tasks.

- [ ] **Step 1: Create the Flutter project**

```bash
cd /home/luser/claude_projects/SpeseClienteApp
/home/luser/snap/flutter/common/flutter/bin/flutter create --org com.spesecliente --project-name spese_cliente_app --platforms=android spese_cliente_app
```

Expected: a new `spese_cliente_app/` directory containing `lib/main.dart`, `android/`, `pubspec.yaml`, etc.

- [ ] **Step 2: Add dependencies**

Edit `spese_cliente_app/pubspec.yaml`, in the `dependencies:` section (below `flutter: sdk: flutter`), add:

```yaml
  sqflite: ^2.4.1
  path: ^1.9.0
  provider: ^6.1.2
  intl: ^0.19.0
```

- [ ] **Step 3: Fetch packages**

```bash
cd /home/luser/claude_projects/SpeseClienteApp/spese_cliente_app
/home/luser/snap/flutter/common/flutter/bin/flutter pub get
```

Expected: `Got dependencies!` with no version resolution errors.

- [ ] **Step 4: Verify the default template still builds/tests clean**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test
```

Expected: the default counter-app widget test passes (`00:0X +1: All tests passed!`).

- [ ] **Step 5: Commit**

```bash
cd /home/luser/claude_projects/SpeseClienteApp
git add spese_cliente_app
git commit -m "Scaffold Flutter project with sqflite, provider, intl dependencies"
```

---

## Task 2: Models — `Client` and `MaterialItem`

**Files:**
- Create: `spese_cliente_app/lib/models/client.dart`
- Create: `spese_cliente_app/lib/models/material_item.dart`
- Test: `spese_cliente_app/test/models/client_test.dart`
- Test: `spese_cliente_app/test/models/material_item_test.dart`

**Interfaces:**
- Produces:
  - `Client(int? id, String name, String surname)` with `Map<String, Object?> toMap()` and `Client.fromMap(Map<String, Object?> map)`.
  - `MaterialItem(int? id, int clientId, String name, double quantity, double unitPrice, DateTime date)` where `totalPrice` is a computed getter (`quantity * unitPrice`), plus `Map<String, Object?> toMap()` and `MaterialItem.fromMap(Map<String, Object?> map)`. Dates are stored/read as ISO-8601 strings via `DateTime.toIso8601String()` / `DateTime.parse()`.

- [ ] **Step 1: Write failing test for `Client`**

Create `spese_cliente_app/test/models/client_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/models/client.dart';

void main() {
  test('Client toMap/fromMap round-trip', () {
    final client = Client(id: 1, name: 'Mario', surname: 'Rossi');

    final map = client.toMap();
    expect(map, {'id': 1, 'name': 'Mario', 'surname': 'Rossi'});

    final rebuilt = Client.fromMap(map);
    expect(rebuilt.id, 1);
    expect(rebuilt.name, 'Mario');
    expect(rebuilt.surname, 'Rossi');
  });

  test('Client toMap omits id when null (for insert)', () {
    final client = Client(name: 'Anna', surname: 'Bianchi');
    final map = client.toMap();
    expect(map.containsKey('id'), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/luser/claude_projects/SpeseClienteApp/spese_cliente_app
/home/luser/snap/flutter/common/flutter/bin/flutter test test/models/client_test.dart
```

Expected: FAIL — `Error: Couldn't resolve the package 'spese_cliente_app'` or `Target of URI doesn't exist: 'package:spese_cliente_app/models/client.dart'`.

- [ ] **Step 3: Implement `Client`**

Create `spese_cliente_app/lib/models/client.dart`:

```dart
class Client {
  final int? id;
  final String name;
  final String surname;

  Client({this.id, required this.name, required this.surname});

  Map<String, Object?> toMap() {
    final map = <String, Object?>{'name': name, 'surname': surname};
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Client.fromMap(Map<String, Object?> map) {
    return Client(
      id: map['id'] as int?,
      name: map['name'] as String,
      surname: map['surname'] as String,
    );
  }

  Client copyWith({int? id, String? name, String? surname}) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/models/client_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Write failing test for `MaterialItem`**

Create `spese_cliente_app/test/models/material_item_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/models/material_item.dart';

void main() {
  test('totalPrice is computed from quantity and unitPrice', () {
    final item = MaterialItem(
      clientId: 1,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    );

    expect(item.totalPrice, 45.0);
  });

  test('toMap/fromMap round-trip preserves fields and date', () {
    final date = DateTime(2026, 7, 20);
    final item = MaterialItem(
      id: 5,
      clientId: 2,
      name: 'Bricks',
      quantity: 10,
      unitPrice: 2.5,
      date: date,
    );

    final map = item.toMap();
    expect(map['id'], 5);
    expect(map['clientId'], 2);
    expect(map['name'], 'Bricks');
    expect(map['quantity'], 10.0);
    expect(map['unitPrice'], 2.5);
    expect(map['date'], date.toIso8601String());

    final rebuilt = MaterialItem.fromMap(map);
    expect(rebuilt.id, 5);
    expect(rebuilt.clientId, 2);
    expect(rebuilt.name, 'Bricks');
    expect(rebuilt.quantity, 10.0);
    expect(rebuilt.unitPrice, 2.5);
    expect(rebuilt.date, date);
    expect(rebuilt.totalPrice, 25.0);
  });

  test('toMap omits id when null (for insert)', () {
    final item = MaterialItem(
      clientId: 1,
      name: 'Sand',
      quantity: 1,
      unitPrice: 5,
      date: DateTime(2026, 7, 20),
    );
    expect(item.toMap().containsKey('id'), isFalse);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/models/material_item_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/models/material_item.dart'`.

- [ ] **Step 7: Implement `MaterialItem`**

Create `spese_cliente_app/lib/models/material_item.dart`:

```dart
class MaterialItem {
  final int? id;
  final int clientId;
  final String name;
  final double quantity;
  final double unitPrice;
  final DateTime date;

  MaterialItem({
    this.id,
    required this.clientId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.date,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'clientId': clientId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'date': date.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory MaterialItem.fromMap(Map<String, Object?> map) {
    return MaterialItem(
      id: map['id'] as int?,
      clientId: map['clientId'] as int,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }

  MaterialItem copyWith({
    int? id,
    int? clientId,
    String? name,
    double? quantity,
    double? unitPrice,
    DateTime? date,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      date: date ?? this.date,
    );
  }
}
```

- [ ] **Step 8: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/models/material_item_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 9: Commit**

```bash
cd /home/luser/claude_projects/SpeseClienteApp
git add spese_cliente_app/lib/models spese_cliente_app/test/models
git commit -m "Add Client and MaterialItem models with map serialization"
```

---

## Task 3: `DatabaseHelper` — schema and raw access

**Files:**
- Create: `spese_cliente_app/lib/data/database_helper.dart`
- Test: `spese_cliente_app/test/data/database_helper_test.dart`
- Modify: `spese_cliente_app/pubspec.yaml` (add `sqflite_common_ffi` as a dev dependency, for running sqflite in plain Dart tests without an Android device)

**Interfaces:**
- Consumes: nothing from earlier tasks (models are used only by repositories, not by `DatabaseHelper` itself).
- Produces: `DatabaseHelper` singleton with `Future<Database> get database` getter. Schema: table `clients(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, surname TEXT NOT NULL)` and table `materials(id INTEGER PRIMARY KEY AUTOINCREMENT, clientId INTEGER NOT NULL, name TEXT NOT NULL, quantity REAL NOT NULL, unitPrice REAL NOT NULL, date TEXT NOT NULL, FOREIGN KEY(clientId) REFERENCES clients(id) ON DELETE CASCADE)`.

- [ ] **Step 1: Add `sqflite_common_ffi` dev dependency**

Edit `spese_cliente_app/pubspec.yaml`, in `dev_dependencies:` (below `flutter_test:`), add:

```yaml
  sqflite_common_ffi: ^2.3.4
```

Run:

```bash
cd /home/luser/claude_projects/SpeseClienteApp/spese_cliente_app
/home/luser/snap/flutter/common/flutter/bin/flutter pub get
```

Expected: `Got dependencies!`.

- [ ] **Step 2: Write failing test for schema creation**

Create `spese_cliente_app/test/data/database_helper_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('database creates clients and materials tables', () async {
    final helper = DatabaseHelper(inMemory: true);
    final db = await helper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('clients','materials')",
    );
    final names = tables.map((row) => row['name']).toSet();

    expect(names, {'clients', 'materials'});

    await helper.close();
  });

  test('inserting a material with unknown clientId still works (no FK enforcement needed for insert)', () async {
    final helper = DatabaseHelper(inMemory: true);
    final db = await helper.database;

    final clientId = await db.insert('clients', {'name': 'Mario', 'surname': 'Rossi'});
    final materialId = await db.insert('materials', {
      'clientId': clientId,
      'name': 'Cement',
      'quantity': 3.0,
      'unitPrice': 15.0,
      'date': DateTime(2026, 7, 20).toIso8601String(),
    });

    expect(materialId, greaterThan(0));

    await helper.close();
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/data/database_helper_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/data/database_helper.dart'`.

- [ ] **Step 4: Implement `DatabaseHelper`**

Create `spese_cliente_app/lib/data/database_helper.dart`:

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  final bool inMemory;
  Database? _db;

  DatabaseHelper({this.inMemory = false});

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = inMemory ? inMemoryDatabasePath : join(await getDatabasesPath(), 'spese_cliente.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            surname TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE materials (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clientId INTEGER NOT NULL,
            name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unitPrice REAL NOT NULL,
            date TEXT NOT NULL,
            FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
```

Note: `getDatabasesPath()` requires a real Android/iOS platform at runtime (Task 4's app code), but is never called when `inMemory: true` (used by tests), so the test above does not need platform channel mocking.

- [ ] **Step 5: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/data/database_helper_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
cd /home/luser/claude_projects/SpeseClienteApp
git add spese_cliente_app/pubspec.yaml spese_cliente_app/pubspec.lock spese_cliente_app/lib/data/database_helper.dart spese_cliente_app/test/data/database_helper_test.dart
git commit -m "Add DatabaseHelper with clients/materials schema"
```

---

## Task 4: `ClientRepository`

**Files:**
- Create: `spese_cliente_app/lib/data/client_repository.dart`
- Test: `spese_cliente_app/test/data/client_repository_test.dart`

**Interfaces:**
- Consumes: `DatabaseHelper` (Task 3, constructor `DatabaseHelper({bool inMemory})`, getter `Future<Database> get database`), `Client` model (Task 2, `toMap()`/`Client.fromMap()`).
- Produces: `ClientRepository(DatabaseHelper helper)` with:
  - `Future<int> insertClient(Client client)` → returns new id.
  - `Future<List<Client>> getAllClients()` → ordered by surname, then name.
  - `Future<void> updateClient(Client client)`.
  - `Future<void> deleteClient(int id)` → also deletes that client's materials (relies on `ON DELETE CASCADE` from Task 3's schema, since `PRAGMA foreign_keys = ON` is set in `onConfigure`).
  - `Future<double> getTotalSpentForClient(int clientId)` → `SUM(quantity * unitPrice)` over that client's materials, `0.0` if none.

- [ ] **Step 1: Write failing tests**

Create `spese_cliente_app/test/data/client_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/models/client.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late ClientRepository repo;

  setUp(() {
    helper = DatabaseHelper(inMemory: true);
    repo = ClientRepository(helper);
  });

  tearDown(() async {
    await helper.close();
  });

  test('insertClient returns a positive id, getAllClients returns it back', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    expect(id, greaterThan(0));

    final all = await repo.getAllClients();
    expect(all.length, 1);
    expect(all.first.name, 'Mario');
    expect(all.first.surname, 'Rossi');
  });

  test('getAllClients orders by surname then name', () async {
    await repo.insertClient(Client(name: 'Zara', surname: 'Alpha'));
    await repo.insertClient(Client(name: 'Anna', surname: 'Alpha'));
    await repo.insertClient(Client(name: 'Bob', surname: 'Beta'));

    final all = await repo.getAllClients();
    expect(all.map((c) => '${c.surname}-${c.name}').toList(), [
      'Alpha-Anna',
      'Alpha-Zara',
      'Beta-Bob',
    ]);
  });

  test('updateClient persists changes', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    await repo.updateClient(Client(id: id, name: 'Mario', surname: 'Verdi'));

    final all = await repo.getAllClients();
    expect(all.first.surname, 'Verdi');
  });

  test('deleteClient removes the client', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    await repo.deleteClient(id);

    final all = await repo.getAllClients();
    expect(all, isEmpty);
  });

  test('deleteClient cascades to that client materials', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    final db = await helper.database;
    await db.insert('materials', {
      'clientId': id,
      'name': 'Cement',
      'quantity': 1.0,
      'unitPrice': 10.0,
      'date': DateTime(2026, 7, 20).toIso8601String(),
    });

    await repo.deleteClient(id);

    final remaining = await db.query('materials');
    expect(remaining, isEmpty);
  });

  test('getTotalSpentForClient sums quantity * unitPrice, 0.0 when none', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    final db = await helper.database;

    expect(await repo.getTotalSpentForClient(id), 0.0);

    await db.insert('materials', {
      'clientId': id,
      'name': 'Cement',
      'quantity': 3.0,
      'unitPrice': 15.0,
      'date': DateTime(2026, 7, 20).toIso8601String(),
    });
    await db.insert('materials', {
      'clientId': id,
      'name': 'Bricks',
      'quantity': 10.0,
      'unitPrice': 2.5,
      'date': DateTime(2026, 7, 20).toIso8601String(),
    });

    expect(await repo.getTotalSpentForClient(id), 70.0);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /home/luser/claude_projects/SpeseClienteApp/spese_cliente_app
/home/luser/snap/flutter/common/flutter/bin/flutter test test/data/client_repository_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/data/client_repository.dart'`.

- [ ] **Step 3: Implement `ClientRepository`**

Create `spese_cliente_app/lib/data/client_repository.dart`:

```dart
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/models/client.dart';

class ClientRepository {
  final DatabaseHelper _helper;

  ClientRepository(this._helper);

  Future<int> insertClient(Client client) async {
    final db = await _helper.database;
    return db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final db = await _helper.database;
    final rows = await db.query('clients', orderBy: 'surname, name');
    return rows.map(Client.fromMap).toList();
  }

  Future<void> updateClient(Client client) async {
    final db = await _helper.database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(int id) async {
    final db = await _helper.database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalSpentForClient(int clientId) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity * unitPrice) as total FROM materials WHERE clientId = ?',
      [clientId],
    );
    final total = result.first['total'] as double?;
    return total ?? 0.0;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/data/client_repository_test.dart
```

Expected: `All tests passed!` (6 tests).

- [ ] **Step 5: Commit**

```bash
cd /home/luser/claude_projects/SpeseClienteApp
git add spese_cliente_app/lib/data/client_repository.dart spese_cliente_app/test/data/client_repository_test.dart
git commit -m "Add ClientRepository with CRUD and total-spent calculation"
```

---

## Task 5: `MaterialRepository`

**Files:**
- Create: `spese_cliente_app/lib/data/material_repository.dart`
- Test: `spese_cliente_app/test/data/material_repository_test.dart`

**Interfaces:**
- Consumes: `DatabaseHelper` (Task 3), `MaterialItem` model (Task 2, `toMap()`/`MaterialItem.fromMap()`).
- Produces: `MaterialRepository(DatabaseHelper helper)` with:
  - `Future<int> insertMaterial(MaterialItem item)` → returns new id.
  - `Future<List<MaterialItem>> getMaterialsForClient(int clientId)` → ordered by date descending.
  - `Future<void> updateMaterial(MaterialItem item)`.
  - `Future<void> deleteMaterial(int id)`.

- [ ] **Step 1: Write failing tests**

Create `spese_cliente_app/test/data/material_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/models/material_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late ClientRepository clientRepo;
  late MaterialRepository materialRepo;
  late int clientId;

  setUp(() async {
    helper = DatabaseHelper(inMemory: true);
    clientRepo = ClientRepository(helper);
    materialRepo = MaterialRepository(helper);
    clientId = await clientRepo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
  });

  tearDown(() async {
    await helper.close();
  });

  test('insertMaterial returns a positive id', () async {
    final id = await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    expect(id, greaterThan(0));
  });

  test('getMaterialsForClient returns only that client materials, newest first', () async {
    await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 1),
    ));
    await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Bricks',
      quantity: 10,
      unitPrice: 2.5,
      date: DateTime(2026, 7, 20),
    ));

    final otherClientId = await clientRepo.insertClient(Client(name: 'Anna', surname: 'Bianchi'));
    await materialRepo.insertMaterial(MaterialItem(
      clientId: otherClientId,
      name: 'Sand',
      quantity: 1,
      unitPrice: 5,
      date: DateTime(2026, 7, 10),
    ));

    final results = await materialRepo.getMaterialsForClient(clientId);
    expect(results.length, 2);
    expect(results.first.name, 'Bricks');
    expect(results.last.name, 'Cement');
  });

  test('updateMaterial persists changes', () async {
    final id = await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));

    await materialRepo.updateMaterial(MaterialItem(
      id: id,
      clientId: clientId,
      name: 'Cement',
      quantity: 5,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));

    final results = await materialRepo.getMaterialsForClient(clientId);
    expect(results.first.quantity, 5.0);
    expect(results.first.totalPrice, 75.0);
  });

  test('deleteMaterial removes only that entry', () async {
    final keepId = await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    final removeId = await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Bricks',
      quantity: 10,
      unitPrice: 2.5,
      date: DateTime(2026, 7, 21),
    ));

    await materialRepo.deleteMaterial(removeId);

    final results = await materialRepo.getMaterialsForClient(clientId);
    expect(results.length, 1);
    expect(results.first.id, keepId);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /home/luser/claude_projects/SpeseClienteApp/spese_cliente_app
/home/luser/snap/flutter/common/flutter/bin/flutter test test/data/material_repository_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/data/material_repository.dart'`.

- [ ] **Step 3: Implement `MaterialRepository`**

Create `spese_cliente_app/lib/data/material_repository.dart`:

```dart
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/models/material_item.dart';

class MaterialRepository {
  final DatabaseHelper _helper;

  MaterialRepository(this._helper);

  Future<int> insertMaterial(MaterialItem item) async {
    final db = await _helper.database;
    return db.insert('materials', item.toMap());
  }

  Future<List<MaterialItem>> getMaterialsForClient(int clientId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'materials',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );
    return rows.map(MaterialItem.fromMap).toList();
  }

  Future<void> updateMaterial(MaterialItem item) async {
    final db = await _helper.database;
    await db.update(
      'materials',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteMaterial(int id) async {
    final db = await _helper.database;
    await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/data/material_repository_test.dart
```

Expected: `All tests passed!` (4 tests).

- [ ] **Step 5: Commit**

```bash
cd /home/luser/claude_projects/SpeseClienteApp
git add spese_cliente_app/lib/data/material_repository.dart spese_cliente_app/test/data/material_repository_test.dart
git commit -m "Add MaterialRepository with CRUD for client materials"
```

---

## Task 6: `ClientProvider` and `ClientDetailProvider`

**Files:**
- Create: `spese_cliente_app/lib/providers/client_provider.dart`
- Create: `spese_cliente_app/lib/providers/client_detail_provider.dart`
- Test: `spese_cliente_app/test/providers/client_provider_test.dart`
- Test: `spese_cliente_app/test/providers/client_detail_provider_test.dart`

**Interfaces:**
- Consumes: `ClientRepository` (Task 4: `insertClient`, `getAllClients`, `updateClient`, `deleteClient`, `getTotalSpentForClient`), `MaterialRepository` (Task 5: `insertMaterial`, `getMaterialsForClient`, `updateMaterial`, `deleteMaterial`), `Client`/`MaterialItem` models (Task 2).
- Produces:
  - `ClientProvider(ClientRepository repo)` extends `ChangeNotifier`. State: `List<ClientWithTotal> clients` (empty until loaded), `bool isLoading`. `class ClientWithTotal { final Client client; final double total; }`. Methods: `Future<void> loadClients()`, `Future<void> addClient(Client client)`, `Future<void> editClient(Client client)`, `Future<void> deleteClient(int id)` — each mutating method reloads `clients` and calls `notifyListeners()` on success; on repository error, sets `String? errorMessage` and calls `notifyListeners()` instead of throwing.
  - `ClientDetailProvider(MaterialRepository repo, int clientId)` extends `ChangeNotifier`. State: `List<MaterialItem> materials`, `bool isLoading`, `String? errorMessage`, `double get totalSpent` (computed getter: sum of `totalPrice` over `materials`). Methods: `Future<void> loadMaterials()`, `Future<void> addMaterial(MaterialItem item)`, `Future<void> editMaterial(MaterialItem item)`, `Future<void> deleteMaterial(int id)` — same reload/notify/error pattern.

- [ ] **Step 1: Write failing tests for `ClientProvider`**

Create `spese_cliente_app/test/providers/client_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/models/material_item.dart';
import 'package:spese_cliente_app/providers/client_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late ClientProvider provider;
  late MaterialRepository materialRepo;

  setUp(() {
    helper = DatabaseHelper(inMemory: true);
    provider = ClientProvider(ClientRepository(helper));
    materialRepo = MaterialRepository(helper);
  });

  tearDown(() async {
    await helper.close();
  });

  test('loadClients starts empty, then populates after addClient', () async {
    await provider.loadClients();
    expect(provider.clients, isEmpty);

    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));

    expect(provider.clients.length, 1);
    expect(provider.clients.first.client.name, 'Mario');
    expect(provider.clients.first.total, 0.0);
  });

  test('addClient total reflects that client materials sum', () async {
    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));
    final clientId = provider.clients.first.client.id!;

    await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));

    await provider.loadClients();

    expect(provider.clients.first.total, 45.0);
  });

  test('editClient updates the stored client', () async {
    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));
    final client = provider.clients.first.client;

    await provider.editClient(Client(id: client.id, name: 'Mario', surname: 'Verdi'));

    expect(provider.clients.first.client.surname, 'Verdi');
  });

  test('deleteClient removes it from the list', () async {
    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));
    final id = provider.clients.first.client.id!;

    await provider.deleteClient(id);

    expect(provider.clients, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/luser/claude_projects/SpeseClienteApp/spese_cliente_app
/home/luser/snap/flutter/common/flutter/bin/flutter test test/providers/client_provider_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/providers/client_provider.dart'`.

- [ ] **Step 3: Implement `ClientProvider`**

Create `spese_cliente_app/lib/providers/client_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/models/client.dart';

class ClientWithTotal {
  final Client client;
  final double total;

  ClientWithTotal(this.client, this.total);
}

class ClientProvider extends ChangeNotifier {
  final ClientRepository _repo;

  ClientProvider(this._repo);

  List<ClientWithTotal> clients = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadClients() async {
    isLoading = true;
    notifyListeners();

    try {
      final all = await _repo.getAllClients();
      final withTotals = <ClientWithTotal>[];
      for (final client in all) {
        final total = await _repo.getTotalSpentForClient(client.id!);
        withTotals.add(ClientWithTotal(client, total));
      }
      clients = withTotals;
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClient(Client client) async {
    try {
      await _repo.insertClient(client);
      errorMessage = null;
      await loadClients();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  Future<void> editClient(Client client) async {
    try {
      await _repo.updateClient(client);
      errorMessage = null;
      await loadClients();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  Future<void> deleteClient(int id) async {
    try {
      await _repo.deleteClient(id);
      errorMessage = null;
      await loadClients();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/providers/client_provider_test.dart
```

Expected: `All tests passed!` (4 tests).

- [ ] **Step 5: Write failing tests for `ClientDetailProvider`**

Create `spese_cliente_app/test/providers/client_detail_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/models/material_item.dart';
import 'package:spese_cliente_app/providers/client_detail_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late int clientId;
  late ClientDetailProvider provider;

  setUp(() async {
    helper = DatabaseHelper(inMemory: true);
    final clientId0 = await ClientRepository(helper).insertClient(
      Client(name: 'Mario', surname: 'Rossi'),
    );
    clientId = clientId0;
    provider = ClientDetailProvider(MaterialRepository(helper), clientId);
  });

  tearDown(() async {
    await helper.close();
  });

  test('loadMaterials starts empty, totalSpent is 0.0', () async {
    await provider.loadMaterials();
    expect(provider.materials, isEmpty);
    expect(provider.totalSpent, 0.0);
  });

  test('addMaterial adds it and updates totalSpent', () async {
    await provider.addMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));

    expect(provider.materials.length, 1);
    expect(provider.totalSpent, 45.0);
  });

  test('editMaterial updates quantity and totalSpent', () async {
    await provider.addMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    final item = provider.materials.first;

    await provider.editMaterial(item.copyWith(quantity: 5));

    expect(provider.materials.first.quantity, 5.0);
    expect(provider.totalSpent, 75.0);
  });

  test('deleteMaterial removes it and updates totalSpent', () async {
    await provider.addMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    final id = provider.materials.first.id!;

    await provider.deleteMaterial(id);

    expect(provider.materials, isEmpty);
    expect(provider.totalSpent, 0.0);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/providers/client_detail_provider_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/providers/client_detail_provider.dart'`.

- [ ] **Step 7: Implement `ClientDetailProvider`**

Create `spese_cliente_app/lib/providers/client_detail_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/material_item.dart';

class ClientDetailProvider extends ChangeNotifier {
  final MaterialRepository _repo;
  final int clientId;

  ClientDetailProvider(this._repo, this.clientId);

  List<MaterialItem> materials = [];
  bool isLoading = false;
  String? errorMessage;

  double get totalSpent =>
      materials.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> loadMaterials() async {
    isLoading = true;
    notifyListeners();

    try {
      materials = await _repo.getMaterialsForClient(clientId);
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMaterial(MaterialItem item) async {
    try {
      await _repo.insertMaterial(item);
      errorMessage = null;
      await loadMaterials();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  Future<void> editMaterial(MaterialItem item) async {
    try {
      await _repo.updateMaterial(item);
      errorMessage = null;
      await loadMaterials();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await _repo.deleteMaterial(id);
      errorMessage = null;
      await loadMaterials();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }
}
```

- [ ] **Step 8: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/providers/client_detail_provider_test.dart
```

Expected: `All tests passed!` (4 tests).

- [ ] **Step 9: Commit**

```bash
cd /home/luser/claude_projects/SpeseClienteApp
git add spese_cliente_app/lib/providers spese_cliente_app/test/providers
git commit -m "Add ClientProvider and ClientDetailProvider with error handling"
```

---

## Task 7: Shared widgets — confirm-delete dialog and form fields

**Files:**
- Create: `spese_cliente_app/lib/widgets/confirm_delete_dialog.dart`
- Create: `spese_cliente_app/lib/widgets/client_form.dart`
- Create: `spese_cliente_app/lib/widgets/material_form.dart`
- Test: `spese_cliente_app/test/widgets/confirm_delete_dialog_test.dart`
- Test: `spese_cliente_app/test/widgets/client_form_test.dart`
- Test: `spese_cliente_app/test/widgets/material_form_test.dart`

**Interfaces:**
- Produces:
  - `Future<bool> showConfirmDeleteDialog(BuildContext context, {required String title, required String message})` → shows an `AlertDialog` with Cancel/Delete buttons, resolves `true` if Delete tapped, `false` (or on dismiss) otherwise.
  - `ClientForm` widget: `ClientForm({Key? key, Client? initial, required void Function(Client) onSubmit})`. Renders two `TextFormField`s (name, surname) inside a `Form`, validates non-empty (trimmed), and a submit button that calls `onSubmit` with a `Client` built from the form (preserving `initial?.id` if editing).
  - `MaterialForm` widget: `MaterialForm({Key? key, required int clientId, MaterialItem? initial, required void Function(MaterialItem) onSubmit})`. Renders name field, quantity field (numeric, > 0), unit price field (numeric, ≥ 0), a live-updating total display (`quantity * unitPrice`, recomputed on every keystroke via `TextEditingController` listeners and `setState`), and a date picker field (defaults to `initial?.date ?? DateTime.now()`). Submit button calls `onSubmit` with a `MaterialItem` built from the form (preserving `initial?.id` if editing).

- [ ] **Step 1: Write failing test for confirm-delete dialog**

Create `spese_cliente_app/test/widgets/confirm_delete_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/widgets/confirm_delete_dialog.dart';

void main() {
  testWidgets('tapping Delete resolves true', (tester) async {
    bool? result;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDeleteDialog(
                context,
                title: 'Delete client',
                message: 'Are you sure?',
              );
            },
            child: const Text('Trigger'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('tapping Cancel resolves false', (tester) async {
    bool? result;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDeleteDialog(
                context,
                title: 'Delete client',
                message: 'Are you sure?',
              );
            },
            child: const Text('Trigger'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/luser/claude_projects/SpeseClienteApp/spese_cliente_app
/home/luser/snap/flutter/common/flutter/bin/flutter test test/widgets/confirm_delete_dialog_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/widgets/confirm_delete_dialog.dart'`.

- [ ] **Step 3: Implement confirm-delete dialog**

Create `spese_cliente_app/lib/widgets/confirm_delete_dialog.dart`:

```dart
import 'package:flutter/material.dart';

Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/widgets/confirm_delete_dialog_test.dart
```

Expected: `All tests passed!` (2 tests).

- [ ] **Step 5: Write failing tests for `ClientForm`**

Create `spese_cliente_app/test/widgets/client_form_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/widgets/client_form.dart';

void main() {
  testWidgets('submitting blank name shows validation error and does not call onSubmit', (tester) async {
    Client? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClientForm(onSubmit: (c) => submitted = c),
      ),
    ));

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted, isNull);
    expect(find.text('Required'), findsWidgets);
  });

  testWidgets('submitting valid name and surname calls onSubmit with trimmed values', (tester) async {
    Client? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClientForm(onSubmit: (c) => submitted = c),
      ),
    ));

    await tester.enterText(find.byKey(const Key('client_name_field')), ' Mario ');
    await tester.enterText(find.byKey(const Key('client_surname_field')), ' Rossi ');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted?.name, 'Mario');
    expect(submitted?.surname, 'Rossi');
  });

  testWidgets('pre-fills fields and preserves id when editing', (tester) async {
    Client? submitted;
    final initial = Client(id: 7, name: 'Anna', surname: 'Bianchi');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClientForm(initial: initial, onSubmit: (c) => submitted = c),
      ),
    ));

    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Bianchi'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted?.id, 7);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/widgets/client_form_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/widgets/client_form.dart'`.

- [ ] **Step 7: Implement `ClientForm`**

Create `spese_cliente_app/lib/widgets/client_form.dart`:

```dart
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
```

- [ ] **Step 8: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/widgets/client_form_test.dart
```

Expected: `All tests passed!` (3 tests).

- [ ] **Step 9: Write failing tests for `MaterialForm`**

Create `spese_cliente_app/test/widgets/material_form_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/models/material_item.dart';
import 'package:spese_cliente_app/widgets/material_form.dart';

void main() {
  testWidgets('submitting blank name shows validation error and does not call onSubmit', (tester) async {
    MaterialItem? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialForm(clientId: 1, onSubmit: (m) => submitted = m),
      ),
    ));

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted, isNull);
    expect(find.text('Required'), findsWidgets);
  });

  testWidgets('non-positive quantity is rejected', (tester) async {
    MaterialItem? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialForm(clientId: 1, onSubmit: (m) => submitted = m),
      ),
    ));

    await tester.enterText(find.byKey(const Key('material_name_field')), 'Cement');
    await tester.enterText(find.byKey(const Key('material_quantity_field')), '0');
    await tester.enterText(find.byKey(const Key('material_unit_price_field')), '15');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted, isNull);
    expect(find.text('Must be greater than 0'), findsOneWidget);
  });

  testWidgets('valid input computes live total and calls onSubmit', (tester) async {
    MaterialItem? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialForm(clientId: 1, onSubmit: (m) => submitted = m),
      ),
    ));

    await tester.enterText(find.byKey(const Key('material_name_field')), 'Cement');
    await tester.enterText(find.byKey(const Key('material_quantity_field')), '3');
    await tester.enterText(find.byKey(const Key('material_unit_price_field')), '15');
    await tester.pump();

    expect(find.text('Total: 45.00'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted?.name, 'Cement');
    expect(submitted?.quantity, 3.0);
    expect(submitted?.unitPrice, 15.0);
    expect(submitted?.clientId, 1);
    expect(submitted?.totalPrice, 45.0);
  });

  testWidgets('pre-fills fields and preserves id when editing', (tester) async {
    MaterialItem? submitted;
    final initial = MaterialItem(
      id: 9,
      clientId: 1,
      name: 'Bricks',
      quantity: 10,
      unitPrice: 2.5,
      date: DateTime(2026, 7, 20),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialForm(clientId: 1, initial: initial, onSubmit: (m) => submitted = m),
      ),
    ));

    expect(find.text('Bricks'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted?.id, 9);
  });
}
```

- [ ] **Step 10: Run test to verify it fails**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/widgets/material_form_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/widgets/material_form.dart'`.

- [ ] **Step 11: Implement `MaterialForm`**

Create `spese_cliente_app/lib/widgets/material_form.dart`:

```dart
import 'package:flutter/material.dart';
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
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _positiveQuantityValidator(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) {
      return 'Must be a number';
    }
    if (parsed <= 0) {
      return 'Must be greater than 0';
    }
    return null;
  }

  String? _nonNegativePriceValidator(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) {
      return 'Must be a number';
    }
    if (parsed < 0) {
      return 'Must be 0 or greater';
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('material_name_field'),
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: _requiredValidator,
          ),
          TextFormField(
            key: const Key('material_quantity_field'),
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _positiveQuantityValidator,
          ),
          TextFormField(
            key: const Key('material_unit_price_field'),
            controller: _unitPriceController,
            decoration: const InputDecoration(labelText: 'Unit price'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _nonNegativePriceValidator,
          ),
          Text('Total: ${_liveTotal.toStringAsFixed(2)}'),
          ListTile(
            title: Text('Date: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
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
```

- [ ] **Step 12: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/widgets/material_form_test.dart
```

Expected: `All tests passed!` (4 tests).

- [ ] **Step 13: Commit**

```bash
cd /home/luser/claude_projects/SpeseClienteApp
git add spese_cliente_app/lib/widgets spese_cliente_app/test/widgets
git commit -m "Add confirm-delete dialog, ClientForm, and MaterialForm widgets"
```

---

## Task 8: Screens — `ClientListScreen` and `ClientDetailScreen`, wire up `main.dart`

**Files:**
- Create: `spese_cliente_app/lib/screens/client_list_screen.dart`
- Create: `spese_cliente_app/lib/screens/client_detail_screen.dart`
- Modify: `spese_cliente_app/lib/main.dart` (replace default counter app)
- Test: `spese_cliente_app/test/screens/client_list_screen_test.dart`
- Test: `spese_cliente_app/test/screens/client_detail_screen_test.dart`

**Interfaces:**
- Consumes: `ClientProvider`/`ClientWithTotal`/`ClientDetailProvider` (Task 6), `ClientForm`/`MaterialForm`/`showConfirmDeleteDialog` (Task 7), `Client`/`MaterialItem` models (Task 2).
- Produces:
  - `ClientListScreen` (`StatelessWidget`, no constructor args) — reads `ClientProvider` via `Consumer`, calls `loadClients()` once on first build via `context.read` in a post-frame callback pattern (or `initState` if converted to `StatefulWidget` — implementation detail left to the coder, test only asserts on rendered content).
  - `ClientDetailScreen({required Client client})` — reads/creates a `ClientDetailProvider` scoped to `client.id`.
  - `main.dart` wires up `MultiProvider` with a single shared `DatabaseHelper`, `ClientRepository`, `MaterialRepository`, and a top-level `ClientProvider`, then runs `MaterialApp(home: ClientListScreen())`.

- [ ] **Step 1: Write failing widget test for `ClientListScreen`**

Create `spese_cliente_app/test/screens/client_list_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/providers/client_provider.dart';
import 'package:spese_cliente_app/screens/client_list_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget buildTestable(ClientProvider provider) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: ClientListScreen()),
    );
  }

  testWidgets('shows empty state when there are no clients', (tester) async {
    final helper = DatabaseHelper(inMemory: true);
    final provider = ClientProvider(ClientRepository(helper));

    await tester.pumpWidget(buildTestable(provider));
    await tester.pumpAndSettle();

    expect(find.text('No clients yet — tap + to add one.'), findsOneWidget);

    await helper.close();
  });

  testWidgets('adding a client through the FAB dialog shows it in the list', (tester) async {
    final helper = DatabaseHelper(inMemory: true);
    final provider = ClientProvider(ClientRepository(helper));

    await tester.pumpWidget(buildTestable(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('client_name_field')), 'Mario');
    await tester.enterText(find.byKey(const Key('client_surname_field')), 'Rossi');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Mario Rossi'), findsOneWidget);

    await helper.close();
  });

  testWidgets('deleting a client requires confirmation', (tester) async {
    final helper = DatabaseHelper(inMemory: true);
    final provider = ClientProvider(ClientRepository(helper));
    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));

    await tester.pumpWidget(buildTestable(provider));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Mario Rossi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Mario Rossi'), findsNothing);
    expect(find.text('No clients yet — tap + to add one.'), findsOneWidget);

    await helper.close();
  });
}
```

Note: add `import 'package:spese_cliente_app/models/client.dart';` alongside the other imports in this file (needed for the `Client(...)` constructor used in the delete test).

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/luser/claude_projects/SpeseClienteApp/spese_cliente_app
/home/luser/snap/flutter/common/flutter/bin/flutter test test/screens/client_list_screen_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/screens/client_list_screen.dart'`.

- [ ] **Step 3: Implement `ClientListScreen`**

Create `spese_cliente_app/lib/screens/client_list_screen.dart`:

```dart
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
    if (confirmed) {
      await context.read<ClientProvider>().deleteClient(client.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Consumer<ClientProvider>(
        builder: (context, provider, _) {
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClientDetailScreen(client: entry.client),
                  ),
                ),
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/screens/client_list_screen_test.dart
```

Expected: `All tests passed!` (3 tests). If the "deleting a client" test fails to find the second "Delete" text (bottom sheet vs. dialog both saying "Delete"), that is expected ambiguity resolved by `.last` in the test — re-read the test step if it does not pass and adjust widget keys/text as needed, but do not change the confirmation UX (bottom-sheet-then-dialog) itself.

- [ ] **Step 5: Write failing widget test for `ClientDetailScreen`**

Create `spese_cliente_app/test/screens/client_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/screens/client_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/data/material_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('shows empty state, then an added material with running total', (tester) async {
    final helper = DatabaseHelper(inMemory: true);
    final clientRepo = ClientRepository(helper);
    final materialRepo = MaterialRepository(helper);
    final clientId = await clientRepo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    final client = Client(id: clientId, name: 'Mario', surname: 'Rossi');

    await tester.pumpWidget(
      Provider<MaterialRepository>.value(
        value: materialRepo,
        child: MaterialApp(home: ClientDetailScreen(client: client)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No materials yet for this client.'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('material_name_field')), 'Cement');
    await tester.enterText(find.byKey(const Key('material_quantity_field')), '3');
    await tester.enterText(find.byKey(const Key('material_unit_price_field')), '15');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cement'), findsOneWidget);
    expect(find.textContaining('45.00'), findsWidgets);

    await helper.close();
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/screens/client_detail_screen_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:spese_cliente_app/screens/client_detail_screen.dart'`.

- [ ] **Step 7: Implement `ClientDetailScreen`**

Create `spese_cliente_app/lib/screens/client_detail_screen.dart`:

```dart
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
    if (confirmed) {
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
```

- [ ] **Step 8: Run test to verify it passes**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test test/screens/client_detail_screen_test.dart
```

Expected: `All tests passed!` (1 test).

- [ ] **Step 9: Wire up `main.dart`**

Replace the entire contents of `spese_cliente_app/lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/providers/client_provider.dart';
import 'package:spese_cliente_app/screens/client_list_screen.dart';

void main() {
  final helper = DatabaseHelper();
  final clientRepository = ClientRepository(helper);
  final materialRepository = MaterialRepository(helper);

  runApp(MultiProvider(
    providers: [
      Provider<MaterialRepository>.value(value: materialRepository),
      ChangeNotifierProvider<ClientProvider>(
        create: (_) => ClientProvider(clientRepository),
      ),
    ],
    child: const SpeseClienteApp(),
  ));
}

class SpeseClienteApp extends StatelessWidget {
  const SpeseClienteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spese Cliente',
      home: const ClientListScreen(),
    );
  }
}
```

- [ ] **Step 10: Run the full test suite**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter test
```

Expected: `All tests passed!` across every test file created in Tasks 2–8.

- [ ] **Step 11: Run static analysis**

```bash
/home/luser/snap/flutter/common/flutter/bin/flutter analyze
```

Expected: `No issues found!`. Fix any lint errors before proceeding (do not fix by suppressing lints unless the lint itself is a false positive).

- [ ] **Step 12: Commit**

```bash
cd /home/luser/claude_projects/SpeseClienteApp
git add spese_cliente_app/lib/screens spese_cliente_app/lib/main.dart spese_cliente_app/test/screens
git commit -m "Add ClientListScreen and ClientDetailScreen, wire up main.dart"
```

---

## Task 9: Build and hand off APK for manual verification

**Files:**
- No new source files. Produces a build artifact: `spese_cliente_app/build/app/outputs/flutter-apk/app-release.apk`.

**Interfaces:**
- Consumes: the completed app from Task 8.
- Produces: an installable release APK for the user to test on their own physical Android device.

- [ ] **Step 1: Build the release APK**

```bash
cd /home/luser/claude_projects/SpeseClienteApp/spese_cliente_app
/home/luser/snap/flutter/common/flutter/bin/flutter build apk --release
```

Expected: ends with `✓ Built build/app/outputs/flutter-apk/app-release.apk`. If it fails on missing Android licenses, re-run Task 0 Step 4 (`sdkmanager --licenses`).

- [ ] **Step 2: Report the APK location to the user**

No command — this is a manual note for whoever executes this plan: tell the user the APK is at `spese_cliente_app/build/app/outputs/flutter-apk/app-release.apk` and that they can transfer it to an Android phone (e.g. via `adb install <path>` with the phone connected and USB debugging enabled, or by copying the file and opening it on-device) to manually verify: adding/editing/deleting a client, adding/editing/deleting a material, the running total updating correctly, and both empty states appearing.

- [ ] **Step 3: No commit needed**

The build artifact is not checked into git (it lives under `build/`, which `flutter create` already `.gitignore`s by default). Verify this is the case:

```bash
cd /home/luser/claude_projects/SpeseClienteApp
git status --short
```

Expected: no untracked files under `spese_cliente_app/build/` are listed (confirming `.gitignore` is working as expected). If build artifacts do show up as untracked, do not add them — leave them untracked.
