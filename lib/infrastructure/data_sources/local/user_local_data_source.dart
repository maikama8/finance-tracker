import 'package:hive/hive.dart';
import '../../../domain/entities/user.dart';
import 'hive_database.dart';

/// Local data source for User entities using Hive
class UserLocalDataSource {
  final HiveDatabase _database;

  UserLocalDataSource(this._database);

  /// Get the users box
  Box _getBox() => _database.getBox(HiveBoxNames.users);

  /// Store or update a user
  Future<User> store(User user) async {
    final box = _getBox();
    await box.put(user.id, user);
    return user;
  }

  /// Get a user by ID
  Future<User?> getById(String id) async {
    final box = _getBox();
    return box.get(id) as User?;
  }

  /// Get the current user (assumes single user per device)
  Future<User?> getCurrentUser() async {
    final box = _getBox();
    if (box.isEmpty) return null;
    return box.values.first as User;
  }

  /// Delete a user by ID
  Future<void> delete(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  /// Clear all users
  Future<void> clearAll() async {
    final box = _getBox();
    await box.clear();
  }

  /// Check if a user exists
  Future<bool> exists(String id) async {
    final box = _getBox();
    return box.containsKey(id);
  }

  /// Watch the current user (returns a stream)
  Stream<User?> watchCurrentUser() {
    final box = _getBox();

    return box.watch().asyncMap((_) async {
      return getCurrentUser();
    });
  }
}
