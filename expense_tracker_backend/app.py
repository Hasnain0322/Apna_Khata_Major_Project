import os
import re
import joblib
from flask import Flask, request, jsonify
from flask_cors import CORS
from google.cloud import vision
from sklearn.exceptions import InconsistentVersionWarning
import warnings

# --- 0. PRE-CONFIGURATION ---
warnings.filterwarnings("ignore", category=InconsistentVersionWarning)


# --- 1. INITIAL SETUP ---
app = Flask(__name__)

CORS(app)
# --- 2. LOAD MODELS & CLIENTS ON STARTUP ---

try:
    category_classifier = joblib.load('category_classifier.pkl')
    print("✅ Category classification model loaded successfully .!")
except FileNotFoundError:
    print("❌ ERROR: 'category_classifier.pkl' not found. Please run train_model.py first.")
    exit()

try:
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "gcp-vision-credentials.json"
    vision_client = vision.ImageAnnotatorClient()
    print("✅ Google Cloud Vision client initialized successfully.")
except Exception as e:
    print(f"❌ ERROR: Could not initialize Google Vision client: {e}")
    print("   Please ensure 'gcp-vision-credentials.json' is present, valid, and that you have enabled the Vision API and billing.")
    exit()


# --- 3. KEYWORD DICTIONARY & HELPER FUNCTIONS ---

