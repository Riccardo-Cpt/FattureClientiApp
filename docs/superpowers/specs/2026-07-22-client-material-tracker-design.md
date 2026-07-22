# Client Material Expense Tracker — Design

## Overview

An Android app, built with Flutter, for tracking materials purchased per client. For each client, the app lists all materials bought and their total cost, with a running grand total per client. Users can add, edit, and delete both clients and material items.

## Architecture

- **Platform:** Flutter, targeting Android.
- **State management:** Provider (`ChangeNotifier` + `Consumer`/`Provider.of`).
- **Persistence:** Local SQLite via the `sqflite` package. No backend/cloud sync.

### Layers

- `models/` — plain Dart classes: `Client`, `MaterialItem`.
- `data/` — `DatabaseHelper` (raw sqflite access: table creation, migrations) plus `ClientRepository` and `MaterialRepository` (CRUD methods consumed by providers).
- `providers/` — `ClientProvider` (list of clients + totals) and `ClientDetailProvider` (materials for one client), both `ChangeNotifier`.
- `screens/` — `ClientListScreen`, `ClientDetailScreen`, add/edit forms.
- `widgets/` — reusable pieces: list tiles, form fields, confirm-delete dialog.

## Data Model

### Client

| Field | Type | Notes |
|---|---|---|
| id | int (PK, autoincrement) | |
| name | String | required |
| surname | String | required |

### MaterialItem

| Field | Type | Notes |
|---|---|---|
| id | int (PK, autoincrement) | |
| clientId | int (FK → Client.id) | |
| name | String | required |
| quantity | double | required, > 0 |
| unitPrice | double | required, ≥ 0 |
| totalPrice | double | computed as `quantity * unitPrice`, stored |
| date | DateTime | required, defaults to today when adding |

**Relationships:** One client has many materials. Deleting a client cascades and deletes all their materials.

**Client total spent** (shown in the client list) = sum of `totalPrice` across all their materials, computed via SQL `SUM()` or in-memory in the provider.

## Screens & Flows

### Client List Screen (home)

- Lists all clients as `Name Surname` + total spent.
- FAB opens a dialog to add a new client (name, surname fields).
- Tapping a client opens the Client Detail Screen.
- Swipe/long-press on a client row → edit (opens same add dialog, pre-filled) or delete (confirmation dialog: "Delete client X and all their materials?").
- Empty state: "No clients yet — tap + to add one."

### Client Detail Screen

- Shows the selected client's materials: name, quantity, unit price, total price, date.
- Running total displayed at the top.
- FAB opens a form to add a new material (name, quantity, unit price — total auto-calculated live as the user types — and a date picker defaulting to today).
- Tapping a material opens the same form pre-filled for editing.
- Swipe/long-press on a material row → delete (confirmation dialog: "Delete this material entry?").
- Empty state: "No materials yet for this client."

### Add/Edit Forms

- The same form widget is reused for both add and edit (pre-filled with existing values when editing).

## Validation & Error Handling

- **Client form:** name and surname required, non-empty after trimming. Inline validation errors on submit if blank.
- **Material form:** name required; quantity and unit price must be valid numbers (numeric keyboard) and must be positive (quantity > 0, unit price ≥ 0); date required (defaults to today, editable via date picker). Inline validation errors for invalid input.
- **Database errors:** caught in the repository layer and surfaced via a snackbar ("Something went wrong, please try again") rather than crashing the app.
- **Deletion:** always requires confirmation via dialog, for both clients and material items.

## Testing Approach

- **Unit tests:** repository CRUD operations (against an in-memory sqflite instance) and total-calculation logic.
- **Widget tests:** add/edit form validation (blank name rejected, non-numeric/non-positive quantity or price rejected).
- **Manual testing:** full add → view → edit → delete flows on an emulator/device, as the primary validation of real UI behavior.

## Out of Scope

- Cloud sync / multi-device support.
- Client contact info (phone, address, notes) — only name and surname are tracked.
- Reporting/export features (e.g. CSV, PDF invoices) beyond the in-app running totals.
