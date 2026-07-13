import { apiClient } from './api';
import { supabase } from './supabase';

export const pushDeviceTokensService = {
  async registerDeviceToken(
    token: string,
    platform: 'ios' | 'android'
  ): Promise<boolean> {
    try {
      await apiClient.post('/device-tokens/register', { token, platform });
      return true;
    } catch (apiErr) {
      try {
        const { data: userData } = await supabase.auth.getUser();
        if (!userData.user) return false;

        const { error } = await supabase.from('push_tokens').upsert(
          {
            user_id: userData.user.id,
            token,
            platform,
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'user_id' }
        );
        return !error;
      } catch {
        return false;
      }
    }
  },

  async unregisterDeviceToken(token: string): Promise<boolean> {
    try {
      await apiClient.post('/device-tokens/unregister', { token });
      return true;
    } catch (apiErr) {
      try {
        const { error } = await supabase
          .from('push_tokens')
          .delete()
          .eq('token', token);
        return !error;
      } catch {
        return false;
      }
    }
  },
};
export default pushDeviceTokensService;