CATEGORY_KEYWORDS = {
    'Food & Dining': ['biryani', 'pizza', 'burger', 'sandwich', 'pasta', 'noodles', 'momo', 'thali', 'biriyani', 'dosa', 'idli', 'pav bhaji', 'maggi', 'roll', 'shawarma', 'wrap', 'ice cream', 'cake', 'pastry', 'dessert', 'coffee', 'tea', 'juice', 'smoothie', 'milkshake', 'biryani house', 'barbecue', 'kebab', 'tikka', 'restaurant', 'cafe', 'canteen', 'dining', 'buffet', 'meal', 'zomato', 'swiggy', 'dominos', 'pizza hut', "domino's", "mcdonald's", 'mcdonald', 'kfc', 'subway', 'burger king', 'starbucks', 'barista', '99 pancakes', 'chicken tandoori', 'hocco','apple', 'bikanervala', 'haldiram', 'cafe coffee day', 'baskin robbins'],
    'Grocery': ['rice', 'wheat', 'dal', 'pulses', 'sugar', 'salt', 'milk', 'bread', 'butter', 'oil', 'tea powder', 'coffee powder', 'vegetables', 'fruits', 'tomato', 'potato', 'onion', 'cabbage', 'spinach', 'coriander', 'lemon', 'masala', 'atta', 'besan', 'poha', 'suji', 'jaggery', 'eggs', 'meat', 'fish', 'chicken', 'mutton', 'prawns', 'spices', 'detergent', 'soap', 'toothpaste', 'grocery', 'bigbasket', 'dmart', 'reliance fresh', 'more supermarket', "nature's basket", 'spencer’s', 'jiomart'],
    
    'Transport': ['taxi', 'cab', 'auto', 'bus', 'train', 'flight', 'airline', 'airfare', 'metro', 'tram', 'ferry', 'fuel', 'petrol', 'diesel', 'cng', 'parking', 'toll', 'ticket', 'pass', 'travel card', 'ola', 'uber', 'rapido', 'blablacar', 'redbus', 'irctc'],
    'Shopping & Lifestyle': ['shirt', 'jeans', 't-shirt', 'tshirt', 'trousers', 'kurta', 'saree', 'dress', 'shoes', 'sandals', 'chappal', 'watch', 'wallet', 'handbag', 'purse', 'belt', 'accessories', 'jacket', 'coat', 'sweater', 'hoodie', 'spectacles', 'sunglasses', 'electronics', 'phone', 'laptop', 'charger', 'earphones', 'headphones', 'camera', 'mall', 'boutique', 'apparel', 'amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'snapdeal', 'shopclues', 'tatacliq', 'h&m', 'zara', 'nike', 'adidas', 'puma', 'reebok', 'lifestyle'],
    'Healthcare & Medicine': ['doctor', 'hospital', 'clinic', 'pharmacy', 'chemist', 'medicine', 'injection', 'vaccine', 'blood test', 'sugar test', 'x-ray', 'scan', 'ct scan', 'mri', 'consultation', 'surgery', 'therapy', 'physiotherapy', 'dentist', 'dental', 'ayurvedic', 'homeopathy', 'optician', 'spectacles', 'hearing aid', 'apollo pharmacy', 'medplus', 'pharmeasy', '1mg', 'netmeds', 'practo'],
    'Personal Care & Grooming': ['salon','spa', 'haircut', 'hair wash', 'shaving', 'trimming', 'beard', 'hair color', 'facial', 'manicure', 'pedicure', 'beauty', 'makeup', 'wax', 'threading', 'perfume', 'deodorant','prostitute','lotion', 'shampoo', 'conditioner', 'body wash', 'soap', 'comb', 'mirror', 'towel', 'grooming kit', 'nykaa', 'purplle', 'wow skin', 'beardo', 'mcaffeine', 'urban company'],
    'Utilities & Bills': ['electricity bill', 'water bill', 'gas bill', 'broadband', 'wifi', 'internet', 'cable', 'dth', 'recharge', 'mobile bill', 'postpaid', 'prepaid', 'landline', 'rent', 'emi', 'loan', 'insurance', 'subscription', 'netflix', 'prime', 'hotstar', 'spotify', 'zee5', 'sony liv', 'voot', 'youtube premium'],
    'Others': ['charity', 'donation', 'gift', 'stationery', 'pen', 'pencil', 'notebook', 'printing', 'photocopy', 'laundry', 'tailoring', 'repair', 'maintenance', 'pet food', 'toy', 'game', 'miscellaneous']
}

def get_category_from_keywords(text):
    """Searches for keywords in the text to determine a category."""
    text_lower = text.lower()
    for category, keywords in CATEGORY_KEYWORDS.items():
        for keyword in keywords:
            if keyword in text_lower:
                return category
    return None

def extract_amount(text):
    """
    Intelligently extracts the amount from a text string.
    Priority Order:
    1. Looks for numbers following keywords like 'for', 'paid', 'of', 'cost', 'rs', 'inr'.
    2. If no keywords found, and there's only ONE number in the string, returns that number.
    3. If multiple numbers exist with no keywords, returns the LARGEST number as a best guess.
    4. Returns None if no numbers are found.
    """
    text_lower = text.lower()
    
    # Priority 1: Check for keywords followed by a number
    amount_keywords = ['for', 'paid', 'cost', 'of', 'rs', 'inr', 'amount', 'bill']
    for keyword in amount_keywords:
        # Regex: finds the keyword, then any characters except numbers, then captures the number.
        # This handles cases like "paid rs. 500" or "bill of 250"
        match = re.search(f'{keyword}[^0-9]*(\\d+\\.?\\d*)', text_lower)
        if match:
            return float(match.group(1))

    # Priority 2 & 3: No keywords found, analyze all numbers in the string
    numbers = re.findall(r'\d+\.?\d*', text_lower)
    if not numbers:
        return None # No numbers found
    
    float_numbers = [float(n) for n in numbers]

    if len(float_numbers) == 1:
        return float_numbers[0] # Only one number, it must be the amount
    else:
        # Multiple numbers without context, assume the largest is the amount
        # This solves "ordered from 99 pancakes for 200" -> chooses 200
        return max(float_numbers)

def extract_item(text, amount):
    """
    Cleans the text to create a plausible item name.
    It now removes ALL numbers from the text to avoid including them in the item name.
    """
    text_lower = text.lower()
    
    # Remove all numbers from the text to clean it up
    text_no_numbers = re.sub(r'\d+\.?\d*', '', text_lower).strip()

    stop_words = [
        'bought', 'paid', 'for', 'a', 'an', 'the', 'rs', 'inr', 'rupees', 'was', 'of',
        'my', 'recharged', 'new', 'got', 'purchase', 'cost', 'bill', 'amount'
    ]
    querywords = text_no_numbers.split()
    
    resultwords  = [word for word in querywords if word.lower() not in stop_words]
    item = ' '.join(resultwords).strip()
    
    # Remove extra spaces that might result from removing words
    item = re.sub(r'\s+', ' ', item).title()
    
    return item if item else "Unknown Item"

def parse_receipt_text(text):
    """Analyzes OCR text to find the total, a category, and a vendor name."""
    lines = text.lower().split('\n')
    item = "Scanned Receipt"

    # Use the new intelligent amount extraction on the full text
    amount = extract_amount(text)
            
    # Guess the category using the comprehensive keyword function.
    category = get_category_from_keywords(text) or 'Others'
            
    # Guess the item/vendor name (often one of the first few non-empty lines).
    for line in lines:
        if line.strip() and len(line.strip()) > 2:
            # A simple heuristic to avoid picking a line that is just a number
            if not re.fullmatch(r'[\d\s.,-]+', line.strip()):
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
    
    predicted_category = get_category_from_keywords(input_text)
    if not predicted_category:
        print("-> No keyword match found. Using ML model for classification...")
        predicted_category = category_classifier.predict([input_text])[0]
    else:
        print(f"-> Keyword match found! Category: {predicted_category}")
    
    # Use the new intelligent amount extraction function
    amount = extract_amount(input_text)
    if amount is None:
        return jsonify({'error': 'Could not determine the amount from the text.'}), 400
        
    # Use the improved item extraction function
    item = extract_item(input_text, amount)

    response = {
        'item': item,
        'amount': amount,
        'category': predicted_category
    }
    print(f"✅ Processed text successfully: {response}")
    return jsonify(response)


@app.route('/process-voice-expense', methods=['POST'])
def process_voice_expense():
    """
    This endpoint now ONLY performs Speech-to-Text (Transcription).
    It takes audio in and returns a simple text string out.
    """
    print("\n--- Request received at /process-voice-expense for STT ---")
    if not wit_client: return jsonify({'error': 'Wit.ai client is not configured.'}), 503
    if 'audio' not in request.files: return jsonify({'error': 'No audio file found.'}), 400

    audio_file = request.files['audio']
    try:
        print("Sending audio to Wit.ai for transcription...")
        wit_response = wit_client.speech(audio_file.stream, {'Content-Type': 'audio/wav'})
        
        transcribed_text = wit_response.get('text')
        if not transcribed_text:
            return jsonify({'error': 'Speech could not be transcribed.'}), 400

        # Return a simple JSON with just the text
        response = {'transcribed_text': transcribed_text}
        print(f"✅ Transcription successful: {response}")
        return jsonify(response)
        
    except Exception as e:
        print(f"❌ An error occurred during voice transcription: {e}")
        return jsonify({'error': 'An internal error occurred during transcription.'}), 500


# --- 5. RUN THE APP ---
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)