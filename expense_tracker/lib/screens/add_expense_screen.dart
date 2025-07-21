import 'package:flutter/material.dart';
import 'package:expense_tracker/screens/edit_expense_dialog.dart';
import 'package:expense_tracker/services/ai_service.dart';
import 'package:expense_tracker/services/firestore_service.dart';

class AddExpenseScreen extends StatefulWidget {
  // Can be launched with EITHER initial text (for analysis)
  final String? initialText;
  // OR with final data that is already processed (from image scan)
  final Map<String, dynamic>? initialData;

  // Updated constructor to accept both optional parameters.
  const AddExpenseScreen({super.key, this.initialText, this.initialData});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _textController = TextEditingController();
  final _aiService = AiService();
  final _firestoreService = FirestoreService();

  // State management variables
  bool _isProcessing = false;
  Map<String, dynamic>? _processedData;
  String? _error;

  @override
  void initState() {
    super.initState();

    // --- NEW, SMARTER INITIALIZATION LOGIC ---
    if (widget.initialData != null) {
      // Priority 1: If we received final, structured data (from an image scan),
      // just display it directly for confirmation.
      setState(() {
        _processedData = widget.initialData;
      });
    } else if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      // Priority 2: If we received raw text (from voice or manual entry),
      // populate the text field and trigger the analysis automatically.
      _textController.text = widget.initialText!;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _processAndAnalyzeExpense();
        }
      });
    }
    // If neither is provided, the screen starts empty for manual text entry.
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Called when the user presses the "Analyze Expense" button.
  Future<void> _processAndAnalyzeExpense() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processedData = null;
      _error = null;
    });

    // NOTE: For simplicity, we are keeping the text-length-based analysis.
    // This screen doesn't need to know *how* it got the text, just what to do with it.
    final inputText = _textController.text;
    Map<String, dynamic>? result;

    if (inputText.length > 80) {
      print("Analyzing as a receipt (long text)...");
      result = await _aiService.analyzeReceiptImage(inputText);
    } else {
      print("Analyzing as a single sentence (short text)...");
      result = await _aiService.processExpenseText(inputText);
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      if (result != null) {
        _processedData = result;
      } else {
        _error = 'Could not process the expense. Please try again or check the server.';
      }
    });
  }

  /// Shows the dialog for editing the processed data.
  Future<void> _showEditDialog() async {
    if (_processedData == null) return;

    final updatedData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditExpenseDialog(initialData: _processedData!),
    );

    if (updatedData != null) {
      setState(() {
        _processedData = updatedData;
      });
    }
  }

  /// Called when the user confirms and saves the processed data.
  Future<void> _saveConfirmedExpense() async {
    if (_processedData == null) return;
    
    setState(() => _isProcessing = true);

    await _firestoreService.addExpense(
      _processedData!['item'],
      _processedData!['amount'],
      _processedData!['category'],
    );
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show the text input field if there isn't already processed data from an image scan.
    final bool showTextInput = widget.initialData == null;

    return Scaffold(
      appBar: AppBar(title: Text(showTextInput ? 'Add Expense with AI' : 'Confirm Scanned Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // Conditionally show the text input part
            if (showTextInput) ...[
              const Text(
                'Describe your expense or paste receipt text:',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLines: null,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'e.g., "Bought a school bag for 500"',
                ),
                onSubmitted: (_) => _processAndAnalyzeExpense(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isProcessing ? null : _processAndAnalyzeExpense,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isProcessing && _processedData == null
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                    : const Text('Analyze Expense', style: TextStyle(fontSize: 16)),
              ),
            ],
            
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
            ],
            
            if (_processedData != null) ...[
              // If we are showing text input, add a divider for separation.
              if (showTextInput) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
              ],
              Text('Please Confirm Analysis', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _buildResultRow('Item', _processedData!['item'].toString()),
              _buildResultRow('Amount', '₹${_processedData!['amount']}'),
              _buildResultRow('Category', _processedData!['category'].toString()),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: _showEditDialog,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm & Save'),
                      onPressed: _isProcessing ? null : _saveConfirmedExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        padding: const EdgeInsets.symmetric(vertical: 14)
                      ),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  /// Helper widget to build a formatted result row.
  Widget _buildResultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title:', style: const TextStyle(fontSize: 18, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}