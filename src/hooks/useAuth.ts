import { useEffect } from 'react';
import { useAuthStore } from '../store/authStore';
import { authService } from '../services/auth';
import { supabase } from '../services/supabase';

export const useAuth = () => {
  const user = useAuthStore((state) => state.user);
  const isLoading = useAuthStore((state) => state.isLoading);
  const error = useAuthStore((state) => state.error);
  const setUser = useAuthStore((state) => state.setUser);
  const setTokens = useAuthStore((state) => state.setTokens);
  const setLoading = useAuthStore((state) => state.setLoading);
  const setError = useAuthStore((state) => state.setError);
  const clearAuth = useAuthStore((state) => state.clearAuth);

  const login = async (email: string, password: string) => {
    setLoading(true);
    setError(null);
    try {
      const session = await authService.loginWithEmail(email, password);
      setUser(session.user);
      setTokens(session.accessToken, session.refreshToken);
      setLoading(false);
    } catch (err: any) {
      setError(err.message || 'Failed to sign in');
      setLoading(false);
      throw err;
    }
  };

  const signup = async (
    email: string,
    password: string,
    firstName: string,
    lastName: string
  ) => {
    setLoading(true);
    setError(null);
    try {
      await authService.signupWithEmail(email, password, firstName, lastName);
      setLoading(false);
    } catch (err: any) {
      setError(err.message || 'Failed to sign up');
      setLoading(false);
      throw err;
    }
  };

  const logout = async () => {
    setLoading(true);
    setError(null);
    try {
      await authService.logout();
      clearAuth();
      setLoading(false);
    } catch (err: any) {
      setError(err.message || 'Failed to sign out');
      setLoading(false);
      throw err;
    }
  };

  const loadSession = async () => {
    setLoading(true);
    try {
      const session = await authService.getCurrentSession();
      if (session) {
        setUser(session.user);
        setTokens(session.accessToken, session.refreshToken);
      } else {
        clearAuth();
      }
    } catch (err) {
      clearAuth();
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSession();
  }, []);

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event: string, session: any) => {
        if (event === 'SIGNED_IN' && session) {
          const fullSession = await authService.getCurrentSession();
          if (fullSession) {
            setUser(fullSession.user);
            setTokens(fullSession.accessToken, fullSession.refreshToken);
          }
        } else if (event === 'SIGNED_OUT') {
          clearAuth();
        }
      }
    );

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  return {
    user,
    isLoading,
    error,
    login,
    signup,
    logout,
  };
};
export default useAuth;
