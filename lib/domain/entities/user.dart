import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../value_objects/currency.dart';

/// Notification preferences for a user
class NotificationPreferences extends Equatable {
  final bool budgetAlerts;
  final bool goalReminders;
  final bool goalAchievements;
  final bool syncStatus;

  const NotificationPreferences({
    this.budgetAlerts = true,
    this.goalReminders = true,
    this.goalAchievements = true,
    this.syncStatus = true,
  });

  NotificationPreferences copyWith({
    bool? budgetAlerts,
    bool? goalReminders,
    bool? goalAchievements,
    bool? syncStatus,
  }) {
    return NotificationPreferences(
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      goalReminders: goalReminders ?? this.goalReminders,
      goalAchievements: goalAchievements ?? this.goalAchievements,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        budgetAlerts,
        goalReminders,
        goalAchievements,
        syncStatus,
      ];
}

/// Entity representing a user
class User extends Equatable {
  final String id;
  final String email;
  final String? phoneNumber;
  final String displayName;
  final Locale locale;
  final Currency baseCurrency;
  final NotificationPreferences notificationPrefs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.phoneNumber,
    required this.displayName,
    required this.locale,
    required this.baseCurrency,
    this.notificationPrefs = const NotificationPreferences(),
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? displayName,
    Locale? locale,
    Currency? baseCurrency,
    NotificationPreferences? notificationPrefs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      locale: locale ?? this.locale,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        phoneNumber,
        displayName,
        locale,
        baseCurrency,
        notificationPrefs,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, locale: ${locale.toString()})';
  }
}
