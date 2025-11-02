#!/usr/bin/env python3
"""
Create all Python helper scripts for AI Running Coach
Run this script to generate all Python helpers in the python/ directory
"""

import os
import sys

def create_directory(path):
    os.makedirs(path, exist_ok=True)
    print(f"✓ Created directory: {path}")

def create_file(path, content):
    with open(path, 'w') as f:
        f.write(content)
    os.chmod(path, 0o755)
    print(f"✓ Created: {path}")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    python_dir = os.path.join(script_dir, 'python')
    
    create_directory(python_dir)
    
    # ========================================================================
    # PARSE INTENT
    # ========================================================================
    create_file(os.path.join(python_dir, 'parse_intent.py'), '''#!/usr/bin/env python3
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
''')

    # ========================================================================
    # EXTRACT WORKOUT
    # ========================================================================
    create_file(os.path.join(python_dir, 'extract_workout.py'), '''#!/usr/bin/env python3
"""Extract workout details from training plan"""

import sys
import json
from datetime import datetime, timedelta

def parse_date(date_str):
    """Parse date string in various formats"""
    formats = ["%Y-%m-%d", "%Y/%m/%d", "%d-%m-%Y", "%m/%d/%Y"]
    
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt)
        except ValueError:
            continue
    
    if date_str.lower() == "today":
        return datetime.now()
    elif date_str.lower() == "tomorrow":
        return datetime.now() + timedelta(days=1)
    
    raise ValueError(f"Unable to parse date: {date_str}")

def extract_workout(training_plan, target_date):
    """Extract workout for specific date from training plan"""
    
    if not training_plan or 'data' not in training_plan:
        return {"error": "Invalid training plan format", "found": False}
    
    plan_data = training_plan['data']
    
    if 'weeks' in plan_data:
        for week in plan_data['weeks']:
            if 'workouts' in week:
                for workout in week['workouts']:
                    workout_date = parse_date(workout.get('date', ''))
                    if workout_date.date() == target_date.date():
                        return {
                            "found": True,
                            "workout": workout,
                            "week": week.get('week_number', 'unknown')
                        }
    
    elif 'workouts' in plan_data:
        for workout in plan_data['workouts']:
            workout_date = parse_date(workout.get('date', ''))
            if workout_date.date() == target_date.date():
                return {"found": True, "workout": workout}
    
    return {
        "found": False,
        "message": f"No workout scheduled for {target_date.date()}"
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Date argument required"}))
        sys.exit(1)
    
    date_str = sys.argv[1]
    
    try:
        target_date = parse_date(date_str)
    except ValueError as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
    
    try:
        training_plan = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid JSON input: {str(e)}"}))
        sys.exit(1)
    
    result = extract_workout(training_plan, target_date)
    print(json.dumps(result, indent=2))
''')

    # ========================================================================
    # GENERATE TRAINING PLAN
    # ========================================================================
    create_file(os.path.join(python_dir, 'generate_training_plan.py'), '''#!/usr/bin/env python3
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
''')

    # ========================================================================
    # ANALYZE TRENDS
    # ========================================================================
    create_file(os.path.join(python_dir, 'analyze_trends.py'), '''#!/usr/bin/env python3
"""Analyze performance trends from activity data"""

import sys
import json
from datetime import datetime

def analyze_trends(activities):
    """Analyze trends in activity data"""
    
    if not activities or len(activities) == 0:
        return {"error": "No activities to analyze"}
    
    # Extract data
    data = [act.get('data', act) for act in activities]
    
    # Calculate averages
    avg_pace = sum([d.get('pace', 0) for d in data]) / len(data) if data else 0
    avg_distance = sum([d.get('distance', 0) for d in data]) / len(data) if data else 0
    avg_hr = sum([d.get('heart_rate', 0) for d in data]) / len(data) if data else 0
    
    # Trend detection (simple: compare first half to second half)
    mid = len(data) // 2
    first_half_pace = sum([d.get('pace', 0) for d in data[:mid]]) / mid if mid > 0 else 0
    second_half_pace = sum([d.get('pace', 0) for d in data[mid:]]) / (len(data) - mid) if mid > 0 else 0
    
    improving = second_half_pace < first_half_pace if first_half_pace > 0 else False
    
    return {
        'total_activities': len(data),
        'average_pace_min_per_km': round(avg_pace, 2),
        'average_distance_km': round(avg_distance, 2),
        'average_heart_rate': round(avg_hr, 0),
        'trend': 'improving' if improving else 'stable',
        'analysis_date': datetime.now().isoformat()
    }

if __name__ == "__main__":
    try:
        activities = json.load(sys.stdin)
        analysis = analyze_trends(activities)
        print(json.dumps(analysis, indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)
''')

    # ========================================================================
    # DETECT ANOMALIES
    # ========================================================================
    create_file(os.path.join(python_dir, 'detect_anomalies.py'), '''#!/usr/bin/env python3
"""Detect anomalies in training data"""

import sys
import json

def detect_anomalies(activities):
    """Detect potential overtraining or injury risk"""
    
    if len(activities) < 3:
        return {"has_alerts": False}
    
    data = [act.get('data', act) for act in activities]
    
    # Calculate weekly load
    distances = [d.get('distance', 0) for d in data]
    total_distance = sum(distances)
    avg_distance = total_distance / len(distances)
    
    # Check for sudden spike
    recent_avg = sum(distances[-3:]) / 3
    spike = recent_avg > (avg_distance * 1.3)
    
    # Check for high heart rate
    heart_rates = [d.get('heart_rate', 0) for d in data if d.get('heart_rate', 0) > 0]
    high_hr = False
    if heart_rates:
        avg_hr = sum(heart_rates) / len(heart_rates)
        high_hr = avg_hr > 165
    
    has_alerts = spike or high_hr
    
    result = {
        "has_alerts": has_alerts,
        "alert_type": "",
        "severity": "low",
        "details": {},
        "recommended_action": ""
    }
    
    if spike:
        result["alert_type"] = "overtraining"
        result["severity"] = "medium"
        result["details"] = {
            "weekly_distance": round(total_distance, 1),
            "spike_detected": True
        }
        result["recommended_action"] = "Consider reducing training load"
    
    if high_hr:
        result["alert_type"] = "fatigue"
        result["severity"] = "medium"
        result["details"]["average_heart_rate"] = round(avg_hr, 0)
        result["recommended_action"] = "Increase rest and recovery"
    
    return result

if __name__ == "__main__":
    try:
        activities = json.load(sys.stdin)
        result = detect_anomalies(activities)
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)
''')

    # ========================================================================
    # GENERATE STRENGTH WORKOUT
    # ========================================================================
    create_file(os.path.join(python_dir, 'generate_strength_workout.py'), '''#!/usr/bin/env python3
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
''')

    # ========================================================================
    # More helpers...
    # ========================================================================
    
    # Create simple placeholders for other scripts
    for script_name in [
        'process_activity.py',
        'adjust_training_plan.py',
        'reduce_training_load.py',
        'assess_injury_risk.py',
        'generate_rehab_plan.py',
        'analyze_nutrition.py',
        'generate_meal_plan.py',
        'hydration_calculator.py',
        'update_training_progress.py',
        'generate_briefing.py'
    ]:
        create_file(os.path.join(python_dir, script_name), f'''#!/usr/bin/env python3
"""
{script_name.replace('_', ' ').title().replace('.Py', '')}
Placeholder - Implement specific logic as needed
"""

import sys
import json

def main():
    try:
        data = json.load(sys.stdin) if not sys.stdin.isatty() else {{}}
        # Implement your logic here
        result = {{"status": "success", "message": "Processing complete"}}
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(json.dumps({{"error": str(e)}}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
''')
    
    print(f"\\n✓ All Python helper scripts created in {python_dir}/")

if __name__ == "__main__":
    main()
