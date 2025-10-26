import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/budget.dart'; // Import BudgetType

/// Service for intelligent transaction categorization using keyword matching
class SmartCategorizationService {
  static const Map<String, List<CategoryMapping>> _categoryMappings = {
    // Transportation
    'expense_transport': [
      CategoryMapping(
        keywords: [
          'uber',
          'bolt',
          'taxify',
          'indriver',
          'lagos ride',
          'yellow cab',
        ],
        categoryId: 'expense_transport',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: ['bus', 'danfo', 'molue', 'bRT', 'Lagos BRT', 'molue bus'],
        categoryId: 'expense_transport',
        confidence: 0.8,
      ),
      CategoryMapping(
        keywords: [
          'fuel',
          'petrol',
          'diesel',
          'gas station',
          'NNPC',
          'Mobil',
          'Total',
          'Conoil',
        ],
        categoryId: 'expense_transport',
        confidence: 0.85,
      ),
      CategoryMapping(
        keywords: ['parking', 'toll gate', 'toll'],
        categoryId: 'expense_transport',
        confidence: 0.9,
      ),
    ],

    // Food & Groceries
    'expense_food': [
      CategoryMapping(
        keywords: [
          'jumia food',
          'bolt food',
          'glovo',
          'food delivery',
          'restaurant',
          'eatery',
          'buka',
        ],
        categoryId: 'expense_food',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: [
          'shoprite',
          'spar',
          'supermarket',
          'market',
          'groceries',
          'provision',
        ],
        categoryId: 'expense_food',
        confidence: 0.85,
      ),
      CategoryMapping(
        keywords: [
          'chicken republic',
          'kFC',
          'mcdonald',
          'burger king',
          'domino',
          'pizza',
        ],
        categoryId: 'expense_food',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: [
          'mama cass',
          'tasty fried chicken',
          'sweet sensation',
          'mr biggs',
        ],
        categoryId: 'expense_food',
        confidence: 0.9,
      ),
    ],

    // Housing & Utilities
    'expense_housing': [
      CategoryMapping(
        keywords: ['rent', 'house rent', 'apartment', 'accommodation'],
        categoryId: 'expense_housing',
        confidence: 0.95,
      ),
      CategoryMapping(
        keywords: [
          'electricity',
          'electric bill',
          'PHCN',
          'EKEDC',
          'electricity bill',
        ],
        categoryId: 'expense_utilities',
        confidence: 0.9,
      ),
    ],

    'expense_utilities': [
      CategoryMapping(
        keywords: ['water bill', 'water rate', 'Lagos Water'],
        categoryId: 'expense_utilities',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: [
          'internet',
          'wifi',
          'broadband',
          'spectranet',
          'smile',
          'MTN',
          'Airtel',
          'Glo',
          '9mobile',
        ],
        categoryId: 'expense_utilities',
        confidence: 0.85,
      ),
      CategoryMapping(
        keywords: ['DSTV', 'GOTV', 'Startimes', 'cable TV', 'satellite TV'],
        categoryId: 'expense_utilities',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: ['waste', 'lawma', 'sanitation', 'refuse'],
        categoryId: 'expense_utilities',
        confidence: 0.85,
      ),
    ],

    // Personal & Lifestyle
    'expense_personal': [
      CategoryMapping(
        keywords: ['jumia', 'konga', 'kara', 'slot', 'justrite', 'shopping'],
        categoryId: 'expense_personal',
        confidence: 0.8,
      ),
      CategoryMapping(
        keywords: ['clothing', 'fashion', 'boutique', 'tailor', 'shoes', 'bag'],
        categoryId: 'expense_personal',
        confidence: 0.85,
      ),
      CategoryMapping(
        keywords: ['salon', 'barber', 'hair cut', 'beauty', 'spa', 'makeup'],
        categoryId: 'expense_personal',
        confidence: 0.85,
      ),
      CategoryMapping(
        keywords: ['gym', 'fitness', 'exercise', 'workout'],
        categoryId: 'expense_personal',
        confidence: 0.8,
      ),
    ],

    // Health & Insurance
    'expense_health': [
      CategoryMapping(
        keywords: [
          'hospital',
          'clinic',
          'doctor',
          'medical',
          'pharmacy',
          'drug',
        ],
        categoryId: 'expense_health',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: ['insurance', 'premium', 'health insurance'],
        categoryId: 'expense_health',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: ['dental', 'optical', 'eye clinic', 'glasses'],
        categoryId: 'expense_health',
        confidence: 0.85,
      ),
    ],

    // Education
    'expense_education': [
      CategoryMapping(
        keywords: [
          'school fees',
          'tuition',
          'education',
          'course',
          'training',
          'books',
        ],
        categoryId: 'expense_education',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: [
          'university',
          'college',
          'polytechnic',
          'exam',
          'waec',
          'jamb',
          'neet',
        ],
        categoryId: 'expense_education',
        confidence: 0.85,
      ),
    ],

    // Family & Relationships
    'expense_family': [
      CategoryMapping(
        keywords: ['gift', 'present', 'birthday', 'wedding', 'ceremony'],
        categoryId: 'expense_family',
        confidence: 0.8,
      ),
      CategoryMapping(
        keywords: ['family', 'relative', 'support', 'allowance'],
        categoryId: 'expense_family',
        confidence: 0.75,
      ),
    ],

    // Debt Payments
    'expense_debt': [
      CategoryMapping(
        keywords: [
          'loan repayment',
          'debt',
          'credit card',
          'interest',
          'bank charge',
        ],
        categoryId: 'expense_debt',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: [
          'first bank',
          'access bank',
          'zenith bank',
          'uba',
          'gtbank',
          'fcmb',
        ],
        categoryId: 'expense_debt',
        confidence: 0.7,
      ),
    ],

    // Savings & Investments
    'expense_savings': [
      CategoryMapping(
        keywords: [
          'savings',
          'investment',
          'stocks',
          'shares',
          'mutual fund',
          'piggyvest',
        ],
        categoryId: 'expense_savings',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: ['cowrywise', 'risevest', 'wealth.ng', 'portfolio'],
        categoryId: 'expense_savings',
        confidence: 0.9,
      ),
    ],

    // Miscellaneous
    'expense_misc': [
      CategoryMapping(
        keywords: ['misc', 'other', 'miscellaneous', 'various', 'sundry'],
        categoryId: 'expense_misc',
        confidence: 0.6,
      ),
    ],

    // Income Categories
    'income_salary': [
      CategoryMapping(
        keywords: ['salary', 'wage', 'payroll', 'monthly pay', 'allowance'],
        categoryId: 'income_salary',
        confidence: 0.95,
      ),
    ],

    'income_freelance': [
      CategoryMapping(
        keywords: [
          'freelance',
          'contract',
          'project',
          'gig',
          'upwork',
          'fiverr',
        ],
        categoryId: 'income_freelance',
        confidence: 0.9,
      ),
    ],

    'income_investment': [
      CategoryMapping(
        keywords: [
          'dividend',
          'interest',
          'profit',
          'return',
          'investment income',
        ],
        categoryId: 'income_investment',
        confidence: 0.9,
      ),
      CategoryMapping(
        keywords: ['stock', 'shares', 'equity', 'bond', 'treasury bill'],
        categoryId: 'income_investment',
        confidence: 0.85,
      ),
    ],

    'income_other': [
      CategoryMapping(
        keywords: ['refund', 'cashback', 'bonus', 'commission', 'tip'],
        categoryId: 'income_other',
        confidence: 0.8,
      ),
    ],
  };

