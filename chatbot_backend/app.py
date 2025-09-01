# app.py

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import numpy as np
import random
import nltk
from nltk.stem import WordNetLemmatizer
from tensorflow.keras.models import load_model
import pickle

app = Flask(__name__)
CORS(app)

# --- Load all the necessary files ---
lemmatizer = WordNetLemmatizer()
intents = json.loads(open('intents.json').read())
words = pickle.load(open('words.pkl', 'rb'))
classes = pickle.load(open('classes.pkl', 'rb'))
model = load_model('chatbot_model.h5')

# --- Helper Functions (unchanged) ---
def clean_up_sentence(sentence):
    sentence_words = nltk.word_tokenize(sentence)
    sentence_words = [lemmatizer.lemmatize(word.lower()) for word in sentence_words]
    return sentence_words

def bag_of_words(sentence):
    sentence_words = clean_up_sentence(sentence)
    bag = [0] * len(words)
    for s in sentence_words:
        for i, w in enumerate(words):
            if w == s:
                bag[i] = 1
    return np.array(bag)

def predict_class(sentence):
    bow = bag_of_words(sentence)
    res = model.predict(np.array([bow]))[0]
    ERROR_THRESHOLD = 0.25
    results = [[i, r] for i, r in enumerate(res) if r > ERROR_THRESHOLD]
    results.sort(key=lambda x: x[1], reverse=True)
    return_list = []
    for r in results:
        return_list.append({'intent': classes[r[0]], 'probability': str(r[1])})
    return return_list

# --- UPDATED: This function now also returns recommendations ---
def get_response_and_recommendations(intents_list, intents_json):
    if not intents_list:
        return "I'm sorry, I don't understand that.", []

    tag = intents_list[0]['intent']
    list_of_intents = intents_json['intents']
    
    response = "I'm not sure how to respond to that."
    recommendations = []

    for i in list_of_intents:
        if i['tag'] == tag:
            response = random.choice(i['responses'])
            # Get up to 3 other patterns from the same intent as recommendations
            all_patterns = i['patterns']
            # Make sure we don't recommend the same thing over and over
            random.shuffle(all_patterns)
            recommendations = [p for p in all_patterns[:3]]
            break
            
    return response, recommendations

# --- UPDATED: The API endpoint now returns a more complex JSON object ---
@app.route('/predict', methods=['POST'])
def predict():
    message = request.json.get('message')
    ints = predict_class(message)
    # Get both the response and the recommendations
    response, recommendations = get_response_and_recommendations(ints, intents)
    
    # Return both in the JSON payload
    return jsonify({'response': response, 'recommendations': recommendations})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
