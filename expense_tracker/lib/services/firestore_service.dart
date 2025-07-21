import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/expense_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new expense for the currently logged-in user
  Future<void> addExpense(String item, double amount, String category) async {
    final user = _auth.currentUser;
    if (user == null) return; // Not logged in

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .add({
      'item': item,
      'amount': amount,
      'category': category,
      'timestamp': Timestamp.now(), // Use server timestamp
    });
  }

  // Get a stream of expenses for the currently logged-in user
  Stream<List<Expense>> getExpensesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]); // Return an empty stream if not logged in
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .orderBy('timestamp', descending: true) // Show newest first
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromFirestore(doc))
            .toList());
  }
}