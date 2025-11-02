#!/usr/bin/env python3
"""Parse user intent from natural language input"""

import sys
import json
import re

INTENT_PATTERNS = {
    'training_plan': [
        r'(create|generate|make|build).*training plan',
        r'training.*plan',
        r'(create|generate).*plan.*race',
        r'(prepare|train).*for.*(race|marathon|10k|5k|half)',
    ],
    'workout': [
        r'(today|tomorrow).*workout',
        r'workout.*(today|tomorrow)',
        r'what.*workout',
        r'(show|tell).*workout',
    ],
    'strength': [
        r'strength.*workout',
        r'(generate|create).*strength',
        r'(gym|weight|resistance).*training',
    ],
    'nutrition': [
        r'(what|should).*eat',
        r'meal.*plan',
        r'nutrition.*advice',
        r'(food|diet).*recommendation',
    ],
    'hydration': [
        r'(how much|should).*water',
        r'hydration.*strategy',
        r'drink.*during.*run',
    ],
    'injury': [
        r'(have|feel).*pain',
        r'(hurt|sore|ache)',
        r'injury',
        r'rehab',
    ],
    'analysis': [
        r'(how|what).*progress',
        r'(show|view).*data',
        r'(analyze|analysis).*performance',
    ],
    'daily_briefing': [
        r'daily.*briefing',
        r'today.*summary',
        r'what.*today',
    ],
}

def parse_intent(message):
    """Parse user message and determine intent"""
    message_lower = message.lower()
    
    for intent, patterns in INTENT_PATTERNS.items():
        for pattern in patterns:
            if re.search(pattern, message_lower):
                return intent
    
    return 'general'

if __name__ == "__main__":
    user_message = sys.stdin.read().strip()
    intent = parse_intent(user_message)
    print(intent)