  static const Map<BudgetType, List<String>> _budgetTypeKeywords = {
    BudgetType.fixed: [
      'rent',
      'house rent',
      'apartment rent',
      'data',
      'data subscription',
      'mobile data',
      'internet data',
      'electricity',
      'electric bill',
      'phcn',
      'ekedc',
      'ikedc',
      'electricity bill',
      'insurance',
      'car insurance',
      'health insurance',
      'life insurance',
      'premium',
      'school fees',
      'tuition',
      'child education',
      ' DSTV',
      'GOTV',
      'startimes',
      'cable TV',
      'satellite TV',
      'water bill',
      'water rate',
      'waste management',
      'lawma',
      'sanitation',
      'refuse',
      'security',
      'neighborhood security',
      'estate maintenance',
      'service charge',
      'maintenance fee',
      'generator fuel',
      'diesel',
      'fuel',
      'petrol',
      'gas',
    ],
    BudgetType.recurring: [
      'subscription',
      'monthly subscription',
      'recurring payment',
      'netflix',
      'spotify',
      'amazon prime',
      'apple music',
      'youtube premium',
      'gym membership',
      'fitness membership',
      'club membership',
      'professional membership',
      'association dues',
      'union dues',
      'society dues',
      'magazine subscription',
      'newspaper subscription',
      'software subscription',
      'app subscription',
      'cloud storage',
      'domain registration',
      'hosting',
      'website hosting',
      'online service',
      'streaming service',
      'music streaming',
      'video streaming',
      'regular donation',
      'monthly donation',
      'tithe',
      'offering',
      'charity',
      'regular charity',
    ],
    BudgetType.goal: [
      'vacation',
      'holiday',
      'travel',
      'trip',
      'honeymoon',
      'gadget',
      'phone',
      'laptop',
      'tablet',
      'electronics',
      'car',
      'automobile',
      'vehicle',
      'house',
      'property',
      'land',
      'building',
      'savings',
      'savings goal',
      'investment',
      'mutual fund',
      'stocks',
      'shares',
      'emergency fund',
      'emergency savings',
      'rainy day fund',
      'down payment',
      'mortgage deposit',
      'rent deposit',
      'caution fee',
      'security deposit',
      'refundable deposit',
      'wedding',
      'marriage',
      'traditional wedding',
      'white wedding',
      'engagement',
      'birthday party',
      'ceremony',
      'event',
      'celebration',
      'festival',
      'christmas',
      'sallah',
      'easter',
      'new year',
      'valentine',
      'anniversary',
      'graduation',
      'convocation',
      'retirement',
      'retirement fund',
      'pension',
      'business',
      'startup',
      'investment fund',
      'education fund',
      'children education',
      'university fund',
      'masters degree',
      'phd fund',
      'certification',
      'professional course',
      'skill acquisition',
      'vocational training',
    ],
    BudgetType.progressive: [
      'food',
      'groceries',
      'provision',
      'supermarket',
      'market',
      'shopping',
      'daily expenses',
      'monthly expenses',
      'household expenses',
      'family expenses',
      'personal expenses',
      'living expenses',
      'transport',
      'transportation',
      'fuel',
      'petrol',
      'diesel',
      'bus fare',
      'taxi fare',
      'uber',
      'bolt',
      'indriver',
      'lagos ride',
      'danfo',
      'molue',
      'brt',
      'lagos brt',
      ' Okada',
      'bike',
      'bicycle',
      'parking',
      'toll gate',
      'toll',
      'eating out',
      'restaurant',
      'eatery',
      'buka',
      'fast food',
      'takeaway',
      'delivery',
      'food delivery',
      'lunch',
      'dinner',
      'breakfast',
      'snacks',
      'drinks',
      'beverages',
      'water',
      'soft drinks',
      'juice',
      'entertainment',
      'movies',
      'cinema',
      'outing',
      'social',
      'hangout',
      'party',
      'casual outing',
      'weekend expenses',
      'miscellaneous',
      'misc',
      'other',
      'sundry',
      'various',
      'pocket money',
      'allowance',
      'daily allowance',
      'per diem',
      'cash',
      'petty cash',
      'small expenses',
      'incidentals',
      'tips',
      'gratuity',
      'service tip',
      'haircut',
      'barber',
      'salon',
      'beauty',
      'spa',
      'makeup',
      'cosmetics',
      'personal care',
      'hygiene',
      'toiletries',
      'household items',
      'cleaning supplies',
      'detergent',
      'soap',
      'tissue',
      'kitchen supplies',
      'cooking',
      'ingredients',
      'spices',
      'condiments',
      'pharmacy',
      'medicine',
      'drugs',
      'medical',
      'health',
      'clinic',
      'hospital',
      'doctor',
      'treatment',
      'prescription',
      'vitamins',
      'supplements',
      'clothing',
      'fashion',
      'shoes',
      'bags',
      'accessories',
      'jewelry',
      'watch',
      'clothes',
      'garments',
      'attire',
      'outfit',
      'wardrobe',
      'shopping',
      'jumia',
      'konga',
      'kara',
      'slot',
      'justrite',
      'shoprite',
      'spar',
      'department store',
      'boutique',
      'tailor',
      'sewing',
      'fabric',
      'material',
      'airtime',
      'recharge card',
      'call credit',
      'phone credit',
      'communication',
      'phone bill',
      'mobile bill',
      'telephone',
      'internet bill',
      'wifi',
      'broadband',
      'spectranet',
      'smile',
      'mtn',
      'airtel',
      'glo',
      '9mobile',
      'etisalat',
      'mobile network',
      'telecom',
      'bank charges',
      'atm fees',
      'transfer fees',
      'withdrawal fees',
      'maintenance charges',
      'account maintenance',
      'card fees',
      'debit card',
      'credit card',
      'pos charges',
      'transaction fees',
      'commission',
      'brokerage',
      'financial charges',
      'interest',
      'loan interest',
      'overdraft',
      'penalty',
      'fine',
      'late fee',
      'overdue',
      'default',
    ],
  };

