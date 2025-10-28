# Instagram Integration - Changelog

## Version 1.0.0 - Instagram Auto-Publishing

### ✨ New Features

**Instagram OAuth Integration**
- Connect Instagram Business accounts via Facebook Login
- Long-lived access tokens (60 days, auto-renewable)
- Token expiration warnings in Profile view

**Automated Post Publishing**
- Schedule posts to publish automatically at specific times
- Cron-based publishing via Supabase Edge Functions
- Publishes images and videos to Instagram
- Automatic status updates (scheduled → posted)

**Real-Time Status Tracking**
- Auto-refresh post statuses every 30 seconds
- Pull-to-refresh for instant updates
- "Updated Xm ago" indicator
- Instagram post links and IDs

### 📱 New UI Components

- `InstagramAuthView` - OAuth authentication flow
- Instagram connection status in Profile
- Auto-refreshing Schedule view
- Post status filters (Scheduled, Posted, Failed)

### 🗄️ Database Changes

**New Tables:**
- `instagram_connections` - Store Instagram OAuth tokens and metadata

**New Columns (generated_posts):**
- `instagram_post_id` - Instagram media ID
- `instagram_permalink` - Link to published post
- `published_at` - Publication timestamp
- `error_message` - Publishing error details

**New Functions:**
- `get_posts_ready_for_publishing()` - Find scheduled posts to publish
- `update_post_after_publishing()` - Update post status after publishing

### 🔧 Backend

**Supabase Edge Functions:**
- `publish-scheduled-posts` - Publishes scheduled posts via Instagram Graph API
- Runs every 5 minutes via pg_cron
- Handles images and videos
- Error handling and retry logic

### 🛠️ Technical Improvements

- **UUID Comparison Fix**: All UUID comparisons now case-insensitive to prevent duplicates
- **Auto-Refresh**: Timer-based refresh with RunLoop integration
- **Logging Cleanup**: Removed verbose debug logs, kept only errors and status changes
- **Memory Efficiency**: Refresh only when Schedule view is active

### 📝 Models

**New:**
- `InstagramConnection` - Instagram OAuth data model

**Updated:**
- `GeneratedPost` - Added Instagram publishing fields
- `User` - Added Instagram connection status
- `DraftCampaign` - Basic structure (pre-existing)

### 🔑 Configuration

**Updated Files:**
- `Config.template.plist` - Added Facebook App ID/Secret placeholders
- `Info.plist` - Added custom URL schemes for OAuth
- `project.pbxproj` - Added new Swift files to Xcode project

### 📚 Documentation

- `INSTAGRAM_INTEGRATION_GUIDE.md` - Complete setup guide
- `QUICK_SETUP.md` - Quick reference for setup

### 🐛 Bug Fixes

- Fixed duplicate posts caused by UUID case sensitivity
- Fixed Timer not firing during scrolling (added to RunLoop with .common mode)
- Fixed status updates not reflecting in UI (added explicit objectWillChange)

### 🔐 Security

- Access tokens stored securely in Supabase
- RLS policies on instagram_connections table
- OAuth redirect via HTTPS localhost
- Service role key used only in Edge Functions

---

## Breaking Changes

None - This is a new feature addition.

## Migration Required

Yes - Run `supabase/migrations/20241026000000_add_instagram_integration.sql`

## Dependencies

- Supabase Swift SDK (existing)
- Facebook Graph API v18.0
- Instagram Graph API (Business accounts only)

---

## What's Next

Future enhancements:
- Multi-image carousel posts
- Instagram Stories support
- Analytics and insights
- Post scheduling calendar view
- Batch publishing
- Draft post editing

