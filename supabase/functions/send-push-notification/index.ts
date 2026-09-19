import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const expoPushEndpoint = "https://exp.host/--/api/v2/push/send";

serve(async (req: Request) => {
  try {
    const payload = await req.json();
    
    // Process only PUSH INSERT events from the notifications table
    if (payload.type !== 'INSERT' || payload.table !== 'notifications') {
      return new Response(JSON.stringify({ message: "Ignored event type or table" }), { status: 200 });
    }

    const notification = payload.record;

    if (notification.channel !== 'PUSH') {
      return new Response(JSON.stringify({ message: "Ignored non-PUSH notification" }), { status: 200 });
    }

    const targetUserId = notification.user_id;

    // If there is no target user_id, we can't find a push token
    if (!targetUserId) {
      return new Response(JSON.stringify({ message: "No target user_id provided" }), { status: 200 });
    }

    // Initialize Supabase admin client to bypass RLS
    // @ts-ignore: Deno is provided by the Supabase Edge Function environment
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    // @ts-ignore: Deno is provided by the Supabase Edge Function environment
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    
    const supabaseClient = createClient(
      supabaseUrl,
      supabaseKey
    );

    // Fetch active push tokens for the target user
    const { data: devices, error } = await supabaseClient
      .from('user_devices')
      .select('push_token')
      .eq('user_id', targetUserId)
      .eq('is_active', true)
      .not('push_token', 'is', null);

    if (error) {
      console.error('Error fetching devices:', error);
      throw error;
    }

    if (!devices || devices.length === 0) {
      return new Response(JSON.stringify({ message: "No active push tokens found for user" }), { status: 200 });
    }

    // Filter out invalid/empty tokens
    const validDevices = devices.filter((d: any) => d.push_token && d.push_token.trim() !== '');

    if (validDevices.length === 0) {
      return new Response(JSON.stringify({ message: "No valid push tokens found for user" }), { status: 200 });
    }

    // Prepare Expo push messages for all active devices
    const messages = validDevices.map((device: any) => ({
      to: device.push_token,
      sound: 'default',
      title: notification.title,
      body: notification.body,
      data: {
        notification_id: notification.id,
        reference_type: notification.reference_type,
        reference_id: notification.reference_id,
        metadata: notification.metadata,
      },
    }));

    // Send push notifications via Expo API
    const expoResponse = await fetch(expoPushEndpoint, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Accept-encoding': 'gzip, deflate',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(messages),
    });

    const expoResult = await expoResponse.json();
    console.log('Expo push result:', expoResult);

    return new Response(JSON.stringify({ message: "Push notifications processed", expoResult }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error: any) {
    console.error('Error sending push notification:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
