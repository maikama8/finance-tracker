import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/savings_goal.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../domain/value_objects/exchange_rate.dart';

/// Type adapter for Decimal
class DecimalAdapter extends TypeAdapter<Decimal> {
  @override
  final int typeId = 0;

  @override
  Decimal read(BinaryReader reader) {
    final value = reader.readString();
    return Decimal.parse(value);
  }

  @override
  void write(BinaryWriter writer, Decimal obj) {
    writer.writeString(obj.toString());
  }
}

/// Type adapter for Currency
class CurrencyAdapter extends TypeAdapter<Currency> {
  @override
  final int typeId = 1;

  @override
  Currency read(BinaryReader reader) {
    final code = reader.readString();
    return Currency.fromCode(code) ?? Currency.USD;
  }

  @override
  void write(BinaryWriter writer, Currency obj) {
    writer.writeString(obj.code);
  }
}

/// Type adapter for TransactionType enum
class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 2;

  @override
  TransactionType read(BinaryReader reader) {
    final index = reader.readInt();
    return TransactionType.values[index];
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    writer.writeInt(obj.index);
  }
}

/// Type adapter for SyncStatus enum
class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 3;

  @override
  SyncStatus read(BinaryReader reader) {
    final index = reader.readInt();
    return SyncStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    writer.writeInt(obj.index);
  }
}

/// Type adapter for ReminderFrequency enum
class ReminderFrequencyAdapter extends TypeAdapter<ReminderFrequency> {
  @override
  final int typeId = 4;

  @override
  ReminderFrequency read(BinaryReader reader) {
    final index = reader.readInt();
    return ReminderFrequency.values[index];
  }

  @override
  void write(BinaryWriter writer, ReminderFrequency obj) {
    writer.writeInt(obj.index);
  }
}

/// Type adapter for Transaction entity
class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 10;

  @override
  Transaction read(BinaryReader reader) {
    final id = reader.readString();
    final userId = reader.readString();
    final amount = reader.read() as Decimal;
    final currency = reader.read() as Currency;
    final type = reader.read() as TransactionType;
    final categoryId = reader.readString();
    final date = DateTime.parse(reader.readString());
    final createdAt = DateTime.parse(reader.readString());
    final updatedAt = DateTime.parse(reader.readString());
    final notesStr = reader.readString();
    final receiptStr = reader.readString();
    final syncStatus = reader.read() as SyncStatus;
    
    return Transaction(
      id: id,
      userId: userId,
      amount: amount,
      currency: currency,
      type: type,
      categoryId: categoryId,
      date: date,
      notes: notesStr.isEmpty ? null : notesStr,
      receiptImageId: receiptStr.isEmpty ? null : receiptStr,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.write(obj.amount);
    writer.write(obj.currency);
    writer.write(obj.type);
    writer.writeString(obj.categoryId);
    writer.writeString(obj.date.toIso8601String());
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeString(obj.notes ?? '');
    writer.writeString(obj.receiptImageId ?? '');
    writer.write(obj.syncStatus);
  }
}

/// Type adapter for Category entity
class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 11;

  @override
  Category read(BinaryReader reader) {
    final userIdStr = reader.readString();
    final parentCategoryIdStr = reader.readString();
    final localeStr = reader.readString();
    return Category(
      id: reader.readString(),
      userId: userIdStr.isEmpty ? null : userIdStr,
      name: reader.readString(),
      icon: reader.readString(),
      color: reader.readString(),
      parentCategoryId: parentCategoryIdStr.isEmpty ? null : parentCategoryIdStr,
      isDefault: reader.readBool(),
      locale: localeStr.isEmpty ? null : localeStr,
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId ?? '');
    writer.writeString(obj.parentCategoryId ?? '');
    writer.writeString(obj.locale ?? '');
    writer.writeString(obj.name);
    writer.writeString(obj.icon);
    writer.writeString(obj.color);
    writer.writeBool(obj.isDefault);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
  }
}

/// Type adapter for SavingsGoal entity
class SavingsGoalAdapter extends TypeAdapter<SavingsGoal> {
  @override
  final int typeId = 12;

  @override
  SavingsGoal read(BinaryReader reader) {
    return SavingsGoal(
      id: reader.readString(),
      userId: reader.readString(),
      name: reader.readString(),
      targetAmount: reader.read() as Decimal,
      currency: reader.read() as Currency,
      currentAmount: reader.read() as Decimal,
      deadline: DateTime.parse(reader.readString()),
      reminderEnabled: reader.readBool(),
      reminderFrequency: reader.readBool() ? reader.read() as ReminderFrequency : null,
      lastReminderSent: reader.readBool() ? DateTime.parse(reader.readString()) : null,
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
      syncStatus: reader.read() as SyncStatus,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsGoal obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.name);
    writer.write(obj.targetAmount);
    writer.write(obj.currency);
    writer.write(obj.currentAmount);
    writer.writeString(obj.deadline.toIso8601String());
    writer.writeBool(obj.reminderEnabled);
    writer.writeBool(obj.reminderFrequency != null);
    if (obj.reminderFrequency != null) {
      writer.write(obj.reminderFrequency!);
    }
    writer.writeBool(obj.lastReminderSent != null);
    if (obj.lastReminderSent != null) {
      writer.writeString(obj.lastReminderSent!.toIso8601String());
    }
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.write(obj.syncStatus);
  }
}

