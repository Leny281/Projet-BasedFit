class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final DateTime birthDate;
  double height; // en cm (modifiable)
  double weight; // en kg (modifiable)
  String goal;
  final bool isAdmin;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.birthDate,
    required this.height,
    required this.weight,
    this.goal = 'Remise en forme',
    this.isAdmin = false,
  });

  // Calcul automatique de l'âge
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Nom complet
  String get fullName => '$firstName $lastName';

  // Conversion en Map pour stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'birth_date': birthDate.toIso8601String(),
      'height': height,
      'weight': weight,
      'goal': goal,
      'is_admin': isAdmin ? 1 : 0,
    };
  }

  // Création depuis Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      goal: map['goal'] as String? ?? 'Remise en forme',
      isAdmin: (map['is_admin'] as int? ?? 0) == 1,
    );
  }

  // Copie avec modifications
  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    DateTime? birthDate,
    double? height,
    double? weight,
    String? goal,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
