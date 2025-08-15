import csv
import random

NUM_ROWS = 3000 # Increased dataset size
OUTPUT_FILE = 'sample_data.csv'

# --- EXPANDED VOCABULARY with Brands, Vendors, and more specific items ---
CATEGORIES = {
    'Food': ['groceries', 'lunch', 'dinner', 'coffee', 'pizza', 'breakfast', 'vegetables', 'fruits', 'takeout food', 'restaurant meal', 'snacks', 'pastries', 'ice cream', 'zomato order', 'swiggy delivery', 'milk and bread', 'bigbasket groceries', 'blinkit order', 'chicken biryani', 'paneer tikka', 'dominos pizza'],
    'Transport': ['uber ride', 'taxi fare', 'bus ticket', 'metro card recharge', 'train ticket', 'fuel for car', 'parking fee', 'auto rickshaw fare', 'flight ticket', 'car service', 'ola cab', 'rapido bike', 'petrol', 'diesel'],
    'Shopping': ['new shirt', 'jeans', 'headphones', 'book', 'skincare products', 'running shoes', 'gift', 'watch', 'laptop', 'mobile phone', 'furniture', 'home decor', 'sunglasses', 'amazon purchase', 'flipkart order', 'myntra shopping', 'teddy bear toy', 'ps5 game', 'adidas shoes', 'nike t-shirt', 'samsung phone'],
    'Utilities': ['electricity bill', 'internet bill', 'phone recharge', 'water bill', 'gas cylinder', 'house rent', 'maintenance fee', 'DTH recharge', 'broadband payment', 'subscription service', 'airtel payment', 'jio recharge', 'vodafone idea bill'],
    'Health': ['medicines', 'doctor\'s visit fee', 'health insurance premium', 'vitamins', 'band-aids', 'lab test', 'hospital bill', 'dental checkup', 'apollo pharmacy', 'pharmeasy order', 'netmeds purchase'],
    'Entertainment': ['movie tickets', 'concert tickets', 'Netflix subscription', 'Spotify premium', 'video game', 'bowling with friends', 'amusement park entry', 'sports match ticket', 'bookmyshow booking', 'hotstar plan', 'prime video'],
    'Education': ['online course fee', 'textbooks', 'stationery', 'exam fee', 'pen and notebooks', 'udemy course', 'coursera specialization', 'school fees'],
    'Personal Care': ['haircut', 'shampoo', 'soap', 'gym membership', 'protein powder', 'salon visit', 'cosmetics', 'nykaa products'],
    'Gifts & Donations': ['birthday gift', 'donation to charity', 'wedding present', 'gift for anniversary', 'contribution to fundraiser'],
    'Other': ['bank fee', 'postage stamp', 'home repair', 'pet food', 'laundry service', 'magazine subscription', 'software license', 'courier charges']
}

# --- MORE VARIED & REALISTIC TEMPLATES ---
TEMPLATES = [
    "bought {item} for {amount} {currency}",
    "paid {amount} {currency} for {item}",
    "spent {amount} on {item}",
    "{item} cost {amount}",
    "just got {item} for {amount} {currency}",
    "purchase of {item} - {amount}",
    "recharged my {item} with {amount}",
    "monthly {item} payment of {amount}",
    "paid for {item}, amount was {amount}",
    "{item} {amount} {currency}",
    "got a {item} for {amount}",
    "payment for {item} of {amount} {currency}",
    "bill for {item} was {amount}",
    "expense on {item}, {amount}",
    "ordered {item} from a vendor for {amount}", # New template
    "{item} purchase on amazon for {amount}", # New template with brand
    "swiggy order for {item} was {amount} rupees" # New template with brand
]

CURRENCIES = ['rupees', 'rs', 'inr', '']

def generate_sentence():
    category = random.choice(list(CATEGORIES.keys()))
    item = random.choice(CATEGORIES[category])
    template = random.choice(TEMPLATES)
    currency = random.choice(CURRENCIES)

    if category in ['Utilities', 'Shopping', 'Transport', 'Education']:
        amount = random.randint(200, 25000)
    elif category == 'Health':
        amount = random.randint(100, 5000)
    else:
        amount = random.randint(50, 1500)

    text = template.format(item=item, amount=amount, currency=currency).strip()
    text = ' '.join(text.split())
    
    return text, category

def main():
    try:
        with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['text', 'category'])
            print(f"Generating {NUM_ROWS} rows of new training data...")
            for i in range(NUM_ROWS):
                text, category = generate_sentence()
                writer.writerow([text, category])
                if (i + 1) % 250 == 0:
                    print(f"  ...generated {i + 1}/{NUM_ROWS} rows")
            print(f"\nSuccessfully created '{OUTPUT_FILE}' with {NUM_ROWS} rows.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    main()