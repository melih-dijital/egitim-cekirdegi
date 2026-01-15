// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!
const ONESIGNAL_REST_KEY = Deno.env.get('ONESIGNAL_REST_KEY')!

serve(async (req) => {
    try {
        const { record } = await req.json()
        // record is the row from 'notifications' table

        // Construct OneSignal payload
        const payload: any = {
            app_id: ONESIGNAL_APP_ID,
            contents: { en: record.message },
            headings: { en: record.title },
        }

        if (record.target_user_id) {
            // Individual targeting by external_user_id (which is user_id in Auth)
            payload.include_external_user_ids = [record.target_user_id]
        } else if (record.target_segment) {
            // Segment targeting (e.g. 'Teachers')
            payload.included_segments = [record.target_segment]
        } else if (record.target_tags) {
            // Custom Tag targeting (assuming tags stored as JSON in target_tags)
            // e.g. [{"key": "school_id", "relation": "=", "value": "xyz"}]
            payload.tags = record.target_tags
        } else {
            // Default to All if no target specified? Or specific segment
            payload.included_segments = ['All']
        }

        // Schedule
        if (record.send_at) {
            payload.send_after = record.send_at
        }

        console.log("Sending Notification:", JSON.stringify(payload))

        const response = await fetch("https://onesignal.com/api/v1/notifications", {
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": `Basic ${ONESIGNAL_REST_KEY}`,
            },
            body: JSON.stringify(payload),
        })

        const result = await response.json()
        console.log("OneSignal Result:", result)

        // Ideally update the row status in DB to 'sent' or 'failed' here using Supabase Client

        return new Response(
            JSON.stringify(result),
            { headers: { "Content-Type": "application/json" } },
        )
    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { headers: { "Content-Type": "application/json" }, status: 400 },
        )
    }
})
