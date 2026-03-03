import 'package:flutter/material.dart';
import 'category_template.dart';

/// Regional category templates for different locales
/// Provides culturally relevant default categories based on user's region
class RegionalCategoryTemplates {
  /// Static map of templates keyed by locale strings (e.g., 'en_NG', 'en_US')
  static final Map<String, CategoryTemplate> templates = {
    // Nigeria template
    'en_NG': CategoryTemplate(
      locale: const Locale('en', 'NG'),
      name: 'Nigeria',
      description: 'Categories for Nigerian lifestyle',
      flag: '🇳🇬',
      categories: [
        // Transportation
        const CategoryDefinition('Okada', '🏍️', Colors.orange),
        const CategoryDefinition('Danfo', '🚐', Colors.yellow),
        const CategoryDefinition('Keke', '🛺', Colors.green),
        
        // Food & Dining
        const CategoryDefinition('Suya', '🍖', Colors.red),
        const CategoryDefinition('Jollof Rice', '🍚', Colors.deepOrange),
        const CategoryDefinition('Mama Put', '🍲', Colors.brown),
        
        // Utilities & Services
        const CategoryDefinition('Data Bundle', '📱', Colors.blue),
        const CategoryDefinition('Generator Fuel', '⛽', Colors.amber),
        const CategoryDefinition('NEPA Bill', '💡', Colors.yellow),
        
        // General
        const CategoryDefinition('Market', '🛒', Colors.green),
        const CategoryDefinition('Airtime', '📞', Colors.purple),
      ],
    ),

    // United States template
    'en_US': CategoryTemplate(
      locale: const Locale('en', 'US'),
      name: 'United States',
      description: 'Categories for American lifestyle',
      flag: '🇺🇸',
      categories: [
        // Transportation
        const CategoryDefinition('Subway', '🚇', Colors.blue),
        const CategoryDefinition('Uber/Lyft', '🚗', Colors.black),
        const CategoryDefinition('Gas', '⛽', Colors.red),
        
        // Food & Dining
        const CategoryDefinition('Coffee Shops', '☕', Colors.brown),
        const CategoryDefinition('Fast Food', '🍔', Colors.orange),
        const CategoryDefinition('Restaurants', '🍽️', Colors.red),
        
        // Entertainment & Subscriptions
        const CategoryDefinition('Streaming', '📺', Colors.purple),
        const CategoryDefinition('Gym', '💪', Colors.green),
        const CategoryDefinition('Movies', '🎬', Colors.indigo),
        
        // General
        const CategoryDefinition('Groceries', '🛒', Colors.green),
        const CategoryDefinition('Shopping', '🛍️', Colors.pink),
        const CategoryDefinition('Healthcare', '🏥', Colors.red),
      ],
    ),

    // Europe template (generic European countries)
    'en_GB': CategoryTemplate(
      locale: const Locale('en', 'GB'),
      name: 'United Kingdom',
      description: 'Categories for British lifestyle',
      flag: '🇬🇧',
      categories: [
        // Transportation
        const CategoryDefinition('Public Transport', '🚇', Colors.blue),
        const CategoryDefinition('Train', '🚆', Colors.green),
        const CategoryDefinition('Petrol', '⛽', Colors.red),
        
        // Food & Dining
        const CategoryDefinition('Bakery', '🥖', Colors.brown),
        const CategoryDefinition('Café', '☕', Colors.orange),
        const CategoryDefinition('Pub', '🍺', Colors.amber),
        
        // Shopping & Services
        const CategoryDefinition('Supermarket', '🛒', Colors.green),
        const CategoryDefinition('Pharmacy', '💊', Colors.red),
        const CategoryDefinition('Post Office', '📮', Colors.blue),
        
        // General
        const CategoryDefinition('Council Tax', '🏛️', Colors.grey),
        const CategoryDefinition('Utilities', '💡', Colors.yellow),
      ],
    ),

    // France
    'fr_FR': CategoryTemplate(
      locale: const Locale('fr', 'FR'),
      name: 'France',
      description: 'Catégories pour le style de vie français',
      flag: '🇫🇷',
      categories: [
        const CategoryDefinition('Métro', '🚇', Colors.blue),
        const CategoryDefinition('Boulangerie', '🥖', Colors.brown),
        const CategoryDefinition('Café', '☕', Colors.orange),
        const CategoryDefinition('Supermarché', '🛒', Colors.green),
        const CategoryDefinition('Pharmacie', '💊', Colors.red),
      ],
    ),

    // Germany
    'de_DE': CategoryTemplate(
      locale: const Locale('de', 'DE'),
      name: 'Germany',
      description: 'Kategorien für den deutschen Lebensstil',
      flag: '🇩🇪',
      categories: [
        const CategoryDefinition('U-Bahn', '🚇', Colors.blue),
        const CategoryDefinition('Bäckerei', '🥖', Colors.brown),
        const CategoryDefinition('Café', '☕', Colors.orange),
        const CategoryDefinition('Supermarkt', '🛒', Colors.green),
        const CategoryDefinition('Apotheke', '💊', Colors.red),
      ],
    ),

    // India template
    'en_IN': CategoryTemplate(
      locale: const Locale('en', 'IN'),
      name: 'India',
      description: 'Categories for Indian lifestyle',
      flag: '🇮🇳',
      categories: [
        // Transportation
        const CategoryDefinition('Auto Rickshaw', '🛺', Colors.green),
        const CategoryDefinition('Metro', '🚇', Colors.blue),
        const CategoryDefinition('Petrol', '⛽', Colors.red),
        
        // Food & Dining
        const CategoryDefinition('Street Food', '🍛', Colors.orange),
        const CategoryDefinition('Chai', '☕', Colors.brown),
        const CategoryDefinition('Restaurant', '🍽️', Colors.red),
        
        // Services & Utilities
        const CategoryDefinition('Mobile Recharge', '📱', Colors.blue),
        const CategoryDefinition('DTH Recharge', '📺', Colors.purple),
        const CategoryDefinition('Electricity Bill', '💡', Colors.yellow),
        
        // General
        const CategoryDefinition('Kirana Store', '🛒', Colors.green),
        const CategoryDefinition('Medical', '🏥', Colors.red),
        const CategoryDefinition('Education', '📚', Colors.indigo),
      ],
    ),

    // Hindi (India)
    'hi_IN': CategoryTemplate(
      locale: const Locale('hi', 'IN'),
      name: 'भारत',
      description: 'भारतीय जीवनशैली के लिए श्रेणियाँ',
      flag: '🇮🇳',
      categories: [
        const CategoryDefinition('ऑटो रिक्शा', '🛺', Colors.green),
        const CategoryDefinition('मेट्रो', '🚇', Colors.blue),
        const CategoryDefinition('पेट्रोल', '⛽', Colors.red),
        const CategoryDefinition('स्ट्रीट फूड', '🍛', Colors.orange),
        const CategoryDefinition('चाय', '☕', Colors.brown),
        const CategoryDefinition('मोबाइल रिचार्ज', '📱', Colors.blue),
        const CategoryDefinition('किराना स्टोर', '🛒', Colors.green),
      ],
    ),
  };

  /// Get template for a specific locale
  /// Returns null if no template exists for the locale
  static CategoryTemplate? getTemplate(Locale locale) {
    final localeString = '${locale.languageCode}_${locale.countryCode}';
    return templates[localeString];
  }

  /// Get template by locale string (e.g., 'en_NG', 'en_US')
  static CategoryTemplate? getTemplateByString(String localeString) {
    return templates[localeString];
  }

  /// Get all available locale strings
  static List<String> getAvailableLocales() {
    return templates.keys.toList();
  }

  /// Check if a template exists for a locale
  static bool hasTemplate(Locale locale) {
    final localeString = '${locale.languageCode}_${locale.countryCode}';
    return templates.containsKey(localeString);
  }

  /// Get a fallback template (defaults to US English)
  static CategoryTemplate getFallbackTemplate() {
    return templates['en_US']!;
  }

  /// Get template with fallback
  /// If no template exists for the locale, returns the fallback template
  static CategoryTemplate getTemplateOrFallback(Locale locale) {
    return getTemplate(locale) ?? getFallbackTemplate();
  }

  /// Get all available templates as a list
  static List<CategoryTemplate> get allTemplates {
    return templates.values.toList();
  }
}
