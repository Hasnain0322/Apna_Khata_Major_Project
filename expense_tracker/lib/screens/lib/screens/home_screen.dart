import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // We still need this to get the image
import 'package:expense_tracker/services/ai_service.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final AiService _aiService = AiService(); // Add an instance of our AI service

  // --- THIS IS THE NEW, CORRECT _scanReceipt FUNCTION ---
  /// This function handles picking an image and uploading it to our backend for full processing.
  Future<void> _scanReceipt() async {
    final ImagePicker picker = ImagePicker();
    // 1. Ask user to pick an image from the camera.
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return; // User cancelled the operation.
    if (!mounted) return;

    // 2. Show a user-friendly message that work is being done.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading and analyzing receipt...')),
    );

    try {
      // 3. Call the service method that uploads the image file path to the backend.
      final result = await _aiService.analyzeReceiptImage(image.path);

      if (!mounted) return;
      // Hide the "uploading" message before showing the result.
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result != null) {
        // 4. We received final, structured data from the backend!
        // Navigate to the next screen, passing this data directly.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddExpenseScreen(initialData: result),
          ),
        );
      } else {
        // The backend returned an error or null.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not analyze receipt. Please try again.')),
        );
      }
    } catch (e) {
      print("An error occurred in the scan receipt flow: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    }
  }


  // --- Helper method to show the logout confirmation dialog (no changes) ---
  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _auth.signOut();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.close),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // --- The "Scan Receipt" button now calls the correct function ---
                  _buildActionButton(context,
                      icon: Icons.receipt,
                      label: 'Scan Receipt',
                      onPressed: _scanReceipt,
                  ),
                  _buildActionButton(context,
                      icon: Icons.picture_as_pdf,
                      label: 'Parse PDF',
                      onPressed: () { /* TODO: Implement PDF Parsing */ }),
                  _buildActionButton(context,
                      icon: Icons.mic,
                      label: 'Voice to Text',
                      onPressed: () { /* TODO: Implement Voice to Text */ }),
                  _buildActionButton(context,
                      icon: Icons.edit_note,
                      label: 'Text Entry',
                      onPressed: () { 
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                        );
                      }),
                ],
              ),
              const SizedBox(height: 24),

              // Reports Section
              _buildSectionHeader('Reports'),
              const SizedBox(height: 16),
              _buildActionButton(context,
                  icon: Icons.calendar_today,
                  label: 'Monthly Report',
                  onPressed: () { /* TODO: Implement */ },
                  isFullWidth: true),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                   _buildActionButton(context,
                      icon: Icons.calendar_view_week,
                      label: 'Yearly Report',
                      onPressed: () { /* TODO: Implement */ }),
                  _buildActionButton(context,
                      icon: Icons.edit_calendar,
                      label: 'Custom Report',
                      onPressed: () { /* TODO: Implement */ }),
                ],
              ),
               const SizedBox(height: 24),
              _buildSectionHeader('Personal'),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildActionButton(context,
                      icon: Icons.person_outline,
                      label: 'Profile',
                      onPressed: () { /* TODO: Implement */ }),
                  _buildActionButton(context,
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onPressed: () { /* TODO: Implement */ }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for section headers (no changes)
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  // Helper widget for the reusable action buttons (no changes)
  Widget _buildActionButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onPressed, bool isFullWidth = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: isFullWidth ? TextAlign.start : TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}