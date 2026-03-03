import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/value_objects/currency.dart';
import 'package:flutter/material.dart';

/// Cloud data source for User entities using Firebase Firestore
class UserCloudDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'users';

  UserCloudDataSource(this._firestore);

  /// Get the users collection reference
  CollectionReference get _collection => _firestore.collection(_collectionName);

  /// Create a new user
  Future<User> create(User user) async {
    final data = _toFirestore(user);
    await _collection.doc(user.id).set(data);
    return user;
  }

  /// Update an existing user
  Future<User> update(User user) async {
    final data = _toFirestore(user);
    await _collection.doc(user.id).update(data);
    return user;
  }

  /// Delete a user by ID
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Get a user by ID
  Future<User?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return _fromFirestore(doc);
  }

  /// Check if a user exists
  Future<bool> exists(String id) async {
    final doc = await _collection.doc(id).get();
    return doc.exists;
  }

  /// Convert User entity to Firestore document
  Map<String, dynamic> _toFirestore(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'displayName': user.displayName,
      'locale': {
        'languageCode': user.locale.languageCode,
        'countryCode': user.locale.countryCode,
      },
      'baseCurrency': {
        'code': user.baseCurrency.code,
        'symbol': user.baseCurrency.symbol,
        'name': user.baseCurrency.name,
        'decimalPlaces': user.baseCurrency.decimalPlaces,
      },
      'notificationPrefs': {
        'budgetAlerts': user.notificationPrefs.budgetAlerts,
        'goalReminders': user.notificationPrefs.goalReminders,
        'goalAchievements': user.notificationPrefs.goalAchievements,
        'syncStatus': user.notificationPrefs.syncStatus,
      },
      'createdAt': Timestamp.fromDate(user.createdAt),
      'updatedAt': Timestamp.fromDate(user.updatedAt),
    };
  }

  /// Convert Firestore document to User entity
  User _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final localeData = data['locale'] as Map<String, dynamic>;
    final currencyData = data['baseCurrency'] as Map<String, dynamic>;
    final notifPrefsData = data['notificationPrefs'] as Map<String, dynamic>;

    return User(
      id: data['id'] as String,
      email: data['email'] as String,
      phoneNumber: data['phoneNumber'] as String?,
      displayName: data['displayName'] as String,
      locale: Locale(
        localeData['languageCode'] as String,
        localeData['countryCode'] as String?,
      ),
      baseCurrency: Currency(
        code: currencyData['code'] as String,
        symbol: currencyData['symbol'] as String,
        name: currencyData['name'] as String,
        decimalPlaces: currencyData['decimalPlaces'] as int,
      ),
      notificationPrefs: NotificationPreferences(
        budgetAlerts: notifPrefsData['budgetAlerts'] as bool? ?? true,
        goalReminders: notifPrefsData['goalReminders'] as bool? ?? true,
        goalAchievements: notifPrefsData['goalAchievements'] as bool? ?? true,
        syncStatus: notifPrefsData['syncStatus'] as bool? ?? true,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
