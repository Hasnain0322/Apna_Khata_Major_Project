import 'dart:convert';
import 'package:http/http.dart' as http;
// This new import is required for creating a multipart request to upload a file.
import 'package:http_parser/http_parser.dart';

class AiService {
  // IMPORTANT: This is the hardcoded IP address of your computer on your local Wi-Fi network.
  // You must update this value every time your computer's IP address changes.
  final String _baseUrl = 'http://192.168.0.103:5000'; // <-- UPDATE THIS AS NEEDED

  /// Sends a short, single sentence to the Python backend for ML-based processing.
  /// Used for quick text entry and voice commands.
  Future<Map<String, dynamic>?> processExpenseText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/process'), // Calls the ML model endpoint
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'text': text}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to process text. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error connecting to the AI service for text processing: $e');
      return null;
    }
  }


  // --- NEW METHOD TO UPLOAD AN IMAGE FOR BACKEND OCR ---
  /// Uploads a receipt image to the backend for processing with Google Cloud Vision.
  ///
  /// [imagePath] is the local file path of the image taken by the user.
  /// Returns the final structured JSON with 'item', 'amount', and 'category'.
  Future<Map<String, dynamic>?> analyzeReceiptImage(String imagePath) async {
    try {
      // 1. Create a multipart request. This type of request is needed for file uploads.
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/process-image-receipt') // <-- Calls the NEW image endpoint
      );

      // 2. Attach the image file to the request.
      request.files.add(
        await http.MultipartFile.fromPath(
          'receipt', // This 'field' name must match what the Flask server expects: `request.files['receipt']`
          imagePath,
          // Provide the content type of the file.
          contentType: MediaType('image', 'jpeg'), // Assuming JPEG, can also be 'png'
        )
      );

      print("Uploading receipt image to backend...");
      // 3. Send the request and wait for the response.
      // Use a longer timeout as uploads and cloud processing can take time.
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      
      // 4. Convert the streamed response back into a regular HTTP response.
      var response = await http.Response.fromStream(streamedResponse);

      print("Backend responded with status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Success! The backend did all the work and returned the final data.
        return json.decode(response.body);
      } else {
        // The backend returned an error.
        print("Failed to analyze receipt image: ${response.body}");
        return null;
      }
    } catch (e) {
      // This catches network errors during the upload.
      print("Error uploading/analyzing receipt image: $e");
      return null;
    }
  }
}