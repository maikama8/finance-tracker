import 'package:flutter/material.dart';
import '../../gen_l10n/app_localizations.dart';

/// Grid of icons for category selection
class IconPickerGrid extends StatelessWidget {
  final String selectedIcon;
  final Function(String) onIconSelected;

  const IconPickerGrid({
    Key? key,
    required this.selectedIcon,
    required this.onIconSelected,
  }) : super(key: key);

  // Common category icons
  static const List<String> icons = [
    '🍔', '🍕', '🍜', '☕', '🍺', '🛒', // Food & Drinks
    '🚗', '🚕', '🚌', '🚇', '✈️', '⛽', // Transport
    '🏠', '💡', '🔌', '🚿', '📱', '💻', // Home & Utilities
    '👕', '👗', '👟', '🎽', '👜', '💄', // Shopping & Fashion
    '🏥', '💊', '🩺', '💉', '🧘', '🏋️', // Health & Fitness
    '🎬', '🎮', '🎵', '📚', '🎨', '🎭', // Entertainment
    '✏️', '📝', '🎓', '📖', '🖊️', '📐', // Education
    '💰', '💳', '💵', '🏦', '📊', '💼', // Finance
    '🎁', '🎉', '🎂', '🎈', '🎊', '🎀', // Gifts & Celebrations
    '🐕', '🐈', '🐦', '🐠', '🌱', '🌺', // Pets & Nature
    '🔧', '🔨', '🪛', '⚙️', '🛠️', '🔩', // Tools & Maintenance
    '📦', '📮', '📫', '📪', '📬', '📭', // Packages & Mail
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.selectIcon,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                final icon = icons[index];
                final isSelected = icon == selectedIcon;

                return InkWell(
                  onTap: () => onIconSelected(icon),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
