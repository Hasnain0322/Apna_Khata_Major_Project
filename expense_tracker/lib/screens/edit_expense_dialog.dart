import 'package:flutter/material.dart';

class EditExpenseDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditExpenseDialog({super.key, required this.initialData});

  @override
  State<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  late TextEditingController _itemController;
  late TextEditingController _amountController;
  late String _selectedCategory;

  final _formKey = GlobalKey<FormState>();
  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Utilities', 'Health', 
    'Entertainment', 'Education', 'Personal Care', 'Gifts & Donations', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the data passed from the parent screen
    _itemController = TextEditingController(text: widget.initialData['item']);
    _amountController = TextEditingController(text: widget.initialData['amount'].toString());
    _selectedCategory = widget.initialData['category'];
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      // Create a map of the updated data
      final updatedData = {
        'item': _itemController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'category': _selectedCategory,
      };
      // Pop the dialog and return the updated data
      Navigator.of(context).pop(updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Expense'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(labelText: 'Item'),
                validator: (value) => value!.isEmpty ? 'Please enter an item' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCategory = newValue);
                  }
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Pop without returning data
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}