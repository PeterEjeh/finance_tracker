import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class FirebaseAIService {
  static final FirebaseAIService _instance = FirebaseAIService._internal();
  factory FirebaseAIService() => _instance;
  FirebaseAIService._internal();

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<String> _getAccessToken() async {
    try {
      // Get the Firebase Auth token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final token = await user.getIdToken();

      if (token == null) {
        throw Exception('Failed to retrieve a valid ID token.');
      }

      return token;
    } catch (e) {
      throw Exception('Failed to get access token: $e');
    }
  }

  /// Generate AI-powered spending insights using Firebase AI Gemini
  Future<List<String>> generateAIInsights({
    required List<Transaction> transactions,
    required List<Category> categories,
    required double totalIncome,
    required double totalExpenses,
  }) async {
    final insights = <String>[];

    if (transactions.isEmpty) {
      insights.add(
        'Start tracking your transactions to get personalized AI insights!',
      );
      return insights;
    }

    try {
      final token = await _getAccessToken();

      // Prepare transaction data for AI analysis
      final transactionData = transactions
          .map(
            (t) => {
              'amount': t.amount,
              'category': categories
                  .firstWhere((c) => c.id == t.categoryId)
                  .name,
              'date': t.date.toIso8601String(),
              'type': t.type.toString(),
              'notes': t.description,
            },
          )
          .toList();

      // Prepare the prompt for Gemini
      final prompt =
          '''
        As a financial advisor, analyze these transactions and provide insights:
        Total Income: $totalIncome
        Total Expenses: $totalExpenses
        Transactions: ${json.encode(transactionData)}

        IMPORTANT: Recognize that "Savings & Investments" is a POSITIVE financial behavior, not negative spending.
        Treat savings and investments as wise financial planning, not as expenses to be reduced.

        Please provide 3-5 specific, actionable insights about:
        1. Spending patterns and trends (excluding savings from negative analysis)
        2. Budget recommendations
        3. Savings and investment opportunities (praise good savings behavior)
        4. Financial health indicators

        Format each insight as a clear, concise bullet point starting with appropriate prefixes:
        - Use "💡 Insight:" for positive observations
        - Use "🎯 Recommendation:" for actionable advice
        - Use "⚠️ Alert:" for concerning patterns (excluding high savings)
        - Use "✅ Positive:" for good financial behaviors
      ''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final generatedText =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        // Split the response into individual insights
        insights.addAll(
          generatedText
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) => line.trim())
              .toList(),
        );
      } else {
        throw Exception('Failed to get AI insights: ${response.statusCode}');
      }
    } catch (e) {
      print('Firebase AI insights failed: $e');
      // Fallback to pattern-based insights
      final spendingAnalysis = _analyzeSpendingPatterns(
        transactions,
        categories,
      );
      insights.addAll(spendingAnalysis);

      // Generate budget recommendations
      final budgetRecommendations = _generateBudgetRecommendations(
        transactions,
        totalIncome,
        totalExpenses,
      );
      insights.addAll(budgetRecommendations);

      // Generate personalized tips
      final personalizedTips = _generatePersonalizedTips(
        transactions,
        categories,
        totalIncome,
        totalExpenses,
      );
      insights.addAll(personalizedTips);
    }

    return insights.take(5).toList(); // Return top 5 insights
  }

  /// Generate insights using Firebase AI
  Future<List<String>> _generateFirebaseAIInsights(
    List<Transaction> transactions,
    List<Category> categories,
    double totalIncome,
    double totalExpenses,
  ) async {
    final insights = <String>[];

    // Prepare transaction data for AI analysis
    final transactionData = _prepareTransactionData(transactions, categories);

    // Create prompt for AI analysis
    final prompt =
        '''
Analyze the following financial transaction data and provide personalized insights:

Total Income: $totalIncome
Total Expenses: $totalExpenses
Net Savings: ${totalIncome - totalExpenses}
Number of Transactions: ${transactions.length}

Recent Transactions:
$transactionData

Please provide 3-5 actionable insights about spending patterns, budget recommendations, and personalized tips.
Format each insight as a short, clear sentence starting with "AI Insight:" or "AI Recommendation:" or "AI Tip:".
''';

    try {
      // Generate content using Firebase AI (fallback to pattern analysis if AI fails)
      // TODO: Replace with actual Firebase AI API call (e.g., Cloud Functions, Vertex AI)
      final aiResponse =
          'Simulated AI response for now. Integrate real Firebase AI here.';

      // Parse AI response into individual insights
      final lines = aiResponse.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty &&
            (trimmedLine.startsWith('AI Insight:') ||
                trimmedLine.startsWith('AI Recommendation:') ||
                trimmedLine.startsWith('AI Tip:'))) {
          insights.add(trimmedLine);
        }
      }

      // If AI didn't provide proper insights, fall back to pattern analysis
      if (insights.isEmpty) {
        throw Exception('No valid AI insights generated');
      }
    } catch (e) {
      throw Exception('Failed to generate AI insights: $e');
    }

    return insights;
  }

  /// Prepare transaction data for AI analysis
  String _prepareTransactionData(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final recentTransactions = transactions.take(20).toList();
    final data = <String>[];

    for (final transaction in recentTransactions) {
      final categoryName = _getCategoryName(transaction.categoryId, categories);
      data.add(
        '- ${transaction.title}: ${transaction.amount} on ${transaction.date.toLocal().toString().split(' ')[0]} '
        '(Category: $categoryName${transaction.description != null ? ', Note: ${transaction.description}' : ''})',
      );
    }

    return data.join('\n');
  }

  /// Analyze spending patterns using AI
  List<String> _analyzeSpendingPatterns(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final insights = <String>[];

    // Separate consumption expenses from savings/investments
    final consumptionTransactions = transactions
        .where((t) => t.categoryId != 'expense_savings')
        .toList();

    final savingsTransactions = transactions
        .where((t) => t.categoryId == 'expense_savings')
        .toList();

    // Group consumption transactions by category
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (final transaction in consumptionTransactions) {
      final categoryName = _getCategoryName(transaction.categoryId, categories);
      categoryTotals[categoryName] =
          (categoryTotals[categoryName] ?? 0) + transaction.amount;
      categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
    }

    // Find top consumption spending categories
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isNotEmpty) {
      final topCategory = sortedCategories.first;
      final totalConsumptionSpent = categoryTotals.values.reduce(
        (a, b) => a + b,
      );
      final topCategoryPercentage =
          (topCategory.value / totalConsumptionSpent) * 100;

      if (topCategoryPercentage > 40) {
        insights.add(
          '💡 Insight: ${topCategoryPercentage.toStringAsFixed(1)}% of your consumption spending is on ${topCategory.key}. '
          'Consider diversifying your spending or finding ways to reduce expenses in this category.',
        );
      }

      // Positive insight for savings
      if (savingsTransactions.isNotEmpty) {
        final totalSavings = savingsTransactions.fold<double>(
          0,
          (sum, t) => sum + t.amount,
        );
        final savingsPercentage =
            (totalSavings / (totalConsumptionSpent + totalSavings)) * 100;

        if (savingsPercentage >= 20) {
          insights.add(
            '✅ Positive: Excellent savings discipline! You\'re allocating ${savingsPercentage.toStringAsFixed(1)}% '
            'of your total outflow to savings and investments.',
          );
        } else if (savingsPercentage >= 10) {
          insights.add(
            '💡 Insight: You\'re building good savings habits with ${savingsPercentage.toStringAsFixed(1)}% '
            'of your outflow going to savings. Consider increasing this to 20% for better financial security.',
          );
        }
      }

      // Check for frequent small transactions
      final frequentTransactions = categoryCounts.entries
          .where(
            (entry) =>
                entry.value > 15 &&
                categoryTotals[entry.key]! / entry.value < 100,
          )
          .toList();

      if (frequentTransactions.isNotEmpty) {
        insights.add(
          'AI Insight: You make many small purchases in ${frequentTransactions.first.key}. '
          'Consider consolidating purchases or setting a minimum spending threshold.',
        );
      }
    }

    // Detect unusual spending patterns
    final dailySpending = _calculateDailySpending(transactions);
    if (dailySpending.isNotEmpty) {
      final avgDailySpending =
          dailySpending.reduce((a, b) => a + b) / dailySpending.length;
      final maxDailySpending = dailySpending.reduce(max);

      if (maxDailySpending > avgDailySpending * 3) {
        insights.add(
          'AI Insight: Unusual spending spike detected! Your highest daily spending was '
          '${(maxDailySpending / avgDailySpending).toStringAsFixed(1)}x your average. '
          'Review what caused this spike.',
        );
      }
    }

    return insights;
  }

  /// Generate budget recommendations using AI
  List<String> _generateBudgetRecommendations(
    List<Transaction> transactions,
    double totalIncome,
    double totalExpenses,
  ) {
    final insights = <String>[];

    if (totalIncome <= 0) return insights;

    // Separate savings from consumption expenses
    final consumptionExpenses = transactions
        .where((t) => t.categoryId != 'expense_savings')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final savingsAmount = transactions
        .where((t) => t.categoryId == 'expense_savings')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final actualSavingsRate = totalIncome > 0
        ? (savingsAmount / totalIncome)
        : 0;
    final consumptionRate = totalIncome > 0
        ? (consumptionExpenses / totalIncome)
        : 0;

    // AI-powered budget recommendations based on spending patterns
    if (actualSavingsRate < 0.1) {
      insights.add(
        '🎯 Recommendation: Your savings rate is ${(actualSavingsRate * 100).toStringAsFixed(1)}%. '
        'Try the 50/30/20 rule: 50% for needs, 30% for wants, 20% for savings.',
      );
    } else if (actualSavingsRate >= 0.2) {
      insights.add(
        '✅ Positive: Excellent savings discipline! You\'re saving ${(actualSavingsRate * 100).toStringAsFixed(1)}% of your income. '
        'Consider investing your excess savings for long-term growth.',
      );
    }

    // Provide insights on consumption vs savings balance
    if (consumptionRate > 0.8 && actualSavingsRate < 0.1) {
      insights.add(
        '💡 Insight: You\'re spending ${(consumptionRate * 100).toStringAsFixed(1)}% of your income on consumption. '
        'Consider reallocating 10-15% to savings for better financial security.',
      );
    }

    // Analyze expense trends
    final recentTransactions = transactions
        .where(
          (t) =>
              t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))),
        )
        .toList();

    if (recentTransactions.length >= 10) {
      final avgTransactionAmount =
          recentTransactions.map((t) => t.amount).reduce((a, b) => a + b) /
          recentTransactions.length;

      if (avgTransactionAmount > totalIncome * 0.05) {
        insights.add(
          'AI Recommendation: Your average transaction is quite high relative to your income. '
          'Consider setting transaction limits to better control spending.',
        );
      }
    }

    return insights;
  }

  /// Generate personalized tips using AI
  List<String> _generatePersonalizedTips(
    List<Transaction> transactions,
    List<Category> categories,
    double totalIncome,
    double totalExpenses,
  ) {
    final insights = <String>[];

    // Analyze transaction descriptions for patterns
    final descriptions = transactions
        .map((t) => t.description?.toLowerCase() ?? '')
        .toList();

    // Check for dining/food expenses
    final foodKeywords = [
      'food',
      'restaurant',
      'cafe',
      'coffee',
      'lunch',
      'dinner',
      'breakfast',
    ];
    final foodTransactions = descriptions
        .where((desc) => foodKeywords.any((keyword) => desc.contains(keyword)))
        .length;

    if (foodTransactions > transactions.length * 0.2) {
      insights.add(
        'AI Tip: You spend a lot on food and dining. Try meal planning and cooking at home '
        'to reduce food expenses by up to 30%.',
      );
    }

    // Check for transportation expenses
    final transportKeywords = [
      'transport',
      'fuel',
      'gas',
      'bus',
      'uber',
      'taxi',
    ];
    final transportTransactions = descriptions
        .where(
          (desc) => transportKeywords.any((keyword) => desc.contains(keyword)),
        )
        .length;

    if (transportTransactions > transactions.length * 0.15) {
      insights.add(
        'AI Tip: Consider carpooling, using public transport, or walking for short distances '
        'to save on transportation costs.',
      );
    }

    // Check for entertainment expenses
    final entertainmentKeywords = [
      'movie',
      'cinema',
      'netflix',
      'streaming',
      'game',
      'entertainment',
    ];
    final entertainmentTransactions = descriptions
        .where(
          (desc) =>
              entertainmentKeywords.any((keyword) => desc.contains(keyword)),
        )
        .length;

    if (entertainmentTransactions > transactions.length * 0.1) {
      insights.add(
        'AI Tip: Look for free or low-cost entertainment options like parks, free events, '
        'or review your subscription services.',
      );
    }

    // General financial health tips
    if (totalIncome > 0) {
      // Separate savings from consumption expenses
      final consumptionExpenses = transactions
          .where((t) => t.categoryId != 'expense_savings')
          .fold<double>(0, (sum, t) => sum + t.amount);

      final savingsAmount = transactions
          .where((t) => t.categoryId == 'expense_savings')
          .fold<double>(0, (sum, t) => sum + t.amount);

      final consumptionRatio = consumptionExpenses / totalIncome;
      final savingsRatio = savingsAmount / totalIncome;

      if (consumptionRatio > 0.8 && savingsRatio < 0.1) {
        insights.add(
          '💡 Insight: You\'re spending ${(consumptionRatio * 100).toStringAsFixed(1)}% of your income on consumption '
          'while only saving ${(savingsRatio * 100).toStringAsFixed(1)}%. Consider reallocating to savings for financial security.',
        );
      } else if (consumptionRatio < 0.6 && savingsRatio > 0.15) {
        insights.add(
          '✅ Positive: Excellent financial management! You\'re keeping consumption expenses low '
          '(${(consumptionRatio * 100).toStringAsFixed(1)}%) while maintaining a ${(savingsRatio * 100).toStringAsFixed(1)}% savings rate.',
        );
      } else if (savingsRatio >= 0.2) {
        insights.add(
          '✅ Positive: Outstanding savings discipline! You\'re saving ${(savingsRatio * 100).toStringAsFixed(1)}% of your income. '
          'This puts you ahead of most financial goals.',
        );
      }
    }

    return insights;
  }

  /// Extract text from image using Google ML Kit (for receipt processing)
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      // This would use Google ML Kit in a real implementation
      // For now, we'll simulate text extraction
      return 'Simulated text extraction from receipt';
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Process receipt text to extract transaction information
  Future<Map<String, dynamic>?> processReceiptText(String text) async {
    try {
      // Simple pattern matching for receipt processing
      final amountPattern = RegExp(
        r'(?i)(?:total|amount|due)\s*[:\-]?\s*(\d+\.?\d*)',
      );
      final datePattern = RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})');
      final merchantPattern = RegExp(
        r'(?i)(?:merchant|store|shop|vendor)\s*[:\-]?\s*(.+)',
      );

      final amountMatch = amountPattern.firstMatch(text);
      final dateMatch = datePattern.firstMatch(text);
      final merchantMatch = merchantPattern.firstMatch(text);

      return {
        'amount': amountMatch != null
            ? double.tryParse(amountMatch.group(1)!)
            : null,
        'date': dateMatch != null ? _parseDate(dateMatch.group(1)!) : null,
        'merchant': merchantMatch?.group(1)?.trim(),
        'rawText': text,
      };
    } catch (e) {
      throw Exception('Failed to process receipt text: $e');
    }
  }

  /// Helper method to parse date from string
  DateTime? _parseDate(String dateString) {
    try {
      // Try different date formats
      final formats = [
        RegExp(r'^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})$'),
        RegExp(r'^(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})$'),
      ];

      for (final format in formats) {
        final match = format.firstMatch(dateString);
        if (match != null) {
          final parts = [
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          ];

          // Adjust for 2-digit year
          if (parts[2] < 100) {
            parts[2] += parts[2] < 50 ? 2000 : 1900;
          }

          return DateTime(parts[2], parts[1], parts[0]);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate daily spending amounts
  List<double> _calculateDailySpending(List<Transaction> transactions) {
    final dailySpending = <double>{};
    final dailyTotals = <DateTime, double>{};

    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyTotals[date] = (dailyTotals[date] ?? 0) + transaction.amount;
    }

    return dailyTotals.values.toList();
  }

  /// Generate AI-powered spending summary
  Future<String> generateSpendingSummary({
    required List<Transaction> transactions,
    required double totalIncome,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (transactions.isEmpty) {
      return 'No transactions to analyze in this period.';
    }

    final totalExpenses = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final avgTransaction = totalExpenses / transactions.length;
    final daysInPeriod = endDate.difference(startDate).inDays + 1;
    final avgDailySpending = totalExpenses / daysInPeriod;

    // Find most common category
    final categoryCounts = <String, int>{};
    for (final transaction in transactions) {
      final categoryName = _getCategoryName(transaction.categoryId, []);
      categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
    }

    final mostCommonCategory = categoryCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return '''
AI Spending Summary (${startDate.toLocal().toString().split(' ')[0]} - ${endDate.toLocal().toString().split(' ')[0]}):

• Total Expenses: ${totalExpenses.toStringAsFixed(2)}
• Average Transaction: ${avgTransaction.toStringAsFixed(2)}
• Average Daily Spending: ${avgDailySpending.toStringAsFixed(2)}
• Most Common Category: $mostCommonCategory
• Transaction Count: ${transactions.length}

AI Analysis: Your spending patterns show ${avgDailySpending > 1000 ? 'high daily expenses' : 'moderate daily spending'}.
${totalExpenses > totalIncome * 0.8 ? 'Warning: You\'re spending most of your income.' : 'Good: You\'re keeping expenses under control.'}
''';
  }

  /// Helper method to get category name by ID
  String _getCategoryName(String categoryId, List<Category> categories) {
    if (categories.isEmpty) {
      return 'Unknown';
    }

    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category.create(
        name: 'Unknown',
        icon: 'help_outline',
        color: Colors.grey,
        type: CategoryType.expense,
        userId: '',
      ),
    );

    return category.name;
  }
}
