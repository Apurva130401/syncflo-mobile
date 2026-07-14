import AsyncStorage from '@react-native-async-storage/async-storage';
import { supabase } from './supabase';
import { AuthSession, User } from '../types';

export const authService = {
  async loginWithEmail(email: string, password: string): Promise<AuthSession> {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;
    if (!data.session || !data.user) {
      throw new Error('Invalid session or user payload received.');
    }

    const fullName = data.user.user_metadata?.full_name || '';
    const parts = fullName.split(' ');
    const firstName = parts[0] || '';
    const lastName = parts.slice(1).join(' ') || '';

    const sessionUser: User = {
      id: data.user.id,
      email: data.user.email || '',
      firstName,
      lastName,
      role: data.user.user_metadata?.role || 'agent',
      permissions: data.user.user_metadata?.permissions || [],
      phone: data.user.user_metadata?.phone || '',
    };

    // Store in AsyncStorage
    await AsyncStorage.setItem('syncflo_session', JSON.stringify(data.session));
    await AsyncStorage.setItem('syncflo_user', JSON.stringify(sessionUser));

    return {
      user: sessionUser,
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresAt: data.session.expires_at,
    };
  },

  async signupWithEmail(
    email: string,
    password: string,
    firstName: string,
    lastName: string
  ): Promise<void> {
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: `${firstName} ${lastName}`.trim(),
        },
      },
    });

    if (error) throw error;
  },

  async logout(): Promise<void> {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;

    await AsyncStorage.removeItem('syncflo_session');
    await AsyncStorage.removeItem('syncflo_user');
  },

  async getCurrentSession(): Promise<AuthSession | null> {
    try {
      const { data: { session }, error: sessionError } = await supabase.auth.getSession();
      if (sessionError || !session || !session.user) {
        // Fallback to AsyncStorage recovery
        const savedSession = await AsyncStorage.getItem('syncflo_session');
        const savedUser = await AsyncStorage.getItem('syncflo_user');
        if (savedSession && savedUser) {
          const parsedSession = JSON.parse(savedSession);
          const parsedUser = JSON.parse(savedUser);
          return {
            user: parsedUser,
            accessToken: parsedSession.access_token,
            refreshToken: parsedSession.refresh_token,
            expiresAt: parsedSession.expires_at,
          };
        }
        return null;
      }

      const fullName = session.user.user_metadata?.full_name || '';
      const parts = fullName.split(' ');
      const firstName = parts[0] || '';
      const lastName = parts.slice(1).join(' ') || '';

      const sessionUser: User = {
        id: session.user.id,
        email: session.user.email || '',
        firstName,
        lastName,
        role: session.user.user_metadata?.role || 'agent',
        permissions: session.user.user_metadata?.permissions || [],
        phone: session.user.user_metadata?.phone || '',
      };

      return {
        user: sessionUser,
        accessToken: session.access_token,
        refreshToken: session.refresh_token,
        expiresAt: session.expires_at,
      };
    } catch {
      return null;
    }
  },

  async refreshSession(): Promise<AuthSession | null> {
    const { data, error } = await supabase.auth.refreshSession();
    if (error || !data.session || !data.user) return null;

    const fullName = data.user.user_metadata?.full_name || '';
    const parts = fullName.split(' ');
    const firstName = parts[0] || '';
    const lastName = parts.slice(1).join(' ') || '';

    const sessionUser: User = {
      id: data.user.id,
      email: data.user.email || '',
      firstName,
      lastName,
      role: data.user.user_metadata?.role || 'agent',
      permissions: data.user.user_metadata?.permissions || [],
      phone: data.user.user_metadata?.phone || '',
    };

    await AsyncStorage.setItem('syncflo_session', JSON.stringify(data.session));
    await AsyncStorage.setItem('syncflo_user', JSON.stringify(sessionUser));

    return {
      user: sessionUser,
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresAt: data.session.expires_at,
    };
  },
};
export default authService;
