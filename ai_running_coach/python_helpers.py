#!/usr/bin/env python3
"""
Extract workout details from training plan
Usage: extract_workout.py <date>
Reads training plan JSON from stdin
"""

import sys
import json
from datetime import datetime, timedelta

def parse_date(date_str):
    """Parse date string in various formats"""
    formats = [
        "%Y-%m-%d",
        "%Y/%m/%d",
        "%d-%m-%Y",
        "%m/%d/%Y"
    ]
    
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt)
        except ValueError:
            continue
    
    # Try relative dates
    if date_str.lower() == "today":
        return datetime.now()
    elif date_str.lower() == "tomorrow":
        return datetime.now() + timedelta(days=1)
    
    raise ValueError(f"Unable to parse date: {date_str}")

def extract_workout(training_plan, target_date):
    """Extract workout for specific date from training plan"""
    
    if not training_plan or 'data' not in training_plan:
        return {
            "error": "Invalid training plan format",
            "found": False
        }
    
    plan_data = training_plan['data']
    
    # Handle different plan structures
    if 'weeks' in plan_data:
        # Weekly structure
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
        # Flat workout list
        for workout in plan_data['workouts']:
            workout_date = parse_date(workout.get('date', ''))
            if workout_date.date() == target_date.date():
                return {
                    "found": True,
                    "workout": workout
                }
    
    return {
        "found": False,
        "message": f"No workout scheduled for {target_date.date()}"
    }

def main():
    if len(sys.argv) < 2:
        print(json.dumps({
            "error": "Date argument required"
        }))
        sys.exit(1)
    
    date_str = sys.argv[1]
    
    try:
        target_date = parse_date(date_str)
    except ValueError as e:
        print(json.dumps({
            "error": str(e)
        }))
        sys.exit(1)
    
    # Read training plan from stdin
    try:
        training_plan = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(json.dumps({
            "error": f"Invalid JSON input: {str(e)}"
        }))
        sys.exit(1)
    
    # Extract and print workout
    result = extract_workout(training_plan, target_date)
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
