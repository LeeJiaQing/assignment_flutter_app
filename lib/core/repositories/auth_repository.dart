enum UserRole {
  admin,
  user,
}

abstract class AuthRepository {
  Future<UserRole> getCurrentUserRole();
}
