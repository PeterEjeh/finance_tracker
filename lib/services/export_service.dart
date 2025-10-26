import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/report.dart';
import '../models/currency.dart';
import 'settings_service.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _fileNameDateFormat = DateFormat('yyyy-MM-dd');
  // App base currency code (e.g. 'NGN'). Loaded from settings at runtime.
  String _baseCurrencyCode = SupportedCurrencies.baseCurrency;

  /// Helper function to format currency for PDF with font fallback
  String _formatCurrencyForPDF(double amount) {
    // For PDF generation, always use the app's base currency code to avoid symbol/font issues
    final currencyCode = _baseCurrencyCode;
    return '${NumberFormat('#,##0.00').format(amount)} $currencyCode';
  }

  /// Export spending report as PDF
  Future<String> exportSpendingReportToPDF({
    required SpendingReport report,
    required List<Category> categories,
  }) async {
    await _loadBaseCurrency();
    // Ensure logo is loaded into memory before building PDF pages
    await _loadLogoImage();
    final pdf = pw.Document();

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildPDFHeader(report),
            pw.SizedBox(height: 20),
            _buildPDFSummary(report),
            pw.SizedBox(height: 20),
            _buildPDFCategoryBreakdown(report),
            pw.SizedBox(height: 20),
            _buildPDFDailyBreakdown(report),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await _getExportDirectory();
    final fileName =
        'spending_report_${_fileNameDateFormat.format(report.startDate)}_to_${_fileNameDateFormat.format(report.endDate)}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Export transactions as CSV
  Future<String> exportTransactionsToCSV({
    required List<Transaction> transactions,
    required List<Category> categories,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _loadBaseCurrency();
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add([
      'Date',
      'Title',
      'Amount',
      'Currency',
      'Original Amount',
      'Original Currency',
      'Exchange Rate',
      'Type',
      'Category',
      'Notes',
      'Created At',
    ]);

    // Create category lookup map
    final categoryMap = {for (var cat in categories) cat.id: cat.name};

    // Add transaction data
    for (final transaction in transactions) {
      final amountInBase = _toBaseAmount(transaction);
      // If the transaction uses a foreign currency, ensure original amount/currency are noted.
      final origAmount = transaction.originalAmount != null
          ? transaction.originalAmount
          : (transaction.currencyCode != _baseCurrencyCode
                ? transaction.amount
                : null);
      final origCurrency = transaction.originalCurrencyCode != null
          ? transaction.originalCurrencyCode
          : (transaction.currencyCode != _baseCurrencyCode
                ? transaction.currencyCode
                : null);

      csvData.add([
        _dateFormat.format(transaction.date),
        transaction.title,
        amountInBase,
        transaction.currencyCode,
        origAmount ?? '',
        origCurrency ?? '',
        transaction.exchangeRate ?? '',
        transaction.type.name,
        categoryMap[transaction.categoryId] ?? 'Unknown',
        transaction.description ?? '',
        _dateFormat.format(transaction.createdAt),
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Save to file
    final directory = await _getExportDirectory();
    final fileName =
        'transactions_${_fileNameDateFormat.format(startDate)}_to_${_fileNameDateFormat.format(endDate)}.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csvString);

    return file.path;
  }

  /// Export transactions as PDF
  Future<String> exportTransactionsToPDF({
    required List<Transaction> transactions,
    required List<Category> categories,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _loadBaseCurrency();
    // Ensure logo is loaded into memory before building PDF pages
    await _loadLogoImage();
    final pdf = pw.Document();

    // Create category lookup map
    final categoryMap = {for (var cat in categories) cat.id: cat.name};

    // Calculate summary statistics

    // Calculate totals in base currency
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + _toBaseAmount(t));
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + _toBaseAmount(t));
    final netAmount = totalIncome - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header (include logo when available)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'FinanceTracker - Transaction Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (_logoImageProvider != null)
                      pw.Container(
                        height: 40,
                        width: 40,
                        child: pw.Image(
                          _logoImageProvider!,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Period: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Generated: ${_dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Total Transactions: ${transactions.length}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPDFSummaryCard(
                  'Total Income',
                  _formatCurrencyForPDF(totalIncome),
                  PdfColors.green,
                ),
                _buildPDFSummaryCard(
                  'Total Expenses',
                  _formatCurrencyForPDF(totalExpenses),
                  PdfColors.red,
                ),
                _buildPDFSummaryCard(
                  'Net Amount',
                  _formatCurrencyForPDF(netAmount),
                  netAmount >= 0 ? PdfColors.green : PdfColors.red,
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Transactions Table
            pw.Text(
              'Transaction Details',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            // Use explicit column widths and slightly smaller text to reduce wrapping.
            pw.Table(
              // Column widths tuned to keep 'Type' and 'Date' narrow while giving space to Title/Category.
              columnWidths: {
                0: pw.FixedColumnWidth(60), // Date
                1: pw.FlexColumnWidth(3), // Title
                2: pw.FlexColumnWidth(2), // Category
                3: pw.FixedColumnWidth(80), // Amount
                4: pw.FixedColumnWidth(90), // Original Amount
                5: pw.FixedColumnWidth(55), // Type
              },
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildPDFTableCell('Date', isHeader: true),
                    _buildPDFTableCell('Title', isHeader: true),
                    _buildPDFTableCell('Category', isHeader: true),
                    _buildPDFTableCell('Amount', isHeader: true),
                    _buildPDFTableCell('Original Amount', isHeader: true),
                    _buildPDFTableCell('Type', isHeader: true),
                  ],
                ),
                // Data rows
                ...transactions.map(
                  (transaction) => pw.TableRow(
                    children: [
                      _buildPDFTableCell(_dateFormat.format(transaction.date)),
                      _buildPDFTableCell(transaction.title),
                      _buildPDFTableCell(
                        categoryMap[transaction.categoryId] ?? 'Unknown',
                      ),
                      _buildPDFTableCell(
                        _formatCurrencyForPDF(_toBaseAmount(transaction)),
                        color: transaction.type == TransactionType.income
                            ? PdfColors.green
                            : PdfColors.red,
                      ),
                      _buildPDFTableCell(
                        transaction.originalAmount != null
                            ? '${NumberFormat('#,##0.00').format(transaction.originalAmount!)} ${transaction.originalCurrencyCode ?? ''}'
                            : (transaction.currencyCode != _baseCurrencyCode
                                  ? '${NumberFormat('#,##0.00').format(transaction.amount)} ${transaction.currencyCode}'
                                  : ''),
                      ),
                      // Keep the type column from wrapping by limiting lines and using wider column.
                      _buildPDFTableCell(transaction.type.name, maxLines: 1),
                    ],
                  ),
                ),
              ],
            ),

            // Notes section if any transactions have descriptions
            if (transactions.any(
              (t) => t.description?.isNotEmpty ?? false,
            )) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'Notes',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              ...transactions
                  .where((t) => t.description?.isNotEmpty ?? false)
                  .map(
                    (transaction) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${transaction.title} (${_dateFormat.format(transaction.date)})',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(transaction.description!),
                        ],
                      ),
                    ),
                  ),
            ],
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await _getExportDirectory();
    final fileName =
        'transactions_${_fileNameDateFormat.format(startDate)}_to_${_fileNameDateFormat.format(endDate)}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Export budget performance report as PDF
  Future<String> exportBudgetReportToPDF({
    required List<BudgetPerformanceReport> budgetReports,
    required DateTime reportDate,
  }) async {
    await _loadBaseCurrency();
    // Ensure logo is loaded into memory before building PDF pages
    await _loadLogoImage();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildBudgetPDFHeader(reportDate),
            pw.SizedBox(height: 20),
            _buildBudgetPDFSummary(budgetReports),
            pw.SizedBox(height: 20),
            _buildBudgetPDFDetails(budgetReports),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await _getExportDirectory();
    final fileName =
        'budget_report_${_fileNameDateFormat.format(reportDate)}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Export budgets as CSV
  Future<String> exportBudgetsToCSV({
    required List<Budget> budgets,
    required List<Category> categories,
  }) async {
    await _loadBaseCurrency();
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add([
      'Budget Name',
      'Category',
      'Amount',
      'Period',
      'Start Date',
      'End Date',
      'Type',
      'Status',
      'Alert Threshold',
      'Description',
    ]);

    // Create category lookup map
    final categoryMap = {for (var cat in categories) cat.id: cat.name};

    // Add budget data
    for (final budget in budgets) {
      csvData.add([
        budget.name,
        categoryMap[budget.categoryId] ?? 'Unknown',
        budget.amount, // Budget amounts assumed in base
        budget.period.displayName,
        _dateFormat.format(budget.startDate),
        _dateFormat.format(budget.endDate),
        budget.type.displayName,
        budget.isActive ? 'Active' : 'Inactive',
        '${(budget.alertThreshold * 100).toInt()}%',
        budget.description ?? '',
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Save to file
    final directory = await _getExportDirectory();
    final fileName =
        'budgets_${_fileNameDateFormat.format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csvString);

    return file.path;
  }

  /// Export all user data as PDF
  Future<String> exportAllDataToPDF({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Category> categories,
    required String userName,
  }) async {
    await _loadBaseCurrency();
    // Ensure logo is loaded into memory before building PDF pages
    await _loadLogoImage();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildAllDataPDFHeader(userName),
            pw.SizedBox(height: 20),
            _buildAllDataPDFSummary(transactions, budgets),
            pw.SizedBox(height: 20),
            _buildAllDataPDFTransactions(transactions, categories),
            pw.SizedBox(height: 20),
            _buildAllDataPDFBudgets(budgets, categories),
            pw.SizedBox(height: 20),
            _buildAllDataPDFCategories(categories),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await _getExportDirectory();
    final fileName =
        'finance_tracker_full_export_${_fileNameDateFormat.format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Export all user data as CSV
  Future<String> exportAllDataToCSV({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Category> categories,
    required String userName,
  }) async {
    await _loadBaseCurrency();
    // Create directory for multiple CSV files
    final directory = await _getExportDirectory();
    final timestamp = _fileNameDateFormat.format(DateTime.now());

    // Export transactions
    await _exportTransactionsToCSVFile(
      transactions: transactions,
      categories: categories,
      startDate: transactions.isNotEmpty
          ? transactions
                .map((t) => t.date)
                .reduce((a, b) => a.isBefore(b) ? a : b)
          : DateTime.now(),
      endDate: transactions.isNotEmpty
          ? transactions
                .map((t) => t.date)
                .reduce((a, b) => a.isAfter(b) ? a : b)
          : DateTime.now(),
      directory: directory,
      fileName: 'transactions_$timestamp.csv',
    );

    // Export budgets
    await _exportBudgetsToCSVFile(
      budgets: budgets,
      categories: categories,
      directory: directory,
      fileName: 'budgets_$timestamp.csv',
    );

    // Export categories
    await _exportCategoriesToCSVFile(
      categories: categories,
      directory: directory,
      fileName: 'categories_$timestamp.csv',
    );

    // Create summary CSV
    await _exportSummaryToCSVFile(
      transactions: transactions,
      budgets: budgets,
      categories: categories,
      userName: userName,
      directory: directory,
      fileName: 'export_summary_$timestamp.csv',
    );

    return directory.path;
  }

  /// Export transactions to CSV file
  Future<String> _exportTransactionsToCSVFile({
    required List<Transaction> transactions,
    required List<Category> categories,
    required DateTime startDate,
    required DateTime endDate,
    required Directory directory,
    required String fileName,
  }) async {
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add([
      'Date',
      'Title',
      'Amount',
      'Currency',
      'Original Amount',
      'Original Currency',
      'Exchange Rate',
      'Type',
      'Category',
      'Notes',
      'Created At',
    ]);

    // Create category lookup map
    final categoryMap = {for (var cat in categories) cat.id: cat.name};

    // Add transaction data
    for (final transaction in transactions) {
      final amountInBase = _toBaseAmount(transaction);
      csvData.add([
        _dateFormat.format(transaction.date),
        transaction.title,
        amountInBase,
        transaction.currencyCode,
        transaction.originalAmount ?? '',
        transaction.originalCurrencyCode ?? '',
        transaction.exchangeRate ?? '',
        transaction.type.name,
        categoryMap[transaction.categoryId] ?? 'Unknown',
        transaction.description ?? '',
        _dateFormat.format(transaction.createdAt),
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Save to file
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  /// Export budgets to CSV file
  Future<String> _exportBudgetsToCSVFile({
    required List<Budget> budgets,
    required List<Category> categories,
    required Directory directory,
    required String fileName,
  }) async {
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add([
      'Budget Name',
      'Category',
      'Amount',
      'Period',
      'Start Date',
      'End Date',
      'Type',
      'Status',
      'Alert Threshold',
      'Description',
    ]);

    // Create category lookup map
    final categoryMap = {for (var cat in categories) cat.id: cat.name};

    // Add budget data
    for (final budget in budgets) {
      csvData.add([
        budget.name,
        categoryMap[budget.categoryId] ?? 'Unknown',
        budget.amount,
        budget.period.displayName,
        _dateFormat.format(budget.startDate),
        _dateFormat.format(budget.endDate),
        budget.type.displayName,
        budget.isActive ? 'Active' : 'Inactive',
        '${(budget.alertThreshold * 100).toInt()}%',
        budget.description ?? '',
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Save to file
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  /// Export categories to CSV file
  Future<String> _exportCategoriesToCSVFile({
    required List<Category> categories,
    required Directory directory,
    required String fileName,
  }) async {
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add(['Name', 'Icon', 'Color', 'Type', 'Created At']);

    // Add category data
    for (final category in categories) {
      csvData.add([
        category.name,
        category.icon,
        category.colorValue.toString(),
        category.type.name,
        _dateFormat.format(category.createdAt),
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Save to file
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  /// Export summary to CSV file
  Future<String> _exportSummaryToCSVFile({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Category> categories,
    required String userName,
    required Directory directory,
    required String fileName,
  }) async {
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add(['Export Summary', 'Value']);

    // Calculate summary data
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final netAmount = totalIncome - totalExpenses;
    final activeBudgets = budgets.where((b) => b.isActive).length;
    final totalCategories = categories.length;

    // Add summary data
    csvData.addAll([
      ['User Name', userName],
      ['Export Date', _dateFormat.format(DateTime.now())],
      ['Total Transactions', transactions.length.toString()],
      ['Total Income', _formatCurrencyForPDF(totalIncome)],
      ['Total Expenses', _formatCurrencyForPDF(totalExpenses)],
      ['Net Amount', _formatCurrencyForPDF(netAmount)],
      ['Active Budgets', activeBudgets.toString()],
      ['Total Categories', totalCategories.toString()],
    ]);

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Save to file
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  /// Show download success message with file location.
  /// Backwards-compatible: callers that don't pass [context] will still see a console log.
  /// If [context] is provided, a friendly dialog is shown with actions to Share, copy the path,
  /// or move the file to a different available export directory.
  Future<void> showDownloadSuccess({
    BuildContext? context,
    required String filePath,
    String fileType = 'Export',
  }) async {
    // Get the directory where the file was saved
    final directory = await _getExportDirectory();
    final fileName = filePath.split('/').last;

    // Short friendly path for display when possible
    String friendlyPath;
    try {
      final exportDir = directory.path;
      if (filePath.contains(exportDir)) {
        friendlyPath = '$exportDir/$fileName';
      } else {
        friendlyPath = filePath;
      }
    } catch (_) {
      friendlyPath = filePath;
    }

    // Always log to console for debugging
    print('✅ $fileType exported successfully!');
    print('📁 File saved to: $filePath');
    print('📂 Directory: ${directory.path}');
    print('📄 File name: $fileName');

    // If no context provided, stop here (backwards-compatible)
    if (context == null) return;

    // Show a dialog with actions: Change location, Copy path, Share, OK
    try {
      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('$fileType saved'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saved to:'),
                const SizedBox(height: 6),
                SelectableText(
                  friendlyPath,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              // Allow user to move the file to a different location
              TextButton(
                onPressed: () async {
                  // Prompt for new location and attempt to move the file
                  final newPath = await _promptAndMoveFile(
                    ctx,
                    filePath,
                    fileName,
                  );
                  if (newPath != null) {
                    // Close current dialog and show updated success dialog for new location
                    Navigator.of(ctx).pop();
                    await showDownloadSuccess(
                      context: context,
                      filePath: newPath,
                      fileType: fileType,
                    );
                  }
                },
                child: const Text('Change location'),
              ),
              TextButton(
                onPressed: () async {
                  // Copy path to clipboard
                  await Clipboard.setData(ClipboardData(text: filePath));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File path copied to clipboard'),
                    ),
                  );
                },
                child: const Text('Copy path'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop(); // close dialog before sharing
                  try {
                    // Use share_plus to let the user open or share the file
                    await Share.shareXFiles([
                      XFile(filePath),
                    ], text: '$fileType');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sharing file: $e')),
                    );
                  }
                },
                child: const Text('Share'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // If dialog fails for any reason, fallback to a SnackBar
      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$fileType saved: $fileName')));
      } catch (_) {}
    }
  }

  /// Prompt the user to choose a directory (Downloads, App Documents, or detected SD card) and move the file there.
  /// Returns the new path on success, or null if cancelled/failed.
  Future<String?> _promptAndMoveFile(
    BuildContext context,
    String oldPath,
    String fileName,
  ) async {
    try {
      // Attempt to detect removable SD card mount points under /storage (e.g., XXXX-XXXX)
      final sdCandidates = <Directory>[];
      try {
        final storageRoot = Directory('/storage');
        if (await storageRoot.exists()) {
          for (final entry in storageRoot.listSync()) {
            if (entry is Directory) {
              final name = entry.path.split('/').last;
              // Typical removable storage names contain a dash, e.g. "XXXX-XXXX"
              if (name.contains('-')) {
                sdCandidates.add(entry);
              }
            }
          }
        }
      } catch (_) {
        // ignore detection errors — we'll still offer default options
      }

      final choice = await showDialog<String?>(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            title: const Text('Choose save location'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, 'downloads'),
                child: const Text('Downloads (FinanceTracker)'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, 'documents'),
                child: const Text('App documents (FinanceTracker)'),
              ),
              // Add detected SD card options if any
              ...sdCandidates.map((dir) {
                final label = dir.path.split('/').last;
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, dir.path),
                  child: Text('SD card ($label)'),
                );
              }).toList(),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (choice == null) return null;

      Directory targetDir;
      if (choice == 'downloads') {
        // Try best-effort to get a downloads directory
        try {
          final downloads = await getDownloadsDirectory();
          if (downloads != null) {
            targetDir = Directory('${downloads.path}/FinanceTracker');
          } else {
            // fallback to common Android downloads path
            targetDir = Directory(
              '/storage/emulated/0/Download/FinanceTracker',
            );
          }
        } catch (_) {
          targetDir = Directory('/storage/emulated/0/Download/FinanceTracker');
        }
      } else if (choice == 'documents') {
        final docs = await getApplicationDocumentsDirectory();
        targetDir = Directory('${docs.path}/FinanceTracker');
      } else {
        // User selected an SD card path (choice contains the raw mount path)
        targetDir = Directory('${choice}/FinanceTracker');
      }

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final newPath = '${targetDir.path}/$fileName';
      final oldFile = File(oldPath);
      final newFile = await oldFile.copy(newPath);

      // Optionally delete the old file if it differs
      try {
        if (oldFile.path != newFile.path) {
          await oldFile.delete();
        }
      } catch (_) {}

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Moved to: ${newFile.path}')));
      return newFile.path;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to move file: $e')));
      return null;
    }
  }

  Future<Directory> _getExportDirectory() async {
    // Prefer Downloads if accessible, else fall back to app documents
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        final dir = Directory('${downloads.path}/FinanceTracker');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    } catch (_) {}
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/FinanceTracker');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _loadBaseCurrency() async {
    try {
      final settings = SettingsService();
      final baseCode = await settings.getCurrency();
      final currency = SupportedCurrencies.getCurrency(baseCode);
      _baseCurrencyCode = currency?.code ?? _baseCurrencyCode;
    } catch (_) {}
  }

  // Cache logo bytes for PDF headers
  pw.MemoryImage? _logoImageProvider;

  Future<pw.MemoryImage?> _loadLogoImage() async {
    if (_logoImageProvider != null) return _logoImageProvider;
    try {
      final data = await rootBundle.load(
        'assets/images/finance-tracker-logo.png',
      );
      final bytes = data.buffer.asUint8List();
      _logoImageProvider = pw.MemoryImage(bytes);
      return _logoImageProvider;
    } catch (_) {
      return null;
    }
  }

  double _toBaseAmount(Transaction transaction) {
    // Use the app's loaded base currency code. Convert when needed.
    // If already in base or missing data, use amount.
    // Prefer originalAmount when it represents the base currency.
    final baseCode = _baseCurrencyCode;
    if (transaction.currencyCode == baseCode) return transaction.amount;
    if (transaction.originalCurrencyCode == baseCode &&
        transaction.originalAmount != null) {
      return transaction.originalAmount!;
    }
    // When a stored exchange rate exists the app stores the rate such that
    // converted_base_amount = transaction.amount * exchangeRate
    // (see DatabaseService where stored rates are applied). Multiply here
    // to keep behavior consistent across the app.
    if (transaction.exchangeRate != null && transaction.exchangeRate! > 0) {
      return transaction.amount * transaction.exchangeRate!;
    }
    return 0.0; // Return 0.0 if conversion is needed but exchange rate is missing
  }

  /// Build PDF header for spending report
  pw.Widget _buildPDFHeader(SpendingReport report) {
    final logo = _logoImageProvider;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (logo != null)
              pw.Container(
                height: 40,
                width: 40,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            pw.Text(
              'FinanceTracker - Spending Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Period: ${_dateFormat.format(report.startDate)} - ${_dateFormat.format(report.endDate)}',
          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.Text(
          'Generated: ${_dateFormat.format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  /// Build PDF summary section
  pw.Widget _buildPDFSummary(SpendingReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildPDFSummaryCard(
              'Total Income',
              _formatCurrencyForPDF(report.totalIncome),
              PdfColors.green,
            ),
            _buildPDFSummaryCard(
              'Total Expenses',
              _formatCurrencyForPDF(report.totalExpenses),
              PdfColors.red,
            ),
            _buildPDFSummaryCard(
              'Net Amount',
              _formatCurrencyForPDF(report.netAmount),
              report.netAmount >= 0 ? PdfColors.green : PdfColors.red,
            ),
          ],
        ),
      ],
    );
  }

  /// Build PDF summary card
  pw.Widget _buildPDFSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build PDF category breakdown
  pw.Widget _buildPDFCategoryBreakdown(SpendingReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Category Breakdown',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPDFTableCell('Category', isHeader: true),
                _buildPDFTableCell('Amount', isHeader: true),
                _buildPDFTableCell('Transactions', isHeader: true),
                _buildPDFTableCell('Percentage', isHeader: true),
              ],
            ),
            // Data rows
            ...report.categoryBreakdown
                .take(10)
                .map(
                  (category) => pw.TableRow(
                    children: [
                      _buildPDFTableCell(category.categoryName),
                      _buildPDFTableCell(
                        _formatCurrencyForPDF(category.totalAmount),
                      ),
                      _buildPDFTableCell('${category.transactionCount}'),
                      _buildPDFTableCell(
                        '${category.percentage.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  /// Build PDF daily breakdown (summary)
  pw.Widget _buildPDFDailyBreakdown(SpendingReport report) {
    final recentDays = report.dailyBreakdown
        .where((day) => day.transactionCount > 0)
        .take(10)
        .toList();

    if (recentDays.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Daily Activity',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPDFTableCell('Date', isHeader: true),
                _buildPDFTableCell('Income', isHeader: true),
                _buildPDFTableCell('Expenses', isHeader: true),
                _buildPDFTableCell('Net', isHeader: true),
                _buildPDFTableCell('Transactions', isHeader: true),
              ],
            ),
            // Data rows
            ...recentDays.map(
              (day) => pw.TableRow(
                children: [
                  _buildPDFTableCell(_dateFormat.format(day.date)),
                  _buildPDFTableCell(_formatCurrencyForPDF(day.totalIncome)),
                  _buildPDFTableCell(_formatCurrencyForPDF(day.totalExpenses)),
                  _buildPDFTableCell(_formatCurrencyForPDF(day.netAmount)),
                  _buildPDFTableCell('${day.transactionCount}'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build PDF table cell
  pw.Widget _buildPDFTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? color,
    int? maxLines,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        // Reduce font sizes slightly and limit lines to avoid row wrapping.
        maxLines: maxLines ?? (isHeader ? 2 : 2),
        // The pdf package supports clip; use clip so text does not overflow table cells.
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  /// Build budget PDF header
  pw.Widget _buildBudgetPDFHeader(DateTime reportDate) {
    final logo = _logoImageProvider;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (logo != null)
              pw.Container(
                height: 40,
                width: 40,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            pw.Text(
              'FinanceTracker - Budget Performance Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Report Date: ${_dateFormat.format(reportDate)}',
          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  /// Build budget PDF summary
  pw.Widget _buildBudgetPDFSummary(List<BudgetPerformanceReport> reports) {
    final totalBudgeted = reports.fold<double>(
      0,
      (sum, report) => sum + report.budgetAmount,
    );
    final totalSpent = reports.fold<double>(
      0,
      (sum, report) => sum + report.actualSpent,
    );
    final onTrackCount = reports
        .where((r) => r.status == BudgetPerformanceStatus.onTrack)
        .length;
    final overBudgetCount = reports
        .where((r) => r.status == BudgetPerformanceStatus.overBudget)
        .length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Budget Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildPDFSummaryCard(
              'Total Budgeted',
              _formatCurrencyForPDF(totalBudgeted),
              PdfColors.blue,
            ),
            _buildPDFSummaryCard(
              'Total Spent',
              _formatCurrencyForPDF(totalSpent),
              PdfColors.orange,
            ),
            _buildPDFSummaryCard(
              'On Track',
              '$onTrackCount/${reports.length}',
              PdfColors.green,
            ),
            _buildPDFSummaryCard(
              'Over Budget',
              '$overBudgetCount',
              PdfColors.red,
            ),
          ],
        ),
      ],
    );
  }

  /// Build budget PDF details
  pw.Widget _buildBudgetPDFDetails(List<BudgetPerformanceReport> reports) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Budget Details',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPDFTableCell('Budget', isHeader: true),
                _buildPDFTableCell('Category', isHeader: true),
                _buildPDFTableCell('Budgeted', isHeader: true),
                _buildPDFTableCell('Spent', isHeader: true),
                _buildPDFTableCell('Remaining', isHeader: true),
                _buildPDFTableCell('Status', isHeader: true),
              ],
            ),
            // Data rows
            ...reports.map(
              (report) => pw.TableRow(
                children: [
                  _buildPDFTableCell(report.budgetName),
                  _buildPDFTableCell(report.categoryName),
                  _buildPDFTableCell(
                    _formatCurrencyForPDF(report.budgetAmount),
                  ),
                  _buildPDFTableCell(_formatCurrencyForPDF(report.actualSpent)),
                  _buildPDFTableCell(_formatCurrencyForPDF(report.variance)),
                  _buildPDFTableCell(_getBudgetStatusText(report.status)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Get budget status text
  String _getBudgetStatusText(BudgetPerformanceStatus status) {
    switch (status) {
      case BudgetPerformanceStatus.onTrack:
        return 'On Track';
      case BudgetPerformanceStatus.warning:
        return 'Warning';
      case BudgetPerformanceStatus.overBudget:
        return 'Over Budget';
      case BudgetPerformanceStatus.underBudget:
        return 'Under Budget';
    }
  }

  /// Build all data PDF header
  pw.Widget _buildAllDataPDFHeader(String userName) {
    final logo = _logoImageProvider;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (logo != null)
              pw.Container(
                height: 40,
                width: 40,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            pw.Text(
              'FinanceTracker - Full Data Export',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'User: $userName',
          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.Text(
          'Export Date: ${_dateFormat.format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  /// Build all data PDF summary
  pw.Widget _buildAllDataPDFSummary(
    List<Transaction> transactions,
    List<Budget> budgets,
  ) {
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final netAmount = totalIncome - totalExpenses;
    final activeBudgets = budgets.where((b) => b.isActive).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildPDFSummaryCard(
              'Total Transactions',
              transactions.length.toString(),
              PdfColors.blue,
            ),
            _buildPDFSummaryCard(
              'Total Income',
              _formatCurrencyForPDF(totalIncome),
              PdfColors.green,
            ),
            _buildPDFSummaryCard(
              'Total Expenses',
              _formatCurrencyForPDF(totalExpenses),
              PdfColors.red,
            ),
            _buildPDFSummaryCard(
              'Net Amount',
              _formatCurrencyForPDF(netAmount),
              netAmount >= 0 ? PdfColors.green : PdfColors.red,
            ),
            _buildPDFSummaryCard(
              'Active Budgets',
              activeBudgets.toString(),
              PdfColors.purple,
            ),
          ],
        ),
      ],
    );
  }

  /// Build all data PDF transactions
  pw.Widget _buildAllDataPDFTransactions(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    if (transactions.isEmpty) {
      return pw.SizedBox();
    }

    // Create category lookup map
    final categoryMap = {for (var cat in categories) cat.id: cat.name};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Transactions',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPDFTableCell('Date', isHeader: true),
                _buildPDFTableCell('Title', isHeader: true),
                _buildPDFTableCell('Amount', isHeader: true),
                _buildPDFTableCell('Currency', isHeader: true),
                _buildPDFTableCell('Orig. Amount', isHeader: true),
                _buildPDFTableCell('Orig. Currency', isHeader: true),
                _buildPDFTableCell('Type', isHeader: true),
                _buildPDFTableCell('Category', isHeader: true),
              ],
            ),
            // Data rows (limit to 20 most recent)
            ...transactions
                .take(20)
                .map(
                  (transaction) => pw.TableRow(
                    children: [
                      _buildPDFTableCell(_dateFormat.format(transaction.date)),
                      _buildPDFTableCell(transaction.title),
                      _buildPDFTableCell(
                        _formatCurrencyForPDF(_toBaseAmount(transaction)),
                        color: transaction.type == TransactionType.income
                            ? PdfColors.green
                            : PdfColors.red,
                      ),
                      _buildPDFTableCell(transaction.currencyCode),
                      _buildPDFTableCell(
                        transaction.originalAmount != null
                            ? '${NumberFormat('#,##0.00').format(transaction.originalAmount!)} ${transaction.originalCurrencyCode ?? ''}'
                            : (transaction.currencyCode != _baseCurrencyCode
                                  ? '${NumberFormat('#,##0.00').format(transaction.amount)} ${transaction.currencyCode}'
                                  : ''),
                      ),
                      _buildPDFTableCell(
                        transaction.originalCurrencyCode != null
                            ? transaction.originalCurrencyCode!
                            : (transaction.currencyCode != _baseCurrencyCode
                                  ? transaction.currencyCode
                                  : ''),
                      ),
                      _buildPDFTableCell(transaction.type.name, maxLines: 1),
                      _buildPDFTableCell(
                        categoryMap[transaction.categoryId] ?? 'Unknown',
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  /// Build all data PDF budgets
  pw.Widget _buildAllDataPDFBudgets(
    List<Budget> budgets,
    List<Category> categories,
  ) {
    if (budgets.isEmpty) {
      return pw.SizedBox();
    }

    // Create category lookup map
    final categoryMap = {for (var cat in categories) cat.id: cat.name};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Budgets',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPDFTableCell('Name', isHeader: true),
                _buildPDFTableCell('Category', isHeader: true),
                _buildPDFTableCell('Amount', isHeader: true),
                _buildPDFTableCell('Period', isHeader: true),
                _buildPDFTableCell('Status', isHeader: true),
              ],
            ),
            // Data rows
            ...budgets.map(
              (budget) => pw.TableRow(
                children: [
                  _buildPDFTableCell(budget.name),
                  _buildPDFTableCell(
                    categoryMap[budget.categoryId] ?? 'Unknown',
                  ),
                  _buildPDFTableCell(_formatCurrencyForPDF(budget.amount)),
                  _buildPDFTableCell(budget.period.displayName),
                  _buildPDFTableCell(
                    budget.isActive ? 'Active' : 'Inactive',
                    color: budget.isActive ? PdfColors.green : PdfColors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build all data PDF categories
  pw.Widget _buildAllDataPDFCategories(List<Category> categories) {
    if (categories.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Categories',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPDFTableCell('Name', isHeader: true),
                _buildPDFTableCell('Icon', isHeader: true),
                _buildPDFTableCell('Type', isHeader: true),
                _buildPDFTableCell('Created', isHeader: true),
              ],
            ),
            // Data rows
            ...categories.map(
              (category) => pw.TableRow(
                children: [
                  _buildPDFTableCell(category.name),
                  _buildPDFTableCell(category.icon),
                  _buildPDFTableCell(
                    category.type.name,
                    color: category.type == CategoryType.income
                        ? PdfColors.green
                        : PdfColors.red,
                  ),
                  _buildPDFTableCell(_dateFormat.format(category.createdAt)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
