import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for participant profile fields (synced to server when possible).
class ProfileStore {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  static const _firstNameKey = 'profile_first_name';
  static const _lastNameKey = 'profile_last_name';
  static const _phoneKey = 'profile_phone';

  Future<ProfileDraft> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProfileDraft(
      firstName: prefs.getString(_firstNameKey) ?? '',
      lastName: prefs.getString(_lastNameKey) ?? '',
      phone: prefs.getString(_phoneKey) ?? '',
    );
  }

  Future<void> save(ProfileDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_firstNameKey, draft.firstName.trim());
    await prefs.setString(_lastNameKey, draft.lastName.trim());
    await prefs.setString(_phoneKey, draft.phone.trim());
  }

  Future<bool> isComplete() async {
    final draft = await load();
    return draft.isValid;
  }
}

class ProfileDraft {
  final String firstName;
  final String lastName;
  final String phone;

  const ProfileDraft({
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  bool get isValid =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      phone.trim().isNotEmpty;

  ProfileDraft copyWith({
    String? firstName,
    String? lastName,
    String? phone,
  }) {
    return ProfileDraft(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
    );
  }
}
