import os
import re
import joblib
from flask import Flask, request, jsonify
from google.cloud import vision
from google.oauth2 import service_account

# --- 1. INITIAL SETUP ---
app = Flask(__name__)

# --- 2. LOAD MODELS & CLIENTS ON STARTUP ---
try:
    category_classifier = joblib.load('category_classifier.pkl')
    print("✅ Category classification model loaded.")
except FileNotFoundError:
    print("❌ ERROR: 'category_classifier.pkl' not found. Please run train_model.py first.")
    exit()

try:
    credentials = service_account.Credentials.from_service_account_file("gcp-vision-credentials.json")
    vision_client = vision.ImageAnnotatorClient(credentials=credentials)
    print("✅ Google Cloud Vision client initialized.")
except Exception as e:
    print(f"❌ ERROR: Could not initialize Google Vision client: {e}"); exit()


# --- 3. HELPER FUNCTIONS ---
def find_category_by_keyword(text):
    text_lower = text.lower()
    keyword_map = {
        'Food': ['pizza', 'groceries', 'restaurant', 'lunch', 'dinner', 'coffee', 'snacks', 'zomato', 'swiggy', 'biryani', 'burger', 'cafe', 'bakery', 'sweets'],
        'Shopping': ['mobile phone', 'shirt', 'jeans', 'shoes', 'book', 'laptop', 'teddy bear', 'amazon', 'flipkart', 'myntra', 'nykaa', 'toy', 'outfit', 'dress', 'apparel', 'electronics'],
        'Entertainment': ['movie', 'netflix', 'spotify', 'concert', 'bookmyshow', 'hotstar', 'prime video'],
        'Transport': ['uber', 'taxi', 'bus fare', 'flight', 'fuel', 'metro', 'ola', 'rapido', 'petrol', 'diesel'],
        'Health': ['medicine', 'doctor', 'pharmacy', 'apollo', 'pharmeasy', 'netmeds', 'hospital', 'clinic', 'diagnostics'],
        'Utilities': ['electricity bill', 'internet bill', 'phone recharge', 'rent', 'broadband', 'airtel', 'jio', 'vi', 'vodafone', 'water bill', 'invoice']
    }
    for category, keywords in keyword_map.items():
        if any(keyword in text_lower for keyword in keywords): return category
    return None

def extract_amount(text):
    numbers = re.findall(r'[\d,]+\.\d{2}|[\d,]+', text)
    if numbers: return float(numbers[0].replace(',', ''))
    return None

def extract_item(text, amount):
    if amount:
        amount_str = str(int(amount) if amount % 1 == 0 else amount)
        text = text.lower().replace(amount_str, '')
    stop_words = ['bought', 'paid', 'for', 'a', 'an', 'the', 'rs', 'rupees', 'was', 'of', 'my', 'recharged', 'new', 'got', 'purchase', 'cost', 'from', 'on']
    querywords = text.split(); resultwords = [word for word in querywords if word.lower() not in stop_words]
    item = ' '.join(resultwords).strip().title(); return item if item else "Unknown Item"

def parse_receipt_text(text):
    lines = text.lower().split('\n'); amount, category, item = None, None, "Scanned Receipt"
    high_priority_keywords = ['grand total', 'total due', 'amount paid', 'balance']; low_priority_keywords = ['total', 'subtotal', 'amount']
    found_amounts = []
    for line in reversed(lines):
        if any(keyword in line for keyword in high_priority_keywords):
            found_amount = extract_amount(line)
            if found_amount: amount = found_amount; break
    if amount is None:
        for line in reversed(lines):
            if any(keyword in line for keyword in low_priority_keywords):
                found_amount = extract_amount(line)
                if found_amount: found_amounts.append(found_amount)
        if found_amounts: amount = min(found_amounts)
    if amount is None:
        all_numbers_str = re.findall(r'[\d,]+\.?\d*', text)
        if all_numbers_str:
            valid_numbers = [float(n.replace(',', '')) for n in all_numbers_str if n]
            if valid_numbers: amount = max(valid_numbers)
    category = find_category_by_keyword(text)
    for line in lines:
        clean_line = line.strip()
        if len(clean_line) > 2 and not clean_line.replace('.', '', 1).isdigit(): item = clean_line.title(); break
    if category is None:
        if item != "Scanned Receipt": prediction = category_classifier.predict([item]); category = str(prediction[0])
        else: category = 'Other'
    return {'item': item, 'amount': amount, 'category': category}


# --- 4. API ENDPOINTS ---

@app.route('/process', methods=['POST'])
def process_text():
    print("\n--- Request received at /process endpoint! ---")
    try:
        data = request.get_json()
        if not data or 'text' not in data: return jsonify({'error': 'Invalid input: Missing "text" field.'}), 400
        input_text = data['text']
        
        amount = extract_amount(input_text)
        if amount is None: return jsonify({'error': 'Could not determine the amount from the text.'}), 400

        predicted_category = find_category_by_keyword(input_text)
        if predicted_category is None:
            print("No keyword found, using ML model for prediction...")
            # THE CRITICAL FIX IS HERE: Convert the NumPy type to a standard Python string
            prediction_result = category_classifier.predict([input_text])
            predicted_category = str(prediction_result[0])
        else:
            print(f"Found high-confidence keyword, category set to: {predicted_category}")

        item = extract_item(input_text, amount)
        response = {'item': item, 'amount': amount, 'category': predicted_category}
        print(f"✅ Processed text successfully: {response}")
        return jsonify(response)
    except Exception as e:
        print(f"❌ An error occurred in /process: {e}")
        return jsonify({'error': 'An internal server error occurred.'}), 500

@app.route('/process-image-receipt', methods=['POST'])
def process_image_receipt():
    print("\n--- Request received at /process-image-receipt endpoint! ---")
    if 'receipt' not in request.files: return jsonify({'error': 'No image file found.'}), 400
    file = request.files['receipt']
    try:
        image_content = file.read()
        image = vision.Image(content=image_content)
        response = vision_client.text_detection(image=image)
        if response.error.message: raise Exception(response.error.message)
        if response.text_annotations:
            full_ocr_text = response.text_annotations[0].description
            print("✅ Google Vision OCR successful. Analyzing with smart parser...")
            processed_data = parse_receipt_text(full_ocr_text)
            if processed_data.get('amount') is None: return jsonify({'error': 'Could not determine total from receipt text.'}), 400
            print(f"✅ Processed image successfully: {processed_data}")
            return jsonify(processed_data)
        else:
            return jsonify({'error': 'No text detected in the image.'}), 400
    except Exception as e:
        print(f"❌ An error occurred during image processing: {e}")
        return jsonify({'error': 'An internal error occurred.'}), 500

# --- 5. RUN THE APP ---
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)


    