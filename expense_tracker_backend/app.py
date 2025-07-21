import os
import re
import joblib
from flask import Flask, request, jsonify
from google.cloud import vision

# --- 1. INITIAL SETUP ---
app = Flask(__name__)

# --- 2. LOAD MODELS & CLIENTS ON STARTUP ---

# Load your custom category classification model
try:
    category_classifier = joblib.load('category_classifier.pkl')
    print("✅ Category classification model loaded successfully .!")
except FileNotFoundError:
    print("❌ ERROR: 'category_classifier.pkl' not found. Please run train_model.py first.")
    exit()

# Set up Google Cloud Vision client
# This requires the 'gcp-vision-credentials.json' file in the same directory.
try:
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "gcp-vision-credentials.json"
    vision_client = vision.ImageAnnotatorClient()
    print("✅ Google Cloud Vision client initialized successfully.")
except Exception as e:
    print(f"❌ ERROR: Could not initialize Google Vision client: {e}")
    print("   Please ensure 'gcp-vision-credentials.json' is present, valid, and that you have enabled the Vision API and billing.")
    exit()


# --- 3. HELPER FUNCTIONS ---

def extract_amount(text):
    """Uses regex to find the first number (integer or float) in a given text string."""
    # This regex looks for digits, optionally followed by a dot and more digits.
    numbers = re.findall(r'\d+\.?\d*', text)
    if numbers:
        return float(numbers[0])
    return None

def extract_item(text, amount):
    """A simple heuristic to guess the item name by cleaning up the input text."""
    # Convert amount to string to remove it from the text
    if amount:
        amount_str = str(int(amount) if amount.is_integer() else amount)
        text = text.lower().replace(amount_str, '')

    # Remove common stop words and currency units
    stop_words = [
        'bought', 'paid', 'for', 'a', 'an', 'the', 'rs', 'rupees', 'was', 'of',
        'my', 'recharged', 'new', 'got', 'purchase', 'cost'
    ]
    querywords = text.split()
    
    # Rebuild the string without the stop words
    resultwords  = [word for word in querywords if word.lower() not in stop_words]
    item = ' '.join(resultwords).strip().title() # Capitalize first letters of each word
    
    return item if item else "Unknown Item"

def parse_receipt_text(text):
    """
    Analyzes a large block of OCR text from a receipt to find the total,
    a likely category, and a vendor name.
    """
    lines = text.lower().split('\n')
    amount = None
    category = 'Shopping'  # A safe default
    item = "Scanned Receipt" # A safe default

    # 1. Find the total amount (most important part)
    total_keywords = ['total', 'amount due', 'to pay', 'grand total', 'balance', 'net amount']
    for line in reversed(lines):
        for keyword in total_keywords:
            if keyword in line:
                found_amount = extract_amount(line)
                if found_amount:
                    amount = found_amount
                    break 
        if amount is not None:
            break

    # Fallback: If no keyword found, guess the largest number on the receipt is the total.
    if amount is None:
        all_numbers = re.findall(r'\d+\.?\d*', text)
        if all_numbers:
            amount = max([float(n) for n in all_numbers])

    # 2. Guess the category based on keywords found anywhere in the receipt text.
    category_map = {
        'Food': ['grocery', 'market', 'foods', 'restaurant', 'cafe', 'kitchen', 'sweets', 'bakery'],
        'Health': ['pharmacy', 'medical', 'clinic', 'hospital', 'health', 'diagnostics'],
        'Utilities': ['telecom', 'internet', 'bill', 'invoice', 'electricity', 'water'],
        'Shopping': ['fashion', 'store', 'mall', 'boutique', 'electronics', 'apparel', 'lifestyle']
    }
    for cat, keywords in category_map.items():
        for keyword in keywords:
            if keyword in text.lower():
                category = cat
                break
        if category != 'Shopping':
            break
            
    # 3. Guess the item/vendor name (often one of the first few non-empty lines).
    for line in lines:
        if line.strip() and len(line.strip()) > 2:
            item = line.strip().title()
            break

    return {'item': item, 'amount': amount, 'category': category}


# --- 4. API ENDPOINTS ---

@app.route('/process', methods=['POST'])
def process_text():
    """Endpoint for simple text-based expenses."""
    print("\n--- Request received at /process endpoint! ---")
    data = request.get_json()
    if not data or 'text' not in data:
        return jsonify({'error': 'Invalid input. Please provide a "text" field.'}), 400

    input_text = data['text']
    
    predicted_category = category_classifier.predict([input_text])[0]
    amount = extract_amount(input_text)
    if amount is None:
        return jsonify({'error': 'Could not determine the amount from the text.'}), 400
        
    item = extract_item(input_text, amount)

    response = {
        'item': item,
        'amount': amount,
        'category': predicted_category
    }
    print(f"✅ Processed text successfully: {response}")
    return jsonify(response)


@app.route('/process-image-receipt', methods=['POST'])
def process_image_receipt():
    """Endpoint for processing uploaded receipt images."""
    print("\n--- Request received at /process-image-receipt endpoint! ---")
    if 'receipt' not in request.files:
        return jsonify({'error': 'No image file found in request (expected key "receipt").'}), 400
    
    file = request.files['receipt']
    
    if file.filename == '':
        return jsonify({'error': 'No image file selected.'}), 400

    try:
        print("Received image, sending to Google Cloud Vision for OCR...")
        image_content = file.read()
        image = vision.Image(content=image_content)
        
        response = vision_client.text_detection(image=image)
        
        if response.error.message:
            # This will catch the BILLING_DISABLED error
            raise Exception(response.error.message)

        if response.text_annotations:
            full_ocr_text = response.text_annotations[0].description
            print("✅ Google Vision OCR successful. Analyzing extracted text...")
            
            processed_data = parse_receipt_text(full_ocr_text)
            
            if processed_data.get('amount') is None:
                return jsonify({'error': 'Could not determine total from receipt text.'}), 400
            
            print(f"✅ Processed image successfully: {processed_data}")
            return jsonify(processed_data)
        else:
            return jsonify({'error': 'No text detected in the image by Google Vision.'}), 400

    except Exception as e:
        print(f"❌ An error occurred during image processing: {e}")
        return jsonify({'error': 'An internal error occurred while processing the image.'}), 500


# --- 5. RUN THE APP ---
if __name__ == '__main__':
    # Listens on all network interfaces, making it accessible from the emulator/device
    app.run(host='0.0.0.0', port=5000, debug=True)