# Data Persistence Guide

## Overview

The AI Marketer App now includes comprehensive data persistence using Supabase. All user data including media uploads, draft campaigns, and generated posts are automatically saved and synchronized across devices.

## Features

### 🔐 Secure Storage
- All data is protected with Row Level Security (RLS)
- Users can only access their own data
- Automatic user authentication integration

### 💾 What's Saved

1. **Media Items**
   - Photos and videos uploaded by users
   - Stored in Supabase Storage (`media-uploads` bucket)
   - Metadata stored in database

2. **Draft Campaigns**
   - Marketing plans
   - Posting schedules
   - Content guidelines
   - Associated media items
   - Current progress/step

3. **Generated Posts**
   - AI-generated captions
   - Scheduled dates
   - Post status (pending, draft, scheduled, posted, failed)
   - Links to media items

### 🔄 Automatic Synchronization

Data is automatically:
- **Loaded** when the user signs in or app launches
- **Saved** when the user creates or modifies content
- **Synced** across all devices signed in with the same account
- **Deleted** when the user removes items

## Setup Instructions

### 1. Apply Database Migrations

Before using the app, you need to set up the database schema:

```bash
# From the project root directory
./apply-migrations.sh
```

This will create all necessary tables and storage buckets in your Supabase instance.

### 2. Verify Setup

After running migrations, you can verify the setup in your Supabase dashboard:

1. Go to https://app.supabase.com
2. Select your project
3. Navigate to "Database" → "Tables"
4. You should see:
   - `media_items`
   - `campaigns`
   - `campaign_media_items`
   - `generated_posts`

## Usage

### For Users

**Everything happens automatically!** Users don't need to do anything special:

1. **Sign In** - Data loads automatically
2. **Create Content** - Saves automatically as you work
3. **Sign Out** - Data persists and will be available next time
4. **Switch Devices** - All data syncs across devices

### For Developers

#### Loading Data

Data is automatically loaded when `CampaignViewModel` initializes:

```swift
// In CampaignViewModel init()
Task {
    await loadUserData()
}
```

This fetches:
- All draft campaigns for the user
- All generated posts for the user

#### Saving Data

Data is saved automatically when:

1. **Media is added**: Uploads to storage and saves metadata
   ```swift
   func addMediaItem(_ item: MediaItem)
   ```

2. **Posts are generated**: Saves all posts to database
   ```swift
   func generatePosts() async
   ```

3. **Captions are edited**: Updates post in database
   ```swift
   func updatePostCaption(postId: String, newCaption: String)
   ```

4. **Campaigns are drafted**: Saves complete campaign
   ```swift
   func saveDraft()
   ```

5. **Auto-save**: Periodically saves work in progress
   ```swift
   func autoSaveCampaign() async
   ```

#### Manual Operations

You can also manually trigger operations:

```swift
// Load all user data
await viewModel.loadUserData()

// Save current campaign as draft
viewModel.saveDraft()

// Auto-save without resetting
await viewModel.autoSaveCampaign()

// Delete a post
viewModel.deletePost(post)

// Delete a draft campaign
viewModel.deleteDraft(campaign)
```

## Database Schema

### media_items
Stores metadata for uploaded media files.

```sql
- id: UUID (primary key)
- user_id: UUID (foreign key to auth.users)
- type: text ('image' or 'video')
- cloud_url: text (URL in Supabase Storage)
- created_at: timestamp
```

### campaigns
Stores draft campaigns with all their settings.

```sql
- id: UUID (primary key)
- user_id: UUID (foreign key to auth.users)
- marketing_description: text
- target_audience: text
- tone: text
- hashtags: jsonb (array of strings)
- call_to_action: text
- schedule_start_date: timestamp
- schedule_end_date: timestamp
- selected_days: jsonb (array of integers)
- post_times: jsonb (object)
- posts_per_day: jsonb (object)
- content_guidelines: text
- current_step: integer
- is_draft: boolean
- updated_at: timestamp
- created_at: timestamp
```

### campaign_media_items
Junction table linking campaigns to media items.

```sql
- id: UUID (primary key)
- campaign_id: UUID (foreign key to campaigns)
- media_item_id: UUID (foreign key to media_items)
- position: integer (order in the campaign)
- created_at: timestamp
```

