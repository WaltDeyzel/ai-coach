#!/usr/bin/env python3
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
