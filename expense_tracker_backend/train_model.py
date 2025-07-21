import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import SGDClassifier
from sklearn.pipeline import Pipeline
import joblib

print("Starting model training process...")

# 1. Load Data from CSV
try:
    data = pd.read_csv('sample_data.csv')
    print(f"Successfully loaded {len(data)} training examples.")
except FileNotFoundError:
    print("Error: 'sample_data.csv' not found. Make sure it's in the same directory.")
    exit()

# 2. Define Features (the 'text' column) and Target (the 'category' column)
X = data['text']
y = data['category']

# 3. Create a Scikit-learn Pipeline
# A pipeline makes our workflow clean and reproducible.
# It chains a vectorizer (to turn text into numbers) and a classifier.
text_classifier = Pipeline([
    # TfidfVectorizer: Converts text into meaningful numerical vectors.
    ('tfidf', TfidfVectorizer(stop_words='english')),
    
    # SGDClassifier: A fast and efficient classification algorithm, great for text.
    ('clf', SGDClassifier(loss='hinge', penalty='l2',
                           alpha=1e-3, random_state=42,
                           max_iter=10, tol=None)),
])

# 4. Train the model on our entire dataset
print("Training the category classification model...")
text_classifier.fit(X, y)
print("Training complete.")

# 5. Save the entire pipeline (vectorizer + classifier) to a single file.
# This file is our final, trained model.
joblib.dump(text_classifier, 'category_classifier.pkl')
print("Model successfully saved to 'category_classifier.pkl'")