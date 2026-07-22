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
