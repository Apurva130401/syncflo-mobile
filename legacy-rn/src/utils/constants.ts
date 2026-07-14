import { Platform } from 'react-native';

export const SUPABASE_URL = 'https://qacszvarjbfltmefsavd.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFhY3N6dmFyamJmbHRtZWZzYXZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyNjc0ODgsImV4cCI6MjA3ODg0MzQ4OH0.WnTnuK-Bu1-abjM4RYm3n1AECHQmdi2J-NTnayV-cqA';

// Use production API for APK builds so it works on physical devices
export const API_URL = 'https://dashboard.syncflo.xyz/api';

export const APP_VERSION = '1.0.0';
export const STORAGE_KEYS = {
  SESSION: 'syncflo_session',
  USER: 'syncflo_user',
  THEME: 'syncflo_theme',
};
