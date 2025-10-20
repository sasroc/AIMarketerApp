# Quick Start Guide

## Opening the Project in Xcode

1. **Locate the project file**
   - Navigate to: `/Users/user/Desktop/CursorGitRepos/AIMarketerApp/`
   - Double-click on `AIMarketerApp.xcodeproj`

2. **Select a target device**
   - In Xcode's toolbar, click the device selector (next to the Run button)
   - Choose either:
     - A simulator (e.g., iPhone 17 Pro)
     - Your connected iOS device (requires developer account)

3. **Build and run**
   - Press `Cmd + R` or click the Play button
   - Wait for the build to complete
   - The app will launch in the simulator or on your device

## Testing the App

### 1. Sign Up/Sign In
- When the app launches, you'll see a beautiful welcome screen
- Tap "Get Started" to create an account
- Or tap "Sign In" if you've used the app before
- Use any email/password (mock authentication stores locally)

### 2. Create Your First Campaign
- Tap the "Create" tab (plus icon)
- Follow the 4-step process:

   **Step 1: Upload Media**
   - Tap "Select Photos & Videos"
   - Choose 1-10 images from your photo library
   - You can remove items by tapping the X

   **Step 2: Marketing Plan**
   - Enter a campaign description (e.g., "Promote our new coffee blends")
   - Add target audience (e.g., "Young professionals")
   - Select a content tone (Professional, Casual, etc.)
   - Optionally add hashtags and call-to-action

   **Step 3: Schedule**
   - Set posts per week (1-14)
   - Select posting days (tap day buttons)
   - Set posting times for each day

   **Step 4: Guidelines**
   - Add AI instructions for content generation
   - Review the campaign summary
   - Tap "Generate Posts"

### 3. Review Generated Posts
- AI will generate captions for your posts (mock captions for now)
- Review each post with its media and scheduled date
- Tap "Edit" to modify any caption
- Tap "Schedule All Posts" when ready

### 4. View Schedule
- Go to the "Schedule" tab
- See all upcoming posts organized by status
- Filter by: All, Scheduled, Pending, Posted, Failed
- Tap any post to view details

### 5. Dashboard
- The "Home" tab shows your stats
- View scheduled and posted counts
- See upcoming posts at a glance

### 6. Profile
- Tap the "Profile" tab
- View your account info
- Connect Instagram (UI only - not yet functional)
- Access settings
- Sign out

## Key Features Demonstrated

✅ **Beautiful UI** - Modern purple/blue gradient theme with dark mode
✅ **Photo Picker Integration** - Native iOS photo selection
✅ **Multi-Step Forms** - Intuitive campaign creation flow
✅ **Date/Time Pickers** - Schedule posts for specific times
✅ **Dynamic Lists** - Scrollable, filterable post lists
✅ **Form Validation** - Real-time validation with helpful messages
✅ **Loading States** - Progress indicators for async operations
✅ **Empty States** - Helpful messages when no data exists

## What's Mock/Demo?

Currently using mock services (can be replaced with real backend):
- ✏️ User authentication (stored in UserDefaults)
- ✏️ Post generation (placeholder captions)
- ✏️ Instagram connection (UI only)

## Next Steps for Production

1. **Backend Integration**
   - Replace `AuthenticationService` with real API calls
   - Implement user registration/login with JWT tokens
   - Add password encryption and validation

2. **AI Integration**
   - Connect `ContentGenerationService` to OpenAI API
   - Use GPT-3.5-turbo or GPT-4 for caption generation
   - Implement prompt engineering for better results

3. **Instagram API**
   - Register app with Meta/Facebook Developers
   - Implement OAuth flow for Instagram Business accounts
   - Use Instagram Graph API for posting
   - Handle media uploads and publishing

4. **Push Notifications**
   - Configure APNs certificates
   - Implement notification handling
   - Send alerts for post successes/failures

5. **Analytics**
   - Add post performance tracking
   - Integrate Instagram Insights API
   - Display engagement metrics

## Troubleshooting

**Build Failed?**
- Ensure you're using Xcode 15.0 or later
- Clean build folder: `Cmd + Shift + K`
- Try rebuilding: `Cmd + B`

**Simulator Issues?**
- Reset simulator: Device > Erase All Content and Settings
- Try a different simulator device

**Photo Picker Not Working?**
- Simulator has limited photos
- Add photos: Drag images into the simulator
- Or use the Camera app in simulator to save sample images

**App Crashes?**
- Check Xcode console for error messages
- Verify all files are included in target
- Clean and rebuild

## Support

For issues or questions, refer to:
- Main README.md
- AI_Marketer_Specification.markdown in docs/
- Xcode's built-in documentation (Cmd + Shift + 0)

Enjoy building with AI Marketer! 🚀

