# Instagram Integration Setup Guide

This guide will walk you through setting up Instagram integration for the AI Marketer app, allowing users to schedule and automatically publish posts to their Instagram Business accounts.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Facebook App Setup](#facebook-app-setup)
4. [Configure the iOS App](#configure-the-ios-app)
5. [Database Migration](#database-migration)
6. [Deploy Edge Function](#deploy-edge-function)
7. [Testing the Integration](#testing-the-integration)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The Instagram integration consists of several components:

- **OAuth Authentication Flow**: Users authenticate via Facebook/Instagram OAuth
- **InstagramService**: Swift service handling all Instagram Graph API interactions
- **Database Layer**: Stores Instagram connection data and post publishing status
- **Edge Function**: Supabase Edge Function that runs on a schedule to publish posts
- **UI Components**: Instagram connection management in ProfileView

### Architecture

```
┌─────────────────┐
│   iOS App       │
│  (SwiftUI)      │
└────────┬────────┘
         │
         ├──► InstagramService (OAuth & API calls)
         │
         ├──► SupabaseService (Database)
         │
         └──► Supabase Edge Function
              (Scheduled Publishing)
```

---

## Prerequisites

Before you begin, ensure you have:

1. **Instagram Business Account**: The Instagram account must be converted to a Business account
2. **Facebook Page**: The Instagram Business account must be linked to a Facebook Page
3. **Facebook Developer Account**: Required to create a Facebook App
4. **Supabase Project**: Already set up (you have this)
5. **Publicly Accessible Media URLs**: Instagram requires public URLs for media (your Supabase storage handles this)

---

## Facebook App Setup

### Step 1: Create a Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **"My Apps"** → **"Create App"**
3. **IMPORTANT**: When asked to select a use case, choose **"Other"** or **"None"**
4. Select **"Business"** as the app type
5. Fill in the app details:
   - **App Name**: "AI Marketer" (or your preferred name)
   - **App Contact Email**: Your email
   - **Business Account**: Optional (but recommended)

### Step 2: Add Instagram Product

1. In your app dashboard, you should now see **"Products"** in the left sidebar
2. Click **"Add Product"** 
3. Find **"Instagram"** and click **"Set Up"**
4. This will add Instagram API capabilities to your app
5. You should now see **"Instagram"** in the left sidebar with options:
   - API setup with Instagram login
   - API integration helper
   - API setup with Facebook login

### Step 3: Get Your App Credentials

1. Go to **App settings** → **Basic**
2. Note your **App ID** and **App Secret** (click "Show" to reveal)
3. These are your `FacebookAppId` and `FacebookAppSecret` for Config.plist

### Step 4: Configure OAuth Redirect URIs

1. In the **Instagram** section (left sidebar), click **"API setup with Instagram login"**
2. Scroll down to find **OAuth Redirect URIs** or **Client OAuth Settings**
3. Add **Valid OAuth Redirect URIs**:
   - `aimarketer://instagram-auth`
4. If you don't see OAuth settings on this page, try:
   - **App settings** → **Basic** → Look for Instagram or OAuth section
   - Or it may be under **Instagram** → **Basic Display** settings
5. Save your changes

### Step 5: Request Permissions

For publishing to Instagram, you need these permissions:
- `instagram_basic`
- `instagram_content_publish`
- `pages_read_engagement`
- `pages_show_list`

**Note**: Some permissions require **App Review** by Facebook. For development and testing, you can add test users who don't require approval.

### Step 6: Add Test Users (For Development)

1. Go to **Roles** → **Test Users**
2. Add Instagram accounts as test users
3. Test users can authenticate without app review

### Step 7: Submit for App Review (For Production)

Before launching to real users:
1. Go to **App Review** → **Permissions and Features**
2. Request the required Instagram permissions
3. Provide detailed use case and screencast demonstration
4. Wait for Facebook's approval (usually 1-2 weeks)

---

## Configure the iOS App

### Step 1: Update Config.plist

1. Copy `Config.template.plist` to `Config.plist` (if not done already)
2. Add your Facebook credentials:

```xml
<key>FacebookAppId</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookAppSecret</key>
<string>YOUR_FACEBOOK_APP_SECRET</string>
```

### Step 2: Register URL Scheme

The app needs to handle the OAuth callback URL. Add this to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>aimarketer</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.aimarketer</string>
    </dict>
</array>
```

Or in Xcode:
1. Select your project in the navigator
2. Select your target
3. Go to **Info** tab
4. Expand **URL Types**
5. Click **+** to add a new URL Type
6. Set **Identifier**: `com.yourcompany.aimarketer`
7. Set **URL Schemes**: `aimarketer`

### Step 3: Update Info.plist for Queries

Add Facebook and Instagram to allowed URL schemes:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
    <string>fbauth2</string>
    <string>instagram</string>
</array>
```

---

## Database Migration

### Step 1: Apply the Migration

Run the Instagram integration migration:

```bash
cd supabase
supabase migration up
```

Or apply it manually in the Supabase dashboard:
1. Go to **SQL Editor**
2. Open the migration file: `supabase/migrations/20241026000000_add_instagram_integration.sql`
3. Execute the SQL

### Step 2: Verify Tables

Check that these tables were created:
- `instagram_connections`: Stores OAuth tokens and account info
- Updated `generated_posts`: Now includes Instagram post IDs and permalinks

### Step 3: Test Database Functions

Test the helper functions:
```sql
-- Should return posts ready to publish
SELECT * FROM get_posts_ready_for_publishing();
```

---

## Deploy Edge Function

### Step 1: Deploy the Function

Deploy the scheduled post publisher:

```bash
cd supabase
supabase functions deploy publish-scheduled-posts
```

### Step 2: Set Up Cron Job

The Edge Function needs to run periodically (e.g., every 5 minutes). Add this to your `supabase/config.toml`:

```toml
[[functions.publish-scheduled-posts.cron]]
  schedule = "*/5 * * * *"  # Every 5 minutes
```

Or set up a cron job via the Supabase dashboard:
1. Go to **Edge Functions**
2. Select `publish-scheduled-posts`
3. Click **"Triggers"**
4. Add a cron trigger: `*/5 * * * *`

### Step 3: Test the Function

Test manually via the dashboard or CLI:

```bash
supabase functions invoke publish-scheduled-posts
```

---

## Testing the Integration

### Test Plan

1. **OAuth Flow**:
   - Open the app
   - Go to Profile
   - Tap "Connect" on Instagram
   - Complete Facebook/Instagram OAuth
   - Verify connection shows your Instagram username

2. **Token Storage**:
   - Check the `instagram_connections` table
   - Verify token expiration is ~60 days in the future

3. **Create a Post**:
   - Create a campaign with media and caption
   - Schedule a post for a few minutes in the future
   - Mark the post as "scheduled"

4. **Verify Publishing**:
   - Wait for the cron job to run (or trigger manually)
   - Check your Instagram account for the post
   - Verify the post status updates to "posted" in the app
   - Check the `instagram_post_id` field is populated

### Testing with Test Accounts

For development, use Instagram test accounts:
1. Create a test Instagram Business account
2. Link it to a test Facebook Page
3. Add as a test user in your Facebook App
4. Test the full flow without needing app review

---

## Troubleshooting

### Common Issues

#### "No Instagram Business Account Found"

**Problem**: User's Instagram account is not a Business account or not linked to a Facebook Page.

**Solution**:
1. Convert Instagram account to Business:
   - Instagram app → Settings → Account → Switch to Professional Account
2. Link to Facebook Page:
   - Settings → Account → Linked Accounts → Facebook → Connect

#### "Token Expired"

**Problem**: Access token has expired (60 days).

**Solution**:
- Users need to reconnect their Instagram account
- The app shows a warning when token expires in < 7 days
- Implement automatic token refresh (optional enhancement)

#### "Media Processing Failed"

**Problem**: Instagram couldn't process the media URL.

**Solution**:
- Ensure media URLs are publicly accessible
- Check Supabase storage bucket is public
- Verify image format (JPEG/PNG) and size (< 8MB)
- Videos must be < 100MB and supported formats (MP4, MOV)

#### "Rate Limit Exceeded"

**Problem**: Too many API calls in a short time.

**Solution**:
- The Edge Function includes delays between posts
- Instagram has limits: ~25 API calls per hour per user
- Consider adding exponential backoff

#### "Publishing Failed: Invalid Caption"

**Problem**: Caption contains unsupported characters or is too long.

**Solution**:
- Instagram captions max 2,200 characters
- Limit hashtags to 30
- Avoid certain special characters

### Debugging Tips

1. **Check Edge Function Logs**:
   ```bash
   supabase functions logs publish-scheduled-posts
   ```

2. **Test Instagram API Manually**:
   Use the [Graph API Explorer](https://developers.facebook.com/tools/explorer/)

3. **Verify Token Validity**:
   ```bash
   curl "https://graph.facebook.com/v18.0/me?access_token=YOUR_TOKEN"
   ```

4. **Check Post Status**:
   ```sql
   SELECT * FROM generated_posts WHERE status = 'failed';
   ```

---

## Architecture Details

### Instagram Publishing Flow

```
1. User schedules post
   ↓
2. Post saved to DB with status="scheduled"
   ↓
3. Cron job triggers Edge Function (every 5 min)
   ↓
4. Function queries posts ready to publish
   ↓
5. For each post:
   a. Fetch user's Instagram connection
   b. Validate token
   c. Create media container (Instagram API)
   d. Wait for processing (videos only)
   e. Publish container (Instagram API)
   f. Update post status to "posted"
   ↓
6. Return results summary
```

### Media URL Requirements

Instagram requires media to be:
- **Publicly accessible** via HTTPS
- **Hosted on a permanent URL** (not temporary)
- **Proper format**: JPEG/PNG for images, MP4/MOV for videos
- **Size limits**: Images < 8MB, Videos < 100MB

Your Supabase storage meets all requirements if configured correctly.

### Token Management

- **Short-lived tokens**: 1 hour (initial OAuth)
- **Long-lived tokens**: 60 days (what we store)
- **Refresh**: Exchange long-lived token for new one before expiry
- **Storage**: Encrypted in `instagram_connections` table

---

## Next Steps

### Enhancements to Consider

1. **Automatic Token Refresh**: 
   - Create a cron job to refresh tokens before expiry
   - Update `updateInstagramConnectionToken()` logic

2. **Multi-Account Support**:
   - Allow users to connect multiple Instagram accounts
   - Update UI to select which account per campaign

3. **Carousel Posts**:
   - Support multiple images in one post
   - Update `InstagramService` for carousel API

4. **Stories Support**:
   - Add Instagram Stories publishing
   - Different API endpoints required

5. **Analytics Integration**:
   - Fetch post insights after publishing
   - Show engagement metrics in the app

6. **Retry Logic**:
   - Automatic retry for failed posts
   - Exponential backoff for rate limits

7. **Post Preview**:
   - Show Instagram preview before scheduling
   - Validate caption length and hashtags

---

## Security Considerations

1. **Never expose API keys** in client code
2. **Store tokens encrypted** in the database
3. **Use HTTPS** for all API calls
4. **Implement rate limiting** to prevent abuse
5. **Validate media URLs** before sending to Instagram
6. **Handle token expiration** gracefully
7. **Comply with Instagram policies** on automated posting

---

## Support & Resources

- [Instagram Graph API Documentation](https://developers.facebook.com/docs/instagram-api)
- [Facebook App Review Process](https://developers.facebook.com/docs/app-review)
- [Instagram Platform Policy](https://developers.facebook.com/docs/instagram-api/overview#instagram-platform-policy)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

---

## Summary

You now have a complete Instagram integration that allows:
- ✅ Users to connect their Instagram Business accounts
- ✅ OAuth authentication with long-lived tokens
- ✅ Scheduling posts with captions
- ✅ Automatic publishing via Edge Function
- ✅ Token expiration warnings
- ✅ Error handling and status tracking

The integration is production-ready once you complete Facebook App Review!

