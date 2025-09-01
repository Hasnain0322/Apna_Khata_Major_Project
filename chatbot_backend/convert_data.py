# convert_data.py

import pandas as pd
import json

def convert_csv_to_intents(csv_file_path, json_file_path):
    """
    Reads a CSV and converts it into the intents.json format,
    using a rich set of humanized, custom responses for all intents.
    """

    # --- FINALIZED: Added custom responses for the Main App Navigation ---
    custom_responses = {
        "greeting": [
            "Hello! How can I help you manage your finances today?",
            "Hi there! Ready to track some expenses? Ask me anything.",
            "Hey! I'm your friendly expense assistant. What's on your mind?",
        ],
        "goodbye": [
            "Goodbye! Happy tracking!",
            "Talk to you later! Don't hesitate to come back if you have more questions.",
            "Bye for now! Have a great day.",
        ],
        "thanks": [
            "You're very welcome!",
            "Happy to help! Is there anything else you need?",
            "My pleasure! Let me know if another question comes up.",
        ],
        "about_bot": [
            "I'm a friendly chatbot assistant, here to help you navigate this expense tracking app.",
            "You can think of me as your personal guide to managing your finances with this app!",
        ],
        "options": [
            "I can help with login, registration, adding expenses, and navigating the app. What would you like to know?",
            "You can ask me for help with any of the app's features! For example, try asking 'How do I view my reports?'",
        ],
        "add_expense_help": [
            "It's super easy! From the home screen, tap 'Text Entry'. Then, just type a simple sentence like 'Paid 150 for lunch' and tap the 'Analyze Expense' button.",
            "To add an expense with text, tap the 'Text Entry' button on the home screen. Describe your expense in the text box, and let the AI do the heavy lifting for you.",
        ],
        "edit_expense_help": [
            "Of course! If the AI's analysis isn't quite right, just tap the 'Edit' button. That will open a dialog where you can correct all the details.",
            "You have full control. After the app analyzes an expense, you'll see an 'Edit' button. Use that to make any corrections before you save.",
        ],
        "save_expense_help": [
            "Once you're happy with the analyzed details, just hit 'Confirm & Save'. This will add the transaction permanently to your expense log.",
            "Ready to save? Tapping 'Confirm & Save' finalizes the entry and adds it to your 'My Expenses' list.",
        ],
        "troubleshooting_analysis": [
            "Hmm, if the analysis is failing, it could be a connection issue. First, make sure the Python server is running on your computer.",
            "If you're getting an error, try rephrasing the expense to be more specific, like 'Paid 200 for groceries' instead of just 'groceries'.",
        ],
        "edit_dialog_fields": [
            "Absolutely. In the 'Edit Expense' pop-up, you can tap on the 'Item' and 'Amount' fields to type in new values. You can also tap the 'Category' dropdown to pick a new one.",
            "You can easily change any of the details in the edit dialog. Just tap on a field to update it.",
        ],
        "edit_dialog_save": [
            "Once you hit 'Save Changes', the app will lock in your edits and update the details on the previous screen. You're all set to confirm and save!",
            "Tapping 'Save Changes' confirms the corrections you made in the pop-up. The app will then be ready for you to permanently save the transaction.",
        ],
        "edit_dialog_cancel": [
            "Don't worry, tapping 'Cancel' is like an escape button. It will close the pop-up and none of your edits will be saved.",
            "If you hit 'Cancel', any changes you made in the edit dialog are safely discarded.",
        ],
        "edit_dialog_validation": [
            "If you can't save, the app is likely trying to prevent an error. Please make sure every field is filled out and that the 'Amount' contains a valid number.",
            "Seeing a red error? It means a field needs to be fixed. Usually, it's a missing item name or an invalid amount.",
        ],
        "view_expenses_help": [
            "The 'My Expenses' screen is your financial diary! It shows a complete history of all the expenses you've saved, with the most recent ones at the top.",
            "You can find all your past spending on the 'My Expenses' screen. It's a list that shows every transaction you've recorded.",
        ],
        "delete_expense_help": [
            "Currently, deleting an expense directly from the list isn't a feature. This is a great suggestion for a future update, though!",
            "This screen is for viewing your history. The ability to delete expenses from this list hasn't been added yet.",
        ],
        "edit_from_list_help": [
            "Right now, you can only view expenses on this screen. Editing an expense after it has been saved isn't currently possible.",
            "To keep your history accurate, saved expenses can't be edited.",
        ],
        "troubleshoot_view_expenses": [
            "If you're seeing a spinning circle, the app is currently loading your data from the cloud. If it's stuck or shows an error, it could be due to a poor internet connection.",
            "An error on this screen usually points to a problem with connecting to the database. Please check your internet connection.",
        ],
        "empty_expenses_list_help": [
            "It looks like your expense history is empty! You can start by adding your first expense from the main screen.",
            "If you've just saved an expense and it's not appearing, try waiting a moment for the list to refresh from the database.",
        ],
        "register_help": [
            "To create a new account, simply fill in your email address and a secure password on the 'Register' screen, then tap the 'Register' button.",
            "Signing up is easy! Just enter your email and a password on the registration page to get started.",
        ],
        "register_password_rules": [
            "For your security, your password must be at least 6 characters long. It's a good idea to mix letters, numbers, and symbols!",
            "Please make sure your password is 6 characters or longer. This helps keep your account secure.",
        ],
        "register_email_rules": [
            "You'll need to use a valid email address that you can access. This is important in case you need to recover your account later.",
            "Just type in your email address in the 'Email' field. Make sure it's a real email address!",
        ],
        "register_success_help": [
            "Congratulations on creating your account! The next step is to head back to the login screen and sign in with your new email and password.",
            "That's great! After a successful registration, you can now log in to the app and start tracking your expenses.",
        ],
        "register_failure_help": [
            "If your registration failed, it's most likely because that email address is already registered. Try logging in instead, or use a different email address.",
            "Hmm, there might be an issue. Please double-check that you've entered a valid email. If you have, it's possible that an account with that email already exists.",
        ],
        "navigate_to_login": [
            "No problem at all. On the registration screen, just tap the link at the bottom that says 'Already have an account? Login' to go to the sign-in page.",
            "If you already have an account, you can use the text button at the bottom of the screen to switch over to the login page.",
        ],
        "login_help": [
            "To sign in, just enter the email and password you used to register, then tap the 'Sign In' button.",
            "Welcome back! Enter your credentials on the login screen to access your account."
        ],
        "login_failure_help": [
            "Hmm, that didn't work. This error usually means the email or password you entered doesn't match our records. Please double-check them and try again.",
            "If you're seeing a 'Could not sign in' error, it's a good idea to check for typos in both your email and password. Case matters in passwords!"
        ],
        "login_password_help": [
            "I noticed there isn't a 'Forgot Password' link on the login screen. For now, please try to remember your password.",
            "It looks like a password reset feature hasn't been added to the app yet. If you're completely stuck, you might consider registering again with a different email."
        ],
        "navigate_to_register": [
            "No account yet? No problem! Just tap the 'Don't have an account? Register' link at the bottom of the screen to get started.",
            "If you're a new user, you can tap the text button at the bottom to go to the registration page and create your account."
        ],
        "home_screen_logout": [
            "To sign out, just tap the logout icon in the top-right corner of the Home screen. A confirmation box will pop up to make sure you don't log out by accident.",
            "You can log out by tapping the icon that looks like a person walking out of a door at the top of the Home screen."
        ],
        "home_screen_search": [
            "The search bar at the top of the Home screen lets you find specific expenses. Currently, it's a placeholder for a future update!",
            "You can use the search bar to look for past transactions. This feature is still under development but will be very powerful soon!"
        ],
        "home_screen_actions": [
            "The home screen has several action buttons! 'Text Entry' is for manually adding an expense. The others, like 'Scan Receipt' and 'Voice to Text', are exciting features planned for future updates.",
            "These buttons are your main shortcuts. Use 'Text Entry' to start adding an expense. The other buttons will eventually let you add expenses in different ways, like by scanning or speaking."
        ],
        "scan_receipt_help": [
            "The 'Scan Receipt' feature will be a powerful tool! It will let you use your phone's camera to automatically capture all the details from a physical receipt.",
            "This is a planned feature that will save you a lot of time. Soon, you'll be able to just take a picture of a receipt to log an expense."
        ],
        "parse_pdf_help": [
            "The 'Parse PDF' button will allow you to upload a PDF statement from your bank or a service, and the app will automatically find and import the transactions for you.",
            "This feature is coming soon! It will be perfect for importing expenses from e-receipts or digital statements you receive as PDFs."
        ],
        "voice_entry_help": [
            "The 'Voice to Text' button will let you add an expense just by speaking. For example, you could say 'Paid 300 for a movie ticket' and the app would understand.",
            "This will be a quick and hands-free way to log your spending. Just tap the microphone and speak your expense."
        ],
        "text_entry_help": [
            "The 'Text Entry' button is your primary way to add an expense. Tapping it will take you to the 'Add Expense' screen where you can describe your purchase for the AI to analyze.",
            "Use the 'Text Entry' button when you want to manually type in a new expense. It's the most direct way to get started."
        ],
        "reports_help": [
            "The 'Reports' section gives you powerful insights into your spending habits. You can generate a Monthly, Yearly, or even a Custom date range report.",
            "Want to see where your money is going? Head to the 'Reports' section on the Home screen to get a detailed breakdown of your expenses over different time periods."
        ],
        "profile_settings_help": [
            "You can manage your personal details and app preferences using the 'Profile' and 'Settings' buttons at the bottom of the Home screen.",
            "The 'Personal' section contains your 'Profile' and 'Settings', allowing you to customize your experience and manage your account info."
        ],
        "navigation_main": [
            "You can easily get around the app using the navigation bar at the very bottom of the screen. Each icon takes you to a major section.",
            "The main way to navigate is the bottom bar. It has four icons: Home, Expenses, Reports, and Profile. Just tap one to switch screens."
        ],
        "navigation_home": [
            "To get back to the main dashboard, just tap the 'Home' icon, the one that looks like a little house, in the bottom navigation bar.",
            "The 'Home' button in the bottom left corner will always take you back to the main screen with all the action buttons."
        ],
        "navigation_expenses": [
            "You can see your full transaction history by tapping the 'Expenses' tab at the bottom. It's the one that looks like a long receipt.",
            "To view a list of all your past expenses, tap the 'Expenses' icon in the bottom navigation bar."
        ],
        "navigation_reports": [
            "For all your charts and financial insights, tap the 'Reports' icon, the one that looks like a bar chart, in the bottom navigation bar.",
            "Want to see your spending visualized? The 'Reports' tab at the bottom is where you'll find all the graphs."
        ],
        "navigation_profile": [
            "Your account information and app settings can be found on the 'Profile' screen. Just tap the person icon in the bottom right corner.",
            "To manage your profile, tap the 'Profile' icon in the bottom navigation bar."
        ]
    }

    try:
        df = pd.read_csv(csv_file_path)
    except FileNotFoundError:
        print(f"Error: The file '{csv_file_path}' was not found.")
        return

    intents = {}
    for _, row in df.iterrows():
        tag = row['category']
        pattern = row['text']
        
        if tag not in intents:
            if tag in custom_responses:
                response_list = custom_responses[tag]
            else:
                response_list = [
                    f"Okay, I've noted that down under {tag}.",
                    f"Got it. Categorized as {tag}.",
                    f"Perfect, that's been filed under {tag} for you."
                ]
            
            intents[tag] = {
                "tag": tag,
                "patterns": [],
                "responses": response_list
            }
        intents[tag]['patterns'].append(pattern)

    output_json = {"intents": list(intents.values())}

    with open(json_file_path, 'w') as f:
        json.dump(output_json, f, indent=4)

    print(f"Successfully converted data to '{json_file_path}' with humanized responses.")
    print(f"Found {len(df)} patterns across {len(intents)} unique intents.")

if __name__ == '__main__':
    csv_path = 'data.csv'
    json_path = 'intents.json'
    convert_csv_to_intents(csv_path, json_path)
