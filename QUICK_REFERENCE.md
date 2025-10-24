# Quick Reference Guide

## Common Tasks

### Setting Up Data Persistence

```bash
# 1. Ensure Supabase is configured
# Check that Config.plist has your SupabaseURL and SupabaseKey

# 2. Apply database migrations
./apply-migrations.sh

# 3. Verify in Supabase Dashboard
# - Go to https://app.supabase.com
# - Check Database → Tables for: media_items, campaigns, generated_posts
# - Check Storage for: media-uploads bucket
```

### User Authentication Flow

```swift
// Sign Up
await authViewModel.signUp(email: email, password: password, name: name)

// Sign In
await authViewModel.signIn(email: email, password: password)

// Sign Out
await authViewModel.signOut()
```

### Working with Campaigns

```swift
// Load all user data (campaigns and posts)
await campaignViewModel.loadUserData()

// Create a new campaign
campaignViewModel.mediaItems = [...]
campaignViewModel.marketingPlan = MarketingPlan(...)
campaignViewModel.schedule = PostSchedule(...)

// Auto-save current work
await campaignViewModel.autoSaveCampaign()

// Save as draft and reset
campaignViewModel.saveDraft()

// Load existing draft
campaignViewModel.loadDraft(draft)

// Delete draft
campaignViewModel.deleteDraft(draft)
```

### Managing Media

```swift
// Add media item (automatically uploads)
campaignViewModel.addMediaItem(mediaItem)

// Remove media item (automatically deletes)
campaignViewModel.removeMediaItem(mediaItem)
```

### Generating Posts

```swift
// Generate posts with AI
await campaignViewModel.generatePosts()

// Update a post caption
campaignViewModel.updatePostCaption(postId: id, newCaption: caption)

// Schedule all posts
campaignViewModel.scheduleAllPosts()

// Delete a post
campaignViewModel.deletePost(post)
```

### Direct Database Operations

```swift
let supabase = SupabaseService.shared

// Fetch all campaigns
let campaigns = try await supabase.fetchCampaigns()

// Fetch scheduled posts
let scheduledPosts = try await supabase.fetchGeneratedPosts(status: .scheduled)

// Update post status
try await supabase.updatePostStatus(postId, status: .posted)

// Upload media
let url = try await supabase.uploadMedia(
    data: imageData,
    fileName: "photo.jpg",
    contentType: "image/jpeg"
)
```

## Database Schema Quick Reference

### Tables

**media_items**
- `id` - UUID
- `user_id` - UUID (FK to auth.users)
- `type` - 'image' | 'video'
- `cloud_url` - Storage URL
- `created_at` - Timestamp

**campaigns**
- `id` - UUID
- `user_id` - UUID (FK to auth.users)
- `marketing_description` - Text
- `target_audience` - Text
- `tone` - Text
- `hashtags` - JSONB array
- `call_to_action` - Text
- `schedule_*` - Schedule fields
- `is_draft` - Boolean
- `current_step` - Integer
- `updated_at` - Timestamp

**generated_posts**
- `id` - UUID
- `user_id` - UUID (FK to auth.users)
- `campaign_id` - UUID (FK to campaigns)
- `media_item_id` - UUID (FK to media_items)
- `caption` - Text
- `scheduled_date` - Timestamp
- `status` - 'pending' | 'draft' | 'scheduled' | 'posted' | 'failed'
- `created_at` - Timestamp
- `updated_at` - Timestamp

## Post Status Values

```swift
enum PostStatus: String {
    case pending = "Pending"      // Generated but not reviewed
    case draft = "Draft"          // Being edited
    case scheduled = "Scheduled"  // Ready to post
    case posted = "Posted"        // Successfully posted
    case failed = "Failed"        // Post attempt failed
}
```

## Content Tone Options

```swift
enum ContentTone: String {
    case professional = "Professional"
    case casual = "Casual"
    case energetic = "Energetic"
    case friendly = "Friendly"
    case inspirational = "Inspirational"
}
```

## Useful Supabase Queries

### Get posts for a specific date range
```swift
let posts: [DatabaseGeneratedPost] = try await supabase.client.database
    .from("generated_posts")
    .select()
    .eq("user_id", value: userId)
    .gte("scheduled_date", value: startDate.ISO8601Format())
    .lte("scheduled_date", value: endDate.ISO8601Format())
    .order("scheduled_date", ascending: true)
    .execute()
    .value
```

### Count posts by status
```swift
let count = try await supabase.client.database
    .from("generated_posts")
    .select("*", head: true, count: .exact)
    .eq("user_id", value: userId)
    .eq("status", value: "scheduled")
    .execute()
    .count
```

### Get campaigns updated in last 7 days
```swift
let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

let recentCampaigns: [DatabaseCampaign] = try await supabase.client.database
    .from("campaigns")
    .select()
    .eq("user_id", value: userId)
    .gte("updated_at", value: sevenDaysAgo.ISO8601Format())
    .order("updated_at", ascending: false)
    .execute()
    .value
```

## Error Handling

### Common Errors

**SupabaseError.notAuthenticated**
- User is not signed in
- Session has expired
- Solution: Redirect to login

**Upload failures**
- Check file size (max 50MB by default)
- Verify storage bucket exists
- Check user has permission

**RLS policy violations**
- User trying to access another user's data
- Check user_id matches auth.uid()

### Debugging Tips

```swift
// Check current session
do {
    let session = try supabase.client.auth.session
    print("User ID: \(session.user.id)")
} catch {
    print("Not authenticated: \(error)")
}

// Enable Supabase logging (development only)
// Add to SupabaseService init:
// supabase.database.logLevel = .debug
```

## Performance Tips

1. **Pagination**: Use `.range(from:to:)` for large datasets
2. **Selective fetching**: Only fetch fields you need with `.select("id,caption")`
3. **Caching**: Store frequently accessed data locally
4. **Batch operations**: Group multiple saves/updates together
5. **Indexes**: Already created on user_id, status, scheduled_date

## Testing

### Test User Flow

1. Create test account in Supabase dashboard
2. Sign in with test credentials
3. Create sample campaign
4. Verify data appears in database tables
5. Sign out and sign back in
6. Verify data persists

### Clear Test Data

```sql
-- Run in Supabase SQL Editor
DELETE FROM generated_posts WHERE user_id = 'test-user-uuid';
DELETE FROM campaign_media_items WHERE campaign_id IN (
    SELECT id FROM campaigns WHERE user_id = 'test-user-uuid'
);
DELETE FROM campaigns WHERE user_id = 'test-user-uuid';
DELETE FROM media_items WHERE user_id = 'test-user-uuid';
```

## Security Best Practices

1. ✅ RLS is enabled on all tables
2. ✅ Storage policies restrict to user folders
3. ✅ Never expose Supabase anon key in public repos
4. ✅ Use service role key only for admin tasks (backend)
5. ⚠️ Always validate user input before saving
6. ⚠️ Implement rate limiting for uploads
7. ⚠️ Sanitize user-generated content

## Support & Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Swift Supabase Client](https://github.com/supabase-community/supabase-swift)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Storage Documentation](https://supabase.com/docs/guides/storage)

For app-specific issues, see:
- [DATA_PERSISTENCE.md](DATA_PERSISTENCE.md) - Detailed persistence documentation
- [SUPABASE_SETUP.md](SUPABASE_SETUP.md) - Supabase configuration
- [README.md](README.md) - General app information

