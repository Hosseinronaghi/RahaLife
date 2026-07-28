class LocalAccount {
  const LocalAccount({required this.id, required this.name, required this.email});

  factory LocalAccount.fromJson(Map<String, Object?> json) => LocalAccount(
        id: json['id']! as String,
        name: json['name']! as String,
        email: json['email']! as String,
      );

  final String id;
  final String name;
  final String email;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'email': email};
}

class AuthState {
  const AuthState({this.user, this.loading = false, this.errorCode});
  final LocalAccount? user;
  final bool loading;
  final String? errorCode;
  bool get signedIn => user != null;

  AuthState copyWith({LocalAccount? user, bool? loading, String? errorCode, bool clearUser = false, bool clearError = false}) => AuthState(
        user: clearUser ? null : (user ?? this.user),
        loading: loading ?? this.loading,
        errorCode: clearError ? null : (errorCode ?? this.errorCode),
      );
}
