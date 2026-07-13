import { Platform } from 'react-native';

export const SUPABASE_URL = 'https://qacszvarjbfltmefsavd.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFhY3N6dmFyamJmbHRtZWZzYXZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyNjc0ODgsImV4cCI6MjA3ODg0MzQ4OH0.WnTnuK-Bu1-abjM4RYm3n1AECHQmdi2J-NTnayV-cqA';

// For local development with Next.js dashboard
// Android emulator uses 10.0.2.2, iOS simulator uses localhost
export const API_URL = Platform.select({
  android: 'http://10.0.2.2:3000/api',
  ios: 'http://localhost:3000/api',
  default: 'http://localhost:3000/api',
});

export const APP_VERSION = '1.0.0';
export const STORAGE_KEYS = {
  SESSION: 'syncflo_session',
  USER: 'syncflo_user',
  THEME: 'syncflo_theme',
};
