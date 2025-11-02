#!/usr/bin/env python3
"""Generate personalized strength workout"""

import sys
import json

EXERCISES = {
    'lower_body': [
        {'name': 'Squats', 'sets': 3, 'reps': 12},
        {'name': 'Lunges', 'sets': 3, 'reps': 10},
        {'name': 'Single-leg Deadlift', 'sets': 3, 'reps': 10},
        {'name': 'Calf Raises', 'sets': 3, 'reps': 15},
    ],
    'core': [
        {'name': 'Plank', 'sets': 3, 'reps': '60s'},
        {'name': 'Side Plank', 'sets': 3, 'reps': '45s'},
        {'name': 'Dead Bug', 'sets': 3, 'reps': 12},
        {'name': 'Bird Dog', 'sets': 3, 'reps': 10},
    ],
    'upper_body': [
        {'name': 'Push-ups', 'sets': 3, 'reps': 12},
        {'name': 'Rows', 'sets': 3, 'reps': 12},
        {'name': 'Shoulder Press', 'sets': 3, 'reps': 10},
    ]
}

def generate_strength_workout(data):
    """Generate a strength workout"""
    
    workout = {
        'workout_type': 'strength',
        'duration_minutes': 45,
        'exercises': [],
        'warmup': [
            {'name': 'Dynamic Stretching', 'duration': '5 minutes'},
            {'name': 'Light Cardio', 'duration': '5 minutes'}
        ],
        'cooldown': [
            {'name': 'Static Stretching', 'duration': '5 minutes'}
        ]
    }
    
    # Select exercises from each category
    workout['exercises'].extend(EXERCISES['lower_body'][:3])
    workout['exercises'].extend(EXERCISES['core'][:2])
    workout['exercises'].extend(EXERCISES['upper_body'][:2])
    
    return workout

if __name__ == "__main__":
    try:
        data = json.load(sys.stdin)
        workout = generate_strength_workout(data)
        print(json.dumps(workout, indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)
