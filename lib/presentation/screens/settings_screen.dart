import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../application/state/locale_provider.dart';
import '../../application/state/auth_provider.dart';
import '../../domain/value_objects/currency.dart';
import '../../domain/entities/regional_category_templates.dart';
import '../../domain/entities/user.dart';
import '../../infrastructure/data_sources/local/user_local_data_source.dart';
import '../../infrastructure/services/sync_manager_impl.dart';
import '../../domain/services/sync_manager.dart';
import '../../domain/services/notification_service.dart' as notification_svc;
import '../../infrastructure/services/notification_service_impl.dart';
import 'package:intl/intl.dart';

/// Provider for SyncManager
final syncManagerProvider = Provider<SyncManager>((ref) {
  // This should be properly initialized with all dependencies
  // For now, we'll throw an error if not properly set up
  throw UnimplementedError('SyncManager provider must be initialized in main.dart');
});

/// Provider for NotificationService
final notificationServiceProvider = Provider<notification_svc.NotificationService>((ref) {
  return NotificationServiceImpl();
});

/// Settings screen for managing app preferences
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);
    final authNotifier = ref.read(authProvider.notifier);

    // Language names for display
    final languageNames = {
      'en': 'English',
      'fr': 'Français',
      'es': 'Español',
      'de': 'Deutsch',
      'pt': 'Português',
      'ar': 'العربية',
      'hi': 'हिन्दी',
      'zh': '中文',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Error message display
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Language Section
                _buildSectionHeader(context, l10n.language),
                ...localeNotifier.getSupportedLocales().map((locale) {
                  final isSelected = currentLocale.languageCode == locale.languageCode;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(
                      languageNames[locale.languageCode] ?? locale.languageCode,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(locale.languageCode.toUpperCase()),
                    onTap: () async {
                      await _updateLocale(locale, languageNames[locale.languageCode] ?? locale.languageCode);
                    },
                  );
                }).toList(),
                const Divider(),

                // RTL Indicator
                if (localeNotifier.isRTL())
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_textdirection_r_to_l,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Right-to-Left (RTL) text direction is active',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Base Currency Section
                _buildSectionHeader(context, 'Base Currency'),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Base Currency'),
                  subtitle: Text(
                    currentUser?.baseCurrency.toString() ?? 'USD (\$)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCurrencyPicker(context, currentUser),
                ),
                const Divider(),

                // Category Template Section
                _buildSectionHeader(context, 'Category Template'),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Category Template'),
                  subtitle: Text(
                    _getCategoryTemplateName(currentLocale),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCategoryTemplatePicker(context, currentUser),
                ),
                const Divider(),

                // Notification Preferences Section
                _buildSectionHeader(context, 'Notifications'),
                if (currentUser != null) ...[
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active),
                    title: const Text('Budget Alerts'),
                    subtitle: const Text('Notify when approaching budget limits'),
                    value: currentUser.notificationPrefs.budgetAlerts,
                    onChanged: (value) => _updateNotificationPref(
                      currentUser,
                      currentUser.notificationPrefs.copyWith(budgetAlerts: value),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.savings),
                    title: const Text('Goal Reminders'),
                    subtitle: const Text('Remind me to contribute to savings goals'),
                    value: currentUser.notificationPrefs.goalReminders,
                    onChanged: (value) => _updateNotificationPref(
                      currentUser,
                      currentUser.notificationPrefs.copyWith(goalReminders: value),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.celebration),
                    title: const Text('Goal Achievements'),
                    subtitle: const Text('Celebrate when goals are reached'),
                    value: currentUser.notificationPrefs.goalAchievements,
                    onChanged: (value) => _updateNotificationPref(
                      currentUser,
                      currentUser.notificationPrefs.copyWith(goalAchievements: value),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.sync),
                    title: const Text('Sync Status'),
                    subtitle: const Text('Notify about sync issues'),
                    value: currentUser.notificationPrefs.syncStatus,
                    onChanged: (value) => _updateNotificationPref(
                      currentUser,
                      currentUser.notificationPrefs.copyWith(syncStatus: value),
                    ),
                  ),
                ],
                const Divider(),

                // Sync Status Section
                _buildSectionHeader(context, 'Synchronization'),
                _buildSyncStatusTile(context),
                const Divider(),

                // Account Section
                _buildSectionHeader(context, 'Account'),
                if (currentUser != null) ...[
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Account'),
                    subtitle: Text(currentUser.email),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () => _showLogoutConfirmation(context, authNotifier),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildSyncStatusTile(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: _getSyncStatusStream(),
      builder: (context, snapshot) {
        final syncStatus = snapshot.data;
        final lastSyncTime = syncStatus?.lastSyncTime;
        final pendingItems = syncStatus?.pendingItems ?? 0;
        final isSyncing = syncStatus?.state == SyncState.syncing;

        String statusText = 'Unknown';
        IconData statusIcon = Icons.help_outline;
        Color? statusColor;

        if (isSyncing) {
          statusText = 'Syncing...';
          statusIcon = Icons.sync;
          statusColor = Theme.of(context).colorScheme.primary;
        } else if (lastSyncTime != null) {
          statusText = 'Last synced: ${_formatSyncTime(lastSyncTime)}';
          statusIcon = Icons.check_circle;
          statusColor = Theme.of(context).colorScheme.primary;
        } else {
          statusText = 'Never synced';
          statusIcon = Icons.cloud_off;
        }

        if (pendingItems > 0) {
          statusText += ' ($pendingItems pending)';
        }

        return Column(
          children: [
            ListTile(
              leading: Icon(statusIcon, color: statusColor),
              title: const Text('Sync Status'),
              subtitle: Text(statusText),
              trailing: isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            if (!isSyncing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _manualSync,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                ),
              ),
            if (syncStatus?.state == SyncState.failure)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            syncStatus?.message ?? 'Sync failed',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Stream<SyncStatus> _getSyncStatusStream() {
    try {
      final syncManager = ref.read(syncManagerProvider);
      return syncManager.syncStatusStream;
    } catch (e) {
      // Return a dummy stream if sync manager is not available
      return Stream.value(const SyncStatus(
        state: SyncState.idle,
        message: 'Sync not configured',
      ));
    }
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.yMMMd().format(time);
    }
  }

  Future<void> _manualSync() async {
    try {
      final syncManager = ref.read(syncManagerProvider);
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await syncManager.syncAll();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync completed: ${result.itemsSynced} items synced'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          setState(() {
            _errorMessage = result.errorMessage ?? 'Sync failed';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sync not available: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _updateLocale(Locale locale, String languageName) async {
    final localeNotifier = ref.read(localeProvider.notifier);
    await localeNotifier.setLocale(locale);

    // Update user's locale in database
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await _updateUserLocale(currentUser, locale);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to $languageName'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateUserLocale(User user, Locale locale) async {
    try {
      final userDataSource = ref.read(userLocalDataSourceProvider);
      final updatedUser = user.copyWith(
        locale: locale,
        updatedAt: DateTime.now(),
      );
      await userDataSource.store(updatedUser);
    } catch (e) {
      print('Error updating user locale: $e');
    }
  }

  Future<void> _updateNotificationPref(
    User user,
    NotificationPreferences newPrefs,
  ) async {
    try {
      final userDataSource = ref.read(userLocalDataSourceProvider);
      final notificationService = ref.read(notificationServiceProvider);

      final updatedUser = user.copyWith(
        notificationPrefs: newPrefs,
        updatedAt: DateTime.now(),
      );

      await userDataSource.store(updatedUser);

      // Update notification service preferences
      await notificationService.updatePreferences(
        notification_svc.NotificationPreferences(
          budgetAlertsEnabled: newPrefs.budgetAlerts,
          goalRemindersEnabled: newPrefs.goalReminders,
          goalAchievementsEnabled: newPrefs.goalAchievements,
          syncStatusEnabled: newPrefs.syncStatus,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update preferences: ${e.toString()}';
        });
      }
    }
  }

  String _getCategoryTemplateName(Locale locale) {
    final template = RegionalCategoryTemplates.getTemplate(locale);
    return template?.name ?? 'Default';
  }

  void _showCurrencyPicker(BuildContext context, User? user) {
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: Currency.majorCurrencies.map((currency) {
          final isSelected = user.baseCurrency.code == currency.code;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(
              currency.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text('${currency.code} (${currency.symbol})'),
            onTap: () async {
              Navigator.pop(context);
              await _updateBaseCurrency(user, currency);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _updateBaseCurrency(User user, Currency currency) async {
    try {
      final userDataSource = ref.read(userLocalDataSourceProvider);
      final updatedUser = user.copyWith(
        baseCurrency: currency,
        updatedAt: DateTime.now(),
      );
      await userDataSource.store(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Base currency changed to ${currency.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update currency: ${e.toString()}';
        });
      }
    }
  }

  void _showCategoryTemplatePicker(BuildContext context, User? user) {
    if (user == null) return;

    final templates = RegionalCategoryTemplates.allTemplates;

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: templates.map((template) {
          final isSelected = user.locale.languageCode == template.locale.languageCode &&
              user.locale.countryCode == template.locale.countryCode;
          return ListTile(
            leading: Text(
              template.flag,
              style: const TextStyle(fontSize: 32),
            ),
            title: Text(
              template.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(template.description),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () async {
              Navigator.pop(context);
              await _updateCategoryTemplate(user, template.locale);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _updateCategoryTemplate(User user, Locale locale) async {
    try {
      final userDataSource = ref.read(userLocalDataSourceProvider);
      final updatedUser = user.copyWith(
        locale: locale,
        updatedAt: DateTime.now(),
      );
      await userDataSource.store(updatedUser);

      // Also update the app locale
      final localeNotifier = ref.read(localeProvider.notifier);
      await localeNotifier.setLocale(locale);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category template changed to ${_getCategoryTemplateName(locale)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update template: ${e.toString()}';
        });
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context, AuthNotifier authNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? All local data will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(authNotifier);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(AuthNotifier authNotifier) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Clear local data
      final userDataSource = ref.read(userLocalDataSourceProvider);
      await userDataSource.clearAll();

      // Sign out
      await authNotifier.signOut();

      if (mounted) {
        // Navigate to login screen
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Logout failed: ${e.toString()}';
        });
      }
    }
  }
}
