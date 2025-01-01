import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallet App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const WalletApp(),
    );
  }
}

class WalletApp extends StatefulWidget {
  const WalletApp({super.key});

  @override
  State<WalletApp> createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> {
  List<Transaction> _transactions = [];
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  dynamic
      _selectedCategory; // Use dynamic to hold either Income or Expense category
  TransactionType? _selectedTransactionType;

  // Lists to store custom categories with icons
  List<CustomCategory> _customIncomeCategories = [];
  List<CustomCategory> _customExpenseCategories = [];

  double get _balance {
    double total = 0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  double get _totalIncome {
    double total = 0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      }
    }
    return total;
  }

  double get _totalExpenses {
    double total = 0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.expense) {
        total += tx.amount;
      }
    }
    return total;
  }

  void _addTransaction(TransactionType type) {
    setState(() {
      _selectedTransactionType = type;
      _selectedCategory =
          null; // Reset selected category when opening the dialog
    });
    String titleText =
        type == TransactionType.income ? 'Add Income' : 'Add Expense';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titleText),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              if (type == TransactionType.income)
                _buildCategoryDropdown<dynamic>(
                  // Use dynamic here
                  label: 'Category',
                  value: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  defaultCategories: IncomeCategory.values.toList(),
                  customCategories: _customIncomeCategories,
                ),
              if (type == TransactionType.expense)
                _buildCategoryDropdown<dynamic>(
                  // Use dynamic here
                  label: 'Category',
                  value: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  defaultCategories: ExpenseCategory.values.toList(),
                  customCategories: _customExpenseCategories,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetInputFields();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final description = _descriptionController.text;
              final amount = double.tryParse(_amountController.text);

              if (description.isNotEmpty &&
                  amount != null &&
                  amount > 0 &&
                  _selectedCategory != null) {
                setState(() {
                  _transactions = [
                    ..._transactions,
                    Transaction(
                      description: description,
                      amount: amount,
                      type: type,
                      dateTime: DateTime.now(),
                      category: _selectedCategory,
                    ),
                  ];
                });
                Navigator.of(ctx).pop();
                _resetInputFields();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please enter valid details and select category.'),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown<T>({
    required String label,
    required T? value,
    required ValueChanged<T?>? onChanged,
    required List<T> defaultCategories,
    required List<CustomCategory> customCategories,
  }) {
    List<DropdownMenuItem<T>> items = [];

    for (var category in defaultCategories) {
      items.add(DropdownMenuItem<T>(
        value: category,
        child: Row(
          children: [
            Icon((category as dynamic).icon),
            const SizedBox(width: 8),
            Text((category as dynamic).label),
          ],
        ),
      ));
    }

    for (var customCategory in customCategories) {
      items.add(DropdownMenuItem<T>(
        value: customCategory as T,
        child: Row(
          children: [
            Icon(customCategory.icon),
            const SizedBox(width: 8),
            Text(customCategory.name),
          ],
        ),
      ));
    }

    return DropdownButtonFormField<T>(
      decoration: const InputDecoration(border: OutlineInputBorder()),
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }

  void _resetInputFields() {
    _descriptionController.clear();
    _amountController.clear();
    _selectedCategory = null;
    _selectedTransactionType = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Manage Categories',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CategoryManagementScreen(
                    customIncomeCategories: _customIncomeCategories,
                    customExpenseCategories: _customExpenseCategories,
                    onIncomeCategoryUpdated: (newList) {
                      setState(() {
                        _customIncomeCategories = newList;
                      });
                    },
                    onExpenseCategoryUpdated: (newList) {
                      setState(() {
                        _customExpenseCategories = newList;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard(
                  context: context,
                  title: 'Total Income',
                  value: _totalIncome,
                  color: Colors.green,
                ),
                _buildSummaryCard(
                  context: context,
                  title: 'Total Expenses',
                  value: _totalExpenses,
                  color: Colors.red,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Balance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      NumberFormat.currency(locale: 'en_US', symbol: '\$')
                          .format(_balance),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: _balance >= 0 ? Colors.green : Colors.red,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FilledButton.tonal(
                  onPressed: () => _addTransaction(TransactionType.income),
                  child: const Text('Add Income'),
                ),
                FilledButton.tonal(
                  onPressed: () => _addTransaction(TransactionType.expense),
                  child: const Text('Add Expense'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text('No transactions yet.'))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      IconData iconData;
                      Color iconColor;
                      IconData? categoryIcon;
                      String categoryLabel = '';

                      if (transaction.type == TransactionType.income) {
                        iconData = Icons.arrow_downward;
                        iconColor = Colors.green;
                        if (transaction.category is IncomeCategory) {
                          categoryIcon = transaction.category.icon;
                          categoryLabel = transaction.category.label;
                        } else if (transaction.category is CustomCategory) {
                          categoryIcon = transaction.category.icon;
                          categoryLabel = transaction.category.name;
                        }
                      } else {
                        iconData = Icons.arrow_upward;
                        iconColor = Colors.red;
                        if (transaction.category is ExpenseCategory) {
                          categoryIcon = transaction.category.icon;
                          categoryLabel = transaction.category.label;
                        } else if (transaction.category is CustomCategory) {
                          categoryIcon = transaction.category.icon;
                          categoryLabel = transaction.category.name;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: ListTile(
                          leading: Icon(
                            iconData,
                            color: iconColor,
                          ),
                          title: Text(transaction.description),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  DateFormat('MMM d, yyyy')
                                      .format(transaction.dateTime),
                                  style: Theme.of(context).textTheme.bodySmall),
                              Row(
                                children: [
                                  if (categoryIcon != null)
                                    Icon(categoryIcon, size: 16),
                                  if (categoryIcon != null)
                                    const SizedBox(width: 4),
                                  Text('Category: $categoryLabel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${transaction.type == TransactionType.income ? '+' : '-'}${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(transaction.amount)}',
                            style: TextStyle(
                              color: iconColor,
                              fontWeight: FontWeight.bold,
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

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required double value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              NumberFormat.currency(locale: 'en_US', symbol: '\$')
                  .format(value),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryManagementScreen extends StatefulWidget {
  final List<CustomCategory> customIncomeCategories;
  final List<CustomCategory> customExpenseCategories;
  final Function(List<CustomCategory>) onIncomeCategoryUpdated;
  final Function(List<CustomCategory>) onExpenseCategoryUpdated;

  const CategoryManagementScreen({
    super.key,
    required this.customIncomeCategories,
    required this.customExpenseCategories,
    required this.onIncomeCategoryUpdated,
    required this.onExpenseCategoryUpdated,
  });

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _newCategoryController = TextEditingController();
  IconData? _selectedCustomCategoryIcon;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(TransactionType type) {
    setState(() {
      _selectedCustomCategoryIcon = Icons.category; // Default icon
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            'Add New ${type == TransactionType.income ? 'Income' : 'Expense'} Category'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _newCategoryController,
                    decoration:
                        const InputDecoration(labelText: 'Category Name'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final IconData? result = await showDialog<IconData>(
                        context: context,
                        builder: (BuildContext context) =>
                            const SimpleIconPickerDialog(),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedCustomCategoryIcon = result;
                        });
                      }
                    },
                    icon: Icon(_selectedCustomCategoryIcon ?? Icons.category),
                    label: const Text('Select Icon'),
                  ),
                  if (_selectedCustomCategoryIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Icon(_selectedCustomCategoryIcon, size: 48),
                    ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newCategoryName = _newCategoryController.text.trim();
              if (newCategoryName.isNotEmpty &&
                  _selectedCustomCategoryIcon != null) {
                final newCustomCategory = CustomCategory(
                  name: newCategoryName,
                  icon: _selectedCustomCategoryIcon!,
                );
                if (type == TransactionType.income) {
                  widget.onIncomeCategoryUpdated(
                      [...widget.customIncomeCategories, newCustomCategory]);
                } else {
                  widget.onExpenseCategoryUpdated(
                      [...widget.customExpenseCategories, newCustomCategory]);
                }
                Navigator.of(ctx).pop();
                _newCategoryController.clear();
                // No need to reset _selectedCustomCategoryIcon here, as the dialog is dismissed
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(
            context: context,
            categoryType: TransactionType.income,
            customCategories: widget.customIncomeCategories,
            onAddCategory: () => _showAddCategoryDialog(TransactionType.income),
          ),
          _buildCategoryList(
            context: context,
            categoryType: TransactionType.expense,
            customCategories: widget.customExpenseCategories,
            onAddCategory: () =>
                _showAddCategoryDialog(TransactionType.expense),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList({
    required BuildContext context,
    required TransactionType categoryType,
    required List<CustomCategory> customCategories,
    required VoidCallback onAddCategory,
  }) {
    return ListView.builder(
      itemCount: (categoryType == TransactionType.income
              ? IncomeCategory.values.length
              : ExpenseCategory.values.length) +
          customCategories.length +
          1, // +1 for the Add Category button
      itemBuilder: (context, index) {
        if (index <
            (categoryType == TransactionType.income
                ? IncomeCategory.values.length
                : ExpenseCategory.values.length)) {
          final dynamic category = categoryType == TransactionType.income
              ? IncomeCategory.values[index]
              : ExpenseCategory.values[index];
          return ListTile(
            leading: Icon(category.icon),
            title: Text(category.label),
          );
        } else if (index <
            (categoryType == TransactionType.income
                    ? IncomeCategory.values.length
                    : ExpenseCategory.values.length) +
                customCategories.length) {
          final customCategoryIndex = index -
              (categoryType == TransactionType.income
                  ? IncomeCategory.values.length
                  : ExpenseCategory.values.length);
          final customCategory = customCategories[customCategoryIndex];
          return ListTile(
            leading: Icon(customCategory.icon),
            title: Text(customCategory.name),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.tonal(
              onPressed: onAddCategory,
              child: const Text('Add New Category'),
            ),
          );
        }
      },
    );
  }
}

enum TransactionType { income, expense }

enum IncomeCategory {
  salary(Icons.attach_money, 'Salary'),
  investment(Icons.trending_up, 'Investment'),
  gift(Icons.card_giftcard, 'Gift'),
  other(Icons.category, 'Other');

  final IconData icon;
  final String label;
  const IncomeCategory(this.icon, this.label);
}

enum ExpenseCategory {
  food(Icons.restaurant, 'Food'),
  transport(Icons.directions_bus, 'Transport'),
  shopping(Icons.shopping_cart, 'Shopping'),
  utilities(Icons.power, 'Utilities'),
  entertainment(Icons.movie, 'Entertainment'),
  other(Icons.category, 'Other');

  final IconData icon;
  final String label;
  const ExpenseCategory(this.icon, this.label);
}

class CustomCategory {
  final String name;
  final IconData icon;

  CustomCategory({required this.name, required this.icon});
}

class Transaction {
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime dateTime;
  final dynamic category;

  Transaction({
    required this.description,
    required this.amount,
    required this.type,
    required this.dateTime,
    required this.category,
  });
}

class SimpleIconPickerDialog extends StatelessWidget {
  const SimpleIconPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final List<IconData> popularIcons = [
      Icons.attach_money,
      Icons.trending_up,
      Icons.card_giftcard,
      Icons.category,
      Icons.restaurant,
      Icons.directions_bus,
      Icons.shopping_cart,
      Icons.power,
      Icons.movie,
      Icons.home,
      Icons.flight,
      Icons.local_hospital,
      Icons.school,
    ];

    return AlertDialog(
      title: const Text('Select an Icon'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: popularIcons.length,
          itemBuilder: (context, index) => IconButton(
            icon: Icon(popularIcons[index]),
            onPressed: () => Navigator.pop(context, popularIcons[index]),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
