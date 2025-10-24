# Data Persistence Quick Start

## 🚀 Get Started in 3 Steps

### Step 1: Apply Database Migrations

```bash
cd /path/to/AIMarketerApp
./apply-migrations.sh
```

This creates all necessary tables and storage buckets in your Supabase instance.

### Step 2: Verify Setup

1. Open [Supabase Dashboard](https://app.supabase.com)
2. Go to **Database → Tables**
3. Confirm you see:
   - ✅ `media_items`
   - ✅ `campaigns`
   - ✅ `campaign_media_items`
   - ✅ `generated_posts`
4. Go to **Storage → Buckets**
5. Confirm you see:
   - ✅ `media-uploads`

### Step 3: Build and Run

```bash
# Open in Xcode
open AIMarketerApp.xcodeproj

# Or build from command line
xcodebuild -project AIMarketerApp.xcodeproj -scheme AIMarketerApp build
```

## ✨ What You Get

### Automatic Features
All these happen automatically without any code changes needed:

- 💾 **Data persists** when you sign out and back in
- 📱 **Cross-device sync** - access your data from any device
- 🔐 **Secure storage** - only you can access your data
- ☁️ **Cloud backup** - your media is safely stored in Supabase
- 🔄 **Real-time saves** - changes saved as you work

### User Experience

#### Before (Without Persistence)
```
1. Create campaign → ✅ Works
2. Sign out → ❌ Data lost
3. Sign back in → ❌ Campaign gone
```

#### After (With Persistence)
```
1. Create campaign → ✅ Saved automatically
2. Sign out → ✅ Data persists
3. Sign back in → ✅ Campaign restored!
4. Open on iPad → ✅ Same data available!
```

## 📊 Data That's Saved

### ✅ Automatically Saved
- [x] Uploaded photos and videos
- [x] Marketing plans and descriptions
- [x] Posting schedules and times
- [x] Generated post captions
- [x] Post status (draft, scheduled, posted)
- [x] Draft campaigns
- [x] Content guidelines

### ❌ Not Saved (By Design)
- [ ] Temporary UI state (current step in wizard)
- [ ] In-progress uploads (will retry on next launch)
- [ ] Unfinished text input (save draft first)

## 🧪 Test It Out

### Test Plan

1. **Create a campaign**
   - Sign in
   - Upload a photo
   - Create a marketing plan
   - Generate some posts
   - Save as draft

2. **Verify persistence**
   - Sign out
   - Sign back in
   - Check that your campaign is there ✅

3. **Test cross-device**
   - Sign in on another device/simulator
   - Verify you see the same campaign ✅

## 🔍 Troubleshooting

### "No data after sign in"

**Check:**
1. Did you run `./apply-migrations.sh`?
2. Is Config.plist set up with correct Supabase credentials?
3. Are you signing in with the same account?

**Fix:**
```bash
# Verify tables exist
supabase db pull

# Check Supabase dashboard
# Go to Authentication → Users → verify user exists
```

### "Upload failed"

**Check:**
1. Is the media-uploads bucket created?
2. Are storage policies set up correctly?
3. Is the file size under 50MB?

**Fix:**
- Check Supabase Dashboard → Storage
- Verify bucket "media-uploads" exists
- Check file size: `ls -lh your-file.jpg`

### "Data appears then disappears"

**Possible causes:**
1. RLS policies blocking access
2. User ID mismatch
3. Network connectivity issues

**Fix:**
```swift
// Add debug logging in SupabaseService
print("Current user ID: \(try? await getCurrentUserId())")
```

## 📚 Learn More

- **Detailed docs:** [DATA_PERSISTENCE.md](DATA_PERSISTENCE.md)
- **Quick reference:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Implementation details:** [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)

## 💡 Pro Tips

### Tip 1: Auto-Save
The app auto-saves as you work. No need to manually save every change!

### Tip 2: Draft Campaigns
Use "Save Draft" to safely store incomplete campaigns and continue later.

### Tip 3: Multiple Devices
Work on your iPhone, continue on iPad - everything syncs automatically.

### Tip 4: Offline Tolerance
If you lose connection, data saves when you reconnect (future enhancement).

## 🎯 Common Use Cases

### Use Case 1: Weekly Content Creator
```
Monday:
- Upload this week's photos
- Create marketing plan
- Save as draft

Tuesday:
- Open draft
- Generate posts
- Review and edit

Wednesday:
- Schedule all posts
- Posts auto-save as "scheduled"
```

### Use Case 2: Agency Managing Clients
```
Client A:
- Sign in as client A
- Create their campaigns
- All data isolated

Client B:
- Sign in as client B
- Separate data, secure and isolated
```

### Use Case 3: Team Collaboration (Future)
```
User 1:
- Creates initial campaign
- Shares with team

User 2:
- Reviews and edits
- Adds more posts

User 3:
- Final approval
- Schedules posts
```

## 🚨 Important Notes

### Security
- ✅ All data is private to your account
- ✅ Row Level Security prevents data leaks
- ✅ Media files are in user-specific folders

### Limits
- 📦 50MB max file size (configurable)
- 📊 1000 rows per query (paginate for more)
- 💾 Storage quota depends on Supabase plan

### Performance
- ⚡ Indexed queries for fast retrieval
- 🔄 Efficient batch operations
- 📱 Optimized for mobile networks

## ✅ Checklist

Before deploying to production:

- [ ] Run `./apply-migrations.sh` successfully
- [ ] Test sign up → create data → sign out → sign in
- [ ] Verify data appears after sign-in
- [ ] Test on multiple simulators/devices
- [ ] Check Supabase dashboard shows data
- [ ] Verify RLS policies work (can't see other users' data)
- [ ] Test upload of photo and video
- [ ] Test all CRUD operations
- [ ] Review error handling
- [ ] Check UI loading states

## 🎉 Success!

If you can:
1. ✅ Create a campaign
2. ✅ Sign out
3. ✅ Sign back in
4. ✅ See your campaign

Then data persistence is working perfectly! 🎊

## Need Help?

- **Documentation:** See the markdown files in the project root
- **Supabase Docs:** https://supabase.com/docs
- **Check logs:** Look for errors in Xcode console
- **Database:** Use Supabase dashboard SQL editor for queries

---

**Happy Coding! 🚀**

