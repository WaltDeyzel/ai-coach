#!/usr/bin/env python3
"""
GarminCollectorAgent - Lightweight daily sync for AI Running Coach
Collects: today's activities, sleep, health metrics
Generates: daily_summary.json for agents to consume
"""

import os
import sys
import json
import time
from datetime import datetime, timedelta, date
from pathlib import Path
import logging

from garminconnect import Garmin, GarminConnectAuthenticationError
from dotenv import load_dotenv

# Setup paths
PROJECT_ROOT = Path(__file__).parent.parent
GARMIN_DATA = PROJECT_ROOT / "shared_knowledge_base" / "garmin_data"
RECENT_CACHE = GARMIN_DATA / "recent_cache"
AGGREGATES = GARMIN_DATA / "aggregates"
LOG_DIR = PROJECT_ROOT / "logs"

# Ensure directories exist
for directory in [GARMIN_DATA, RECENT_CACHE, AGGREGATES, LOG_DIR]:
    directory.mkdir(parents=True, exist_ok=True)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [garmin_collector] [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / "garmin_collector.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class GarminCollector:
    """Lightweight Garmin data collector"""
    
    def __init__(self):
        self.client = None
        self.load_credentials()
        
    def load_credentials(self):
        """Load credentials from .env"""
        env_path = PROJECT_ROOT / ".env"
        if not env_path.exists():
            logger.error(".env file not found!")
            sys.exit(1)
            
        load_dotenv(env_path)
        self.email = os.getenv("GARMIN_EMAIL")
        self.password = os.getenv("GARMIN_PASSWORD")
        
        if not self.email or not self.password:
            logger.error("GARMIN_EMAIL and GARMIN_PASSWORD must be set in .env")
            sys.exit(1)
            
    def authenticate(self):
        """Authenticate with Garmin Connect"""
        try:
            logger.info("Authenticating with Garmin Connect...")
            self.client = Garmin(self.email, self.password)
            self.client.login()
            logger.info("✓ Authentication successful")
            return True
        except GarminConnectAuthenticationError as e:
            logger.error(f"Authentication failed: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            return False
            
    def get_todays_activities(self):
        """Get today's activities"""
        try:
            activities = self.client.get_activities(0, 10)  # Last 10 activities
            today = date.today().isoformat()
            
            todays_activities = []
            for activity in activities:
                activity_date = activity.get('startTimeLocal', '')[:10]
                if activity_date == today:
                    todays_activities.append(self.extract_essential(activity))
                    
            return todays_activities
        except Exception as e:
            logger.error(f"Error fetching activities: {e}")
            return []
            
    def extract_essential(self, activity):
        """Extract essential metrics from activity"""
        distance = activity.get('distance', 0)
        duration = activity.get('duration', 0)
        
        pace = None
        if distance > 0 and duration > 0:
            pace = round((duration / distance * 1000) / 60, 2)
            
        return {
            "activity_id": str(activity.get('activityId')),
            "type": activity.get('activityType', {}).get('typeKey', 'unknown'),
            "date": activity.get('startTimeLocal'),
            "distance_km": round(distance / 1000, 2) if distance else 0,
            "duration_minutes": round(duration / 60, 1) if duration else 0,
            "pace_min_per_km": pace,
            "avg_hr": activity.get('averageHR'),
            "max_hr": activity.get('maxHR'),
            "calories": activity.get('calories'),
            "elevation_gain_m": activity.get('elevationGain')
        }
        
    def get_sleep_data(self):
        """Get last night's sleep"""
        try:
            sleep = self.client.get_sleep_data(date.today().isoformat())
            if sleep:
                return {
                    "duration_hours": round(sleep.get('sleepTimeSeconds', 0) / 3600, 1),
                    "quality": sleep.get('sleepQuality', 'unknown'),
                    "deep_sleep_hours": round(sleep.get('deepSleepSeconds', 0) / 3600, 1),
                    "light_sleep_hours": round(sleep.get('lightSleepSeconds', 0) / 3600, 1),
                    "awake_hours": round(sleep.get('awakeTimeSeconds', 0) / 3600, 1)
                }
        except Exception as e:
            logger.warning(f"Could not fetch sleep data: {e}")
            return None
            
    def get_health_metrics(self):
        """Get today's health metrics"""
        health = {}
        
        try:
            # Resting heart rate
            rhr = self.client.get_rhr_day(date.today().isoformat())
            if rhr:
                health['resting_hr'] = rhr.get('restingHeartRate')
        except Exception as e:
            logger.warning(f"Could not fetch RHR: {e}")
            
        try:
            # Get user stats for weight
            stats = self.client.get_stats(date.today().isoformat())
            if stats:
                health['weight_kg'] = stats.get('weight')
        except Exception as e:
            logger.warning(f"Could not fetch weight: {e}")
            
        return health
        
    def get_weekly_summary(self):
        """Calculate this week's summary"""
        try:
            activities = self.client.get_activities(0, 50)
            week_start = (datetime.now() - timedelta(days=datetime.now().weekday())).date()
            
            weekly_activities = []
            for activity in activities:
                activity_date = datetime.fromisoformat(
                    activity.get('startTimeLocal', '').replace('Z', '')
                ).date()
                
                if activity_date >= week_start:
                    weekly_activities.append(activity)
                    
            total_distance = sum(a.get('distance', 0) for a in weekly_activities) / 1000
            total_duration = sum(a.get('duration', 0) for a in weekly_activities) / 3600
            
            return {
                "total_distance_km": round(total_distance, 1),
                "total_duration_hours": round(total_duration, 1),
                "activities_completed": len(weekly_activities)
            }
        except Exception as e:
            logger.error(f"Error calculating weekly summary: {e}")
            return {"total_distance_km": 0, "total_duration_hours": 0, "activities_completed": 0}
            
    def generate_daily_summary(self):
        """Generate the daily summary file that agents will read"""
        logger.info("Generating daily summary...")
        
        # Get all data
        todays_activities = self.get_todays_activities()
        sleep = self.get_sleep_data()
        health = self.get_health_metrics()
        weekly = self.get_weekly_summary()
        
        # Build summary
        summary = {
            "date": date.today().isoformat(),
            "updated_at": datetime.utcnow().isoformat() + "Z",
            "todays_activities": todays_activities,
            "this_week": weekly,
            "health_metrics": {
                "sleep": sleep,
                "resting_hr": health.get('resting_hr'),
                "weight_kg": health.get('weight_kg')
            }
        }
        
        # Save to file
        summary_file = GARMIN_DATA / "daily_summary.json"
        with open(summary_file, 'w') as f:
            json.dump(summary, f, indent=2)
            
        logger.info(f"✓ Daily summary saved: {summary_file}")
        return summary
        
    def publish_alert(self):
        """Publish update notification to data bus"""
        data_bus_dir = PROJECT_ROOT / "data_bus" / "channels" / "data_alerts"
        data_bus_dir.mkdir(parents=True, exist_ok=True)
        
        alert = {
            "id": f"garmin_update_{int(time.time())}",
            "type": "garmin_data_updated",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "sender": "garmin_collector",
            "data": {
                "summary_file": "garmin_data/daily_summary.json",
                "message": "Garmin data has been updated"
            }
        }
        
        alert_file = data_bus_dir / f"{alert['id']}.json"
        with open(alert_file, 'w') as f:
            json.dump(alert, f, indent=2)
            
    def sync(self):
        """Main sync function"""
        logger.info("Starting Garmin sync...")
        
        if not self.authenticate():
            return False
            
        try:
            summary = self.generate_daily_summary()
            self.publish_alert()
            
            logger.info("✓ Sync complete!")
            logger.info(f"  Activities today: {len(summary['todays_activities'])}")
            logger.info(f"  This week: {summary['this_week']['total_distance_km']} km")
            
            return True
        except Exception as e:
            logger.error(f"Sync failed: {e}")
            return False


def main():
    """Main entry point"""
    collector = GarminCollector()
    success = collector.sync()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