  /// Infers the BudgetType based on the budget name
  static BudgetType inferBudgetType(String budgetName) {
    final lowerCaseName = budgetName.toLowerCase();

    for (final entry in _budgetTypeKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerCaseName.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return BudgetType
        .progressive; // Default to progressive if no keywords match
  }

  /// Get category suggestions for a transaction based on title and description
  static List<CategorySuggestion> getCategorySuggestions({
    required String title,
    String? description,
    required List<Category> availableCategories,
    required TransactionType transactionType,
  }) {
    final suggestions = <CategorySuggestion>[];
    final searchText =
        '${title.toLowerCase()} ${description?.toLowerCase() ?? ''}';

    // Get mappings for the transaction type
    final typePrefix = transactionType == TransactionType.income
        ? 'income_'
        : 'expense_';
    final relevantMappings = _categoryMappings.entries
        .where((entry) => entry.key.startsWith(typePrefix))
        .expand((entry) => entry.value);

    for (final mapping in relevantMappings) {
      final confidence = _calculateConfidence(searchText, mapping);
      if (confidence > 0.3) {
        // Only include suggestions with > 30% confidence
        final category = availableCategories
            .where((cat) => cat.id == mapping.categoryId)
            .cast<Category?>()
            .firstWhere((category) => true, orElse: () => null);

        if (category != null) {
          suggestions.add(
            CategorySuggestion(
              category: category,
              confidence: confidence,
              matchedKeywords: _getMatchedKeywords(searchText, mapping),
            ),
          );
        }
      }
    }

    // Sort by confidence (highest first)
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Limit to top 3 suggestions
    return suggestions.take(3).toList();
  }

  /// Get the best category suggestion for a transaction
  static CategorySuggestion? getBestCategorySuggestion({
    required String title,
    String? description,
    required List<Category> availableCategories,
    required TransactionType transactionType,
  }) {
    final suggestions = getCategorySuggestions(
      title: title,
      description: description,
      availableCategories: availableCategories,
      transactionType: transactionType,
    );

    return suggestions.isNotEmpty ? suggestions.first : null;
  }

  /// Calculate confidence score for a mapping against search text
  static double _calculateConfidence(
    String searchText,
    CategoryMapping mapping,
  ) {
    int matchCount = 0;

    for (final keyword in mapping.keywords) {
      if (searchText.contains(keyword.toLowerCase())) {
        matchCount++;
      }
    }

    if (matchCount == 0) return 0.0;

    // Use the base confidence if there's at least one match, with bonus for multiple matches
    final multipleMatchBonus = matchCount > 1 ? 0.1 : 0.0;
    final result = (mapping.confidence + multipleMatchBonus).clamp(0.0, 1.0);

    // Debug print for troubleshooting (only in debug mode)
    // print(
    //   'DEBUG: Category ${mapping.categoryId}, search: "$searchText", matches: $matchCount/${mapping.keywords.length}, confidence: ${result.toStringAsFixed(3)}',
    // );

    return result;
  }

  /// Get which keywords were matched for a suggestion
  static List<String> _getMatchedKeywords(
    String searchText,
    CategoryMapping mapping,
  ) {
    return mapping.keywords
        .where((keyword) => searchText.contains(keyword.toLowerCase()))
        .toList();
  }

  /// Check if a category should be auto-assigned based on confidence threshold
  static bool shouldAutoAssign(
    CategorySuggestion suggestion, {
    double threshold = 0.8,
  }) {
    return suggestion.confidence >= threshold;
  }
}

/// Represents a keyword-to-category mapping rule
class CategoryMapping {
  final List<String> keywords;
  final String categoryId;
  final double confidence;

  const CategoryMapping({
    required this.keywords,
    required this.categoryId,
    required this.confidence,
  });
}

/// Represents a category suggestion with confidence score
class CategorySuggestion {
  final Category category;
  final double confidence;
  final List<String> matchedKeywords;

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.matchedKeywords,
  });

  @override
  String toString() {
    return 'CategorySuggestion{category: ${category.name}, confidence: ${confidence.toStringAsFixed(2)}, keywords: $matchedKeywords}';
  }
}
