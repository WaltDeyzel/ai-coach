#!/usr/bin/env python3
import sys
import re

INTENT_PATTERNS = {
    'training_plan': [r'(create|generate|make).*training plan', r'training.*plan'],
    'workout': [r'(today|tomorrow).*workout', r'workout.*(today|tomorrow)'],
    'strength': [r'strength.*workout', r'(gym|weight).*training'],
    'nutrition': [r'(what|should).*eat', r'meal.*plan'],
    'hydration': [r'(how much).*water', r'hydration'],
    'injury': [r'(have|feel).*pain', r'(hurt|sore)', r'injury'],
}

def parse_intent(message):
    message_lower = message.lower()
    for intent, patterns in INTENT_PATTERNS.items():
        for pattern in patterns:
            if re.search(pattern, message_lower):
                return intent
    return 'general'

if __name__ == "__main__":
    user_message = sys.stdin.read().strip()
    print(parse_intent(user_message))