### generated_posts
Stores all generated posts with their captions and schedules.

```sql
- id: UUID (primary key)
- user_id: UUID (foreign key to auth.users)
- campaign_id: UUID (foreign key to campaigns, nullable)
- media_item_id: UUID (foreign key to media_items, nullable)
- caption: text
- scheduled_date: timestamp
- status: text ('pending', 'draft', 'scheduled', 'posted', 'failed')
- created_at: timestamp
- updated_at: timestamp
```

## Storage Structure

Media files are organized in Supabase Storage:

```
media-uploads/
└── {user_id}/
    ├── {media_id}.jpg
    ├── {media_id}.mp4
    └── ...
```

Each user has their own folder identified by their user ID, ensuring complete isolation.

## Security

### Row Level Security (RLS)

All tables have RLS enabled with policies that ensure:
- Users can only read their own data
- Users can only insert data for themselves
- Users can only update their own data
- Users can only delete their own data

### Storage Security

The `media-uploads` bucket is private with policies that:
- Allow users to upload to their own folder
- Allow users to view their own files
- Prevent access to other users' files

## API Reference

### SupabaseService Methods

#### Media Operations
```swift
// Save a media item to the database
func saveMediaItem(_ item: MediaItem) async throws -> MediaItem

// Fetch all media items for current user
func fetchMediaItems() async throws -> [MediaItem]

// Delete a media item
func deleteMediaItem(_ id: String) async throws

// Upload media file to storage
func uploadMedia(data: Data, fileName: String, contentType: String) async throws -> String

// Download media file from storage
func downloadMedia(url: String) async throws -> Data
```

#### Campaign Operations
```swift
// Save or update a campaign
func saveCampaign(_ campaign: DraftCampaign) async throws -> DraftCampaign

// Fetch all campaigns for current user
func fetchCampaigns() async throws -> [DraftCampaign]

// Delete a campaign
func deleteCampaign(_ id: String) async throws
```

#### Post Operations
```swift
// Save a single post
func saveGeneratedPost(_ post: GeneratedPost, campaignId: String?) async throws -> GeneratedPost

// Save multiple posts
func saveGeneratedPosts(_ posts: [GeneratedPost], campaignId: String?) async throws

// Fetch posts (optionally filtered by status)
func fetchGeneratedPosts(status: PostStatus? = nil) async throws -> [GeneratedPost]

// Update post status
func updatePostStatus(_ postId: String, status: PostStatus) async throws

// Delete a post
func deleteGeneratedPost(_ id: String) async throws
```

## Troubleshooting

### Data Not Loading

1. Check authentication status:
   ```swift
   print(SupabaseService.shared.client.auth.session)
   ```

2. Verify migrations were applied:
   - Check Supabase dashboard for tables
   - Run `./apply-migrations.sh` again if needed

3. Check RLS policies:
   - Go to Supabase Dashboard → Authentication → Policies
   - Ensure policies exist for all tables

### Upload Failures

1. Check storage bucket exists:
   - Go to Supabase Dashboard → Storage
   - Verify `media-uploads` bucket is created

2. Check file size limits:
   - Default limit is 50MB (configurable in `config.toml`)

3. Verify storage policies:
   - Ensure user has permission to upload to their folder

### Performance Issues

1. For large datasets, consider pagination:
   ```swift
   // Add .range(from: 0, to: 50) to queries
   let response = try await supabase.database
       .from("generated_posts")
       .select()
       .range(from: 0, to: 50)
       .execute()
   ```

2. Use indexes (already created in migration):
   - `user_id` on all user-related tables
   - `scheduled_date` on posts
   - `status` on posts

## Future Enhancements

Potential improvements for data persistence:

1. **Offline Support**: Cache data locally with CoreData/Realm
2. **Conflict Resolution**: Handle simultaneous edits from multiple devices
3. **Real-time Sync**: Use Supabase Realtime for live updates
4. **Backup/Export**: Allow users to download their data
5. **Pagination**: Implement pagination for large datasets
6. **Search**: Add full-text search for posts and campaigns

## Support

For issues or questions:
1. Check Supabase logs in the dashboard
2. Review error messages in the app
3. Consult the main README.md for general setup
4. Check SUPABASE_SETUP.md for Supabase configuration

