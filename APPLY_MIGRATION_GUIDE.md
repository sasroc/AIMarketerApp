# How to Apply Database Migration to Cloud Supabase

## Quick Setup (5 minutes)

### Step 1: Open Supabase Dashboard

1. Go to https://app.supabase.com
2. Select your project: **skuisuaymljmqlohcwem**
3. Click on **SQL Editor** in the left sidebar

### Step 2: Run the Migration SQL

1. Click **New Query**
2. Copy the entire contents of: `supabase/migrations/20241024000000_create_user_data_tables.sql`
3. Paste it into the SQL editor
4. Click **Run** (or press Cmd+Enter)

### Step 3: Verify Tables Were Created

1. Go to **Database** → **Tables** in the left sidebar
2. You should now see:
   - ✅ `media_items`
   - ✅ `campaigns`
   - ✅ `campaign_media_items`
   - ✅ `generated_posts`

### Step 4: Verify Storage Bucket

1. Go to **Storage** in the left sidebar
2. You should see:
   - ✅ `media-uploads` bucket

## ✅ That's It!

Now when you:
1. Create posts in the app
2. Sign out
3. Sign back in

Your posts will be there! 🎉

## Troubleshooting

### "Error: relation already exists"
- Tables are already created, you're good to go!

### "Error: permission denied"
- Make sure you're logged into the correct Supabase project
- Check you have admin access to the project

### "Can't find the SQL file"
- The file is at: `supabase/migrations/20241024000000_create_user_data_tables.sql`
- You can also find it in the GitHub repo

## Alternative: Link Project and Push (Advanced)

If you prefer using CLI:

```bash
# 1. Link your project
supabase link --project-ref skuisuaymljmqlohcwem

# 2. Enter your database password when prompted

# 3. Push migrations
supabase db push
```

---

**Need the SQL?** Open the file at: `supabase/migrations/20241024000000_create_user_data_tables.sql`

