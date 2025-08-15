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

# 2. Define Features (X) and Target (y)
X = data['text']
y = data['category']

# 3. Create a Scikit-learn Pipeline
text_classifier = Pipeline([
    # --- THIS IS THE KEY MODIFICATION ---
    # The `ngram_range=(1, 3)` parameter tells the model to look at
    # single words, pairs of words (bigrams), and triplets of words (trigrams).
    # This helps it understand context, like "mobile phone" being one concept.
    ('tfidf', TfidfVectorizer(stop_words='english', ngram_range=(1, 3))),
    # ------------------------------------
    
    # The classifier itself remains the same.
    ('clf', SGDClassifier(loss='hinge', penalty='l2',
                           alpha=1e-3, random_state=42,
                           max_iter=10, tol=None)),
])

# 4. Train the new, smarter model on our data
print("Training the category classification model with n-grams...")
text_classifier.fit(X, y)
print("Training complete.")

# 5. Save the new model file. This will overwrite the old one.
joblib.dump(text_classifier, 'category_classifier.pkl')
print("New, smarter model successfully saved to 'category_classifier.pkl'")