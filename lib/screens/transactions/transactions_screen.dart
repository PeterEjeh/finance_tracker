import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/currency_settings_service.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/currency.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'add_transaction_screen.dart';
import '../../services/export_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  late TabController _tabController;
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TransactionType? _filterType;
  Category? _filterCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _filterType = null;
          break;
        case 1:
          _filterType = TransactionType.income;
          break;
        case 2:
          _filterType = TransactionType.expense;
          break;
      }
      _applyFilters();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';

      _allTransactions = _databaseService.getAllTransactions(userId: userId);
      _categories = _databaseService.getAllCategories(userId: userId);

      _applyFilters();
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((transaction) {
        // Filter by type
        if (_filterType != null && transaction.type != _filterType) {
          return false;
        }

        // Filter by category
        if (_filterCategory != null &&
            transaction.categoryId != _filterCategory!.id) {
          return false;
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return transaction.title.toLowerCase().contains(query) ||
              (transaction.description?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  // ignore: unused_element
  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteTransaction(transaction.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting transaction: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transactions',
          style:
              Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'filter':
                  _showFilterDialog();
                  break;
                case 'export_csv':
                  await _exportTransactionsCSV();
                  break;
                case 'export_pdf':
                  await _exportTransactionsPDF();
                  break;
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Theme.of(context).colorScheme.surface,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'filter', child: Text('Filter')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'export_csv', child: Text('Export (CSV)')),
              PopupMenuItem(value: 'export_pdf', child: Text('Export (PDF)')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _filteredTransactions.isEmpty
                        ? _buildEmptyState()
                        : _buildTransactionsList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  Future<void> _exportTransactionsCSV() async {
    try {
      if (_filteredTransactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export')),
        );
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final exportService = ExportService();
      final path = await exportService.exportTransactionsToCSV(
        transactions: _filteredTransactions,
        categories: _categories,
        startDate: _filteredTransactions
            .map((t) => t.date)
            .reduce((a, b) => a.isBefore(b) ? a : b),
        endDate: _filteredTransactions
            .map((t) => t.date)
            .reduce((a, b) => a.isAfter(b) ? a : b),
      );
      if (mounted) Navigator.pop(context);
      await exportService.showDownloadSuccess(
        context: context,
        filePath: path,
        fileType: 'CSV Export',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting transactions: $e')),
      );
    }
  }

  Future<void> _exportTransactionsPDF() async {
    try {
      if (_filteredTransactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export')),
        );
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final exportService = ExportService();
      final path = await exportService.exportTransactionsToPDF(
        transactions: _filteredTransactions,
        categories: _categories,
        startDate: _filteredTransactions
            .map((t) => t.date)
            .reduce((a, b) => a.isBefore(b) ? a : b),
        endDate: _filteredTransactions
            .map((t) => t.date)
            .reduce((a, b) => a.isAfter(b) ? a : b),
      );
      if (mounted) Navigator.pop(context);
      await exportService.showDownloadSuccess(
        context: context,
        filePath: path,
        fileType: 'PDF Export',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting transactions: $e')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No transactions found'
                  : 'No transactions yet',
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Add your first transaction to get started',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};
    for (final transaction in _filteredTransactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final transactions = groupedTransactions[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.7)
                      : const Color(0xFF666666),
                ),
              ),
            ),

            // Transactions for this date
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _buildTransactionTile(transaction);
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final category = _categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => Category.create(
        name: 'Unknown',
        icon: 'help_outline',
        color: Colors.grey,
        type: CategoryType.expense,
        userId: '',
      ),
    );

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: Text(
              'Are you sure you want to delete "${transaction.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _databaseService.deleteTransaction(transaction.id);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${transaction.title} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // TODO: Implement undo functionality
              },
            ),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.1),
          child: Icon(
            _getIconData(category.icon),
            color: category.color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.name,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            if (transaction.description != null &&
                transaction.description!.isNotEmpty)
              Text(
                transaction.description!,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.grey.shade500,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Builder(
          builder: (context) {
            final settings = Provider.of<CurrencySettingsService>(context);
            // A transaction may be stored in two ways:
            // 1) Stored in its original (foreign) currency (currencyCode != base)
            // 2) Stored in base currency with originalAmount/originalCurrencyCode set
            // Use the model's multi-currency information or originalAmount to
            // detect foreign transactions so we can show converted amount as
            // the main amount and the original foreign amount as the subtitle.
            final isForeignTransaction =
                transaction.isMultiCurrency ||
                (transaction.originalAmount != null &&
                    transaction.originalCurrencyCode != null) ||
                transaction.currencyCode != settings.baseCurrency.code;

            String mainAmountText;
            String? subtitleAmountText;
            Color amountColor = transaction.type == TransactionType.income
                ? Colors.green
                : Colors.red;

            // Determine converted/base amount when possible
            double? convertedValue;
            final baseCode = settings.baseCurrency.code;

            if (transaction.currencyCode == baseCode) {
              // Already stored in base currency
              convertedValue = transaction.amount;
            } else if (transaction.convertedAmount != null) {
              // Explicit converted amount stored
              convertedValue = transaction.convertedAmount;
            } else if (transaction.exchangeRate != null) {
              // Use stored exchange rate: treat transaction.amount as foreign amount
              convertedValue = transaction.amount * transaction.exchangeRate!;
            } else if (transaction.originalCurrencyCode == baseCode &&
                transaction.originalAmount != null) {
              // The original amount happens to be in base currency
              convertedValue = transaction.originalAmount;
            } else {
              convertedValue = null; // can't convert
            }

            // Build main and subtitle strings
            if (isForeignTransaction &&
                settings.showExchangeRates &&
                convertedValue != null) {
              // Show converted/base amount as main text
              mainAmountText =
                  '${transaction.type == TransactionType.income ? '+' : '-'}${_formatCurrency(convertedValue, baseCode)}';

              // Show original/foreign amount as subtitle if available
              if (transaction.originalAmount != null &&
                  transaction.originalCurrencyCode != null) {
                subtitleAmountText =
                    '${transaction.type == TransactionType.income ? '+' : '-'}${_formatCurrency(transaction.originalAmount!, transaction.originalCurrencyCode!)}';
              } else if (transaction.currencyCode != baseCode) {
                subtitleAmountText =
                    '${transaction.type == TransactionType.income ? '+' : '-'}${_formatCurrency(transaction.amount, transaction.currencyCode)}';
              }
            } else {
              // Fallback: show stored amount with its currency
              mainAmountText =
                  '${transaction.type == TransactionType.income ? '+' : '-'}${_formatCurrency(transaction.amount, transaction.currencyCode)}';
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mainAmountText,
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (subtitleAmountText != null)
                  Text(
                    subtitleAmountText,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                if (transaction.isRecurring)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.recurringType?.name.toUpperCase() ??
                          'RECURRING',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddTransactionScreen(editTransaction: transaction),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('MMM dd').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All Categories'),
                  selected: _filterCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _filterCategory = null;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                ),
                ..._categories.map(
                  (category) => FilterChip(
                    label: Text(category.name),
                    selected: _filterCategory?.id == category.id,
                    onSelected: (selected) {
                      setState(() {
                        _filterCategory = selected ? category : null;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.help_outline;
    }
  }

  String _formatCurrency(double amount, String currencyCode) {
    final settings = Provider.of<CurrencySettingsService>(
      context,
      listen: false,
    );

    // If showing exchange rates is enabled, convert to base currency
    if (settings.showExchangeRates) {
      // Use synchronous fallback: format with original currency if conversion unavailable
      // Prefer using the service's formatAmountInBaseCurrency for async conversion when needed elsewhere
      final currency = SupportedCurrencies.getCurrency(currencyCode);
      if (currency != null) return currency.formatAmount(amount);
      final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
      return '${formatter.format(amount).trim()} $currencyCode';
    } else {
      final currency = SupportedCurrencies.getCurrency(currencyCode);
      if (currency != null) {
        return currency.formatAmount(amount);
      }
      final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
      return '${formatter.format(amount).trim()} $currencyCode';
    }
  }
}
