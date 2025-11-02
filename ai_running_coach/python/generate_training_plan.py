#!/usr/bin/env python3
"""Generate personalized training plan"""

import sys
import json
from datetime import datetime, timedelta

def generate_training_plan(user_profile):
    """Generate a basic training plan based on user profile"""
    
    data = user_profile.get('data', user_profile)
    
    goal = data.get('goals', {}).get('target_race', '10k')
    weeks = 12 if goal in ['10k', '5k'] else 16
    training_days = data.get('preferences', {}).get('training_days_per_week', 4)
    
    start_date = datetime.now()
    workouts = []
    
    for week in range(weeks):
        week_start = start_date + timedelta(weeks=week)
        
        # Simple progression: easy, tempo, long, easy
        workout_types = ['easy', 'tempo', 'long', 'easy'][:training_days]
        
        for day_offset, workout_type in enumerate(workout_types):
            workout_date = week_start + timedelta(days=day_offset * 2)
            
            if workout_type == 'easy':
                distance = 5 + (week * 0.3)
                pace = 'easy'
            elif workout_type == 'tempo':
                distance = 6 + (week * 0.2)
                pace = 'tempo'
            elif workout_type == 'long':
                distance = 8 + (week * 0.5)
                pace = 'easy'
            else:
                distance = 5
                pace = 'easy'
            
            workouts.append({
                'date': workout_date.strftime('%Y-%m-%d'),
                'type': workout_type,
                'distance_km': round(distance, 1),
                'pace': pace,
                'week_number': week + 1
            })
    
    return {
        'plan_id': f"plan_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
        'goal': goal,
        'weeks': weeks,
        'workouts': workouts,
        'created': datetime.now().isoformat()
    }

if __name__ == "__main__":
    try:
        user_profile = json.load(sys.stdin)
        plan = generate_training_plan(user_profile)
        print(json.dumps(plan, indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)
