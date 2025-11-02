#!/usr/bin/env python3
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