/// Type adapter for Budget entity
class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 13;

  @override
  Budget read(BinaryReader reader) {
    return Budget(
      id: reader.readString(),
      userId: reader.readString(),
      categoryId: reader.readString(),
      monthlyLimit: reader.read() as Decimal,
      currency: reader.read() as Currency,
      currentSpending: reader.read() as Decimal,
      month: reader.readInt(),
      year: reader.readInt(),
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
      syncStatus: reader.read() as SyncStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.categoryId);
    writer.write(obj.monthlyLimit);
    writer.write(obj.currency);
    writer.write(obj.currentSpending);
    writer.writeInt(obj.month);
    writer.writeInt(obj.year);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.write(obj.syncStatus);
  }
}

/// Type adapter for NotificationPreferences
class NotificationPreferencesAdapter extends TypeAdapter<NotificationPreferences> {
  @override
  final int typeId = 14;

  @override
  NotificationPreferences read(BinaryReader reader) {
    return NotificationPreferences(
      budgetAlerts: reader.readBool(),
      goalReminders: reader.readBool(),
      goalAchievements: reader.readBool(),
      syncStatus: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, NotificationPreferences obj) {
    writer.writeBool(obj.budgetAlerts);
    writer.writeBool(obj.goalReminders);
    writer.writeBool(obj.goalAchievements);
    writer.writeBool(obj.syncStatus);
  }
}

/// Type adapter for Locale
class LocaleAdapter extends TypeAdapter<Locale> {
  @override
  final int typeId = 15;

  @override
  Locale read(BinaryReader reader) {
    final languageCode = reader.readString();
    final countryCode = reader.readString();
    return Locale(languageCode, countryCode.isEmpty ? null : countryCode);
  }

  @override
  void write(BinaryWriter writer, Locale obj) {
    writer.writeString(obj.languageCode);
    writer.writeString(obj.countryCode ?? '');
  }
}

/// Type adapter for User entity
class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 16;

  @override
  User read(BinaryReader reader) {
    final phoneNumberStr = reader.readString();
    return User(
      id: reader.readString(),
      email: reader.readString(),
      phoneNumber: phoneNumberStr.isEmpty ? null : phoneNumberStr,
      displayName: reader.readString(),
      locale: reader.read() as Locale,
      baseCurrency: reader.read() as Currency,
      notificationPrefs: reader.read() as NotificationPreferences,
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.writeString(obj.phoneNumber ?? '');
    writer.writeString(obj.id);
    writer.writeString(obj.email);
    writer.writeString(obj.displayName);
    writer.write(obj.locale);
    writer.write(obj.baseCurrency);
    writer.write(obj.notificationPrefs);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
  }
}

/// Type adapter for ExchangeRate
class ExchangeRateAdapter extends TypeAdapter<ExchangeRate> {
  @override
  final int typeId = 17;

  @override
  ExchangeRate read(BinaryReader reader) {
    return ExchangeRate(
      baseCurrency: reader.read() as Currency,
      targetCurrency: reader.read() as Currency,
      rate: reader.read() as Decimal,
      timestamp: DateTime.parse(reader.readString()),
      expiresAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeRate obj) {
    writer.write(obj.baseCurrency);
    writer.write(obj.targetCurrency);
    writer.write(obj.rate);
    writer.writeString(obj.timestamp.toIso8601String());
    writer.writeString(obj.expiresAt.toIso8601String());
  }
}

/// Model for sync queue items
class SyncQueueItem {
  final String id;
  final String entityType; // 'transaction', 'category', 'goal', 'budget'
  final String entityId;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });
}

/// Type adapter for SyncQueueItem
class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 18;

  @override
  SyncQueueItem read(BinaryReader reader) {
    return SyncQueueItem(
      id: reader.readString(),
      entityType: reader.readString(),
      entityId: reader.readString(),
      operation: reader.readString(),
      data: Map<String, dynamic>.from(reader.readMap()),
      timestamp: DateTime.parse(reader.readString()),
      retryCount: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.entityType);
    writer.writeString(obj.entityId);
    writer.writeString(obj.operation);
    writer.writeMap(obj.data);
    writer.writeString(obj.timestamp.toIso8601String());
    writer.writeInt(obj.retryCount);
  }
}

/// Model for receipt image metadata
class ReceiptImageMetadata {
  final String id;
  final String userId;
  final String transactionId;
  final String filePath;
  final int fileSizeBytes;
  final DateTime uploadedAt;

  ReceiptImageMetadata({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.filePath,
    required this.fileSizeBytes,
    required this.uploadedAt,
  });
}

/// Type adapter for ReceiptImageMetadata
class ReceiptImageMetadataAdapter extends TypeAdapter<ReceiptImageMetadata> {
  @override
  final int typeId = 19;

  @override
  ReceiptImageMetadata read(BinaryReader reader) {
    return ReceiptImageMetadata(
      id: reader.readString(),
      userId: reader.readString(),
      transactionId: reader.readString(),
      filePath: reader.readString(),
      fileSizeBytes: reader.readInt(),
      uploadedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptImageMetadata obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.transactionId);
    writer.writeString(obj.filePath);
    writer.writeInt(obj.fileSizeBytes);
    writer.writeString(obj.uploadedAt.toIso8601String());
  }
}
