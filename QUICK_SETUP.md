# 🚀 Quick Setup - Get Auto-Posting Working NOW!

## ⚡️ 5-Minute Setup

### Step 1: Enable Auto-Publishing (2 minutes)

**Go to Supabase SQL Editor:**  
https://supabase.com/dashboard/project/skuisuaymljmqlohcwem/sql

**Copy & Run This:**

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

SELECT cron.unschedule('publish-instagram-posts');

SELECT cron.schedule(
  'publish-instagram-posts',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://skuisuaymljmqlohcwem.supabase.co/functions/v1/publish-scheduled-posts',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNrdWlzdWF5bWxqbXFsb2hjd2VtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExNDA0MzUsImV4cCI6MjA3NjcxNjQzNX0.xXGCFZdvKyx3LT5aLLBkF9z1-6D-dluMQBgCFrtfQc8'
    )
  ) AS request_id;
  $$
);
```

**Verify it worked:**

```sql
SELECT jobname, schedule, active 
FROM cron.job 
WHERE jobname = 'publish-instagram-posts';
```

✅ You should see: `publish-instagram-posts | */5 * * * * | t`

---

### Step 2: Rebuild Your App (2 minutes)

The app now has **auto-refresh** built in!

1. **In Xcode**, press **⌘ + B** to build
2. Run the app on your device/simulator
3. Done! 🎉

---

### Step 3: Test It! (3 minutes)

1. **Open app** → **Home** → **Create Campaign**
2. **Upload an image**
3. **Generate posts**
4. **Schedule a post for 2 minutes from now**
5. **Go to Schedule tab**
6. **Wait 5-7 minutes** and watch it change to "Posted"
7. **Check Instagram** - it's live! 🚀

---

## 🎯 What You'll See in the App

### Schedule Tab Now Has:

✅ **Auto-refresh every 30 seconds** - Statuses update automatically  
✅ **Pull-to-refresh** - Swipe down for instant update  
✅ **"Updated Xm ago"** - See when last checked  
✅ **Real-time status** - Watch "scheduled" → "posted"  

---

## 🔥 That's It!

**You're done!** Your app now:
- ✅ Automatically publishes scheduled posts to Instagram
- ✅ Updates post status in real-time
- ✅ Shows when posts were published
- ✅ Links to Instagram posts

**Full documentation:** See `INSTAGRAM_AUTO_POSTING_COMPLETE.md`

---

## 🆘 Quick Troubleshooting

### Posts not publishing?

```sql
-- Check cron is running
SELECT start_time, status 
FROM cron.job_run_details
WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname = 'publish-instagram-posts')
ORDER BY start_time DESC
LIMIT 5;
```

### App not updating?

- Pull down to refresh
- Close and reopen Schedule tab
- Check "Updated Xm ago" is recent

### Still stuck?

Check Edge Function logs:  
https://supabase.com/dashboard/project/skuisuaymljmqlohcwem/functions

---

**Enjoy your automated Instagram marketing!** 🎉

