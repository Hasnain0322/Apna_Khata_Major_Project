import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/services/firestore_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        // Automatically implies a leading back button on some platforms, which is fine
        automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _firestoreService.getExpensesStream(),
        builder: (context, snapshot) {
          // ==================== DEBUGGING CODE START ====================
          // These print statements will show up in your VS Code/Android Studio "Debug Console"
          print('StreamBuilder connection state: ${snapshot.connectionState}');
          if (snapshot.hasError) {
            print('!!! StreamBuilder Error: ${snapshot.error}');
          }
          if (snapshot.hasData) {
            print('StreamBuilder has data. Number of expenses: ${snapshot.data!.length}');
          }
          // ===================== DEBUGGING CODE END =====================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // IMPORTANT: Check for an error *after* waiting.
          if (snapshot.hasError) {
            // Displaying the error in the UI is very helpful for debugging
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'An error occurred.\n\nCheck your Debug Console for details.\n\nCommon causes:\n1. Firestore Security Rules are incorrect.\n2. The query requires a Firestore Index.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[300]),
                ),
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No expenses found.\nAdd one from the Home screen!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final expenses = snapshot.data!;
          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF2A2A2A),
                child: ListTile(
                  title: Text(
                    expense.item,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${expense.category} • ${DateFormat.yMMMd().format(expense.timestamp.toDate())}',
                  ),
                  trailing: Text(
                    // Assuming a currency like Rupees, adjust as needed
                    '₹${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.tealAccent,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}