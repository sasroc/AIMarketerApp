# AI Marketer iOS App

An AI-powered marketing app that helps you create and schedule social media content automatically.

## Features

- 🎨 **Beautiful SwiftUI Interface** - Modern, intuitive design with dark mode support
- 🖼️ **AI Image Generation** - Generate new images or edit existing ones using DALL-E (OpenAI)
- 📸 **Media Upload** - Select up to 10 images or videos from your photo library
- 📝 **Marketing Plan** - Define your campaign goals, target audience, and content tone
- 📅 **Smart Scheduling** - Schedule posts with custom date ranges, multiple posting days, and flexible times
- 🤖 **AI Content Generation** - Generate engaging post captions using AI
- ✏️ **Advanced Post Editing** - Edit post captions with cursor positioning and keyboard support
- 🗑️ **Post Management** - Delete posts with confirmation dialogs
- 📊 **Dashboard** - Track upcoming and posted content
- 👤 **User Authentication** - Secure login and account management with Supabase
- 💾 **Data Persistence** - All campaigns, posts, and media automatically saved and synced across devices

## Getting Started

### Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 16.0 or later (deployment target)

### Installation

1. Clone the repository
2. Set up Supabase (see [SUPABASE_SETUP.md](SUPABASE_SETUP.md))
3. Configure your API keys in `Config.plist` (copy from `Config.template.plist`)
4. Apply database migrations: `./apply-migrations.sh`
5. Deploy Edge Functions:
   - `./setup-ai.sh` (for caption generation)
   - `./deploy-image-function.sh` (for image generation)
6. Open `AIMarketerApp.xcodeproj` in Xcode
7. Add new files to Xcode project (see [AI_IMAGE_GENERATION_SETUP.md](AI_IMAGE_GENERATION_SETUP.md))
8. Select your target device or simulator
9. Press `Cmd + R` to build and run

For detailed setup instructions, see [QUICKSTART.md](QUICKSTART.md).

### Project Structure

```
AIMarketerApp/
├── AIMarketerApp.swift          # App entry point
├── Models/                      # Data models
│   ├── User.swift
│   ├── MediaItem.swift
│   ├── MarketingPlan.swift
│   ├── PostSchedule.swift
│   └── GeneratedPost.swift
├── Views/                       # SwiftUI views
│   ├── Authentication/          # Login, signup screens
│   ├── Home/                    # Dashboard
│   ├── Campaign/                # Campaign creation flow
│   ├── Schedule/                # Post schedule view
│   ├── Profile/                 # User profile
│   └── Components/              # Reusable UI components
├── ViewModels/                  # Business logic
│   ├── AuthenticationViewModel.swift
│   └── CampaignViewModel.swift
└── Services/                    # API and data services
    ├── AuthenticationService.swift
    └── ContentGenerationService.swift
```

## Usage

### Creating Your First Campaign

1. **Sign Up/Sign In** - Create an account or sign in to get started
2. **Generate or Upload Media**:
   - Use AI to generate images from text descriptions
   - Or edit existing images with AI
   - Or upload images/videos from your photo library
3. **Define Marketing Plan** - Describe your campaign, target audience, and choose a content tone
4. **Set Schedule** - Choose custom date ranges, select posting days, and set multiple times per day
5. **Add Guidelines** - Specify what the AI should include in your posts
6. **Generate Posts** - Let AI create engaging captions for your content
7. **Review & Edit** - Edit any captions before scheduling
8. **Schedule** - Confirm and schedule all posts

### Data Persistence

All user data is automatically saved to Supabase:

- **Media Files** - Uploaded to Supabase Storage with secure access
- **Draft Campaigns** - Marketing plans, schedules, and content guidelines
- **Generated Posts** - AI-generated captions, scheduled dates, and post status
- **Cross-Device Sync** - Access your data from any device

Data is automatically:
- Loaded when you sign in
- Saved as you create and edit content
- Protected with Row Level Security (RLS)

For more details, see [DATA_PERSISTENCE.md](DATA_PERSISTENCE.md).

### Services Integration

The app integrates with:
- **Supabase** - Authentication, database, and file storage
- **OpenAI API** - For AI-powered content and image generation
  - DALL-E 3 for image generation (see `supabase/functions/generate-image`)
  - GPT-4 for caption generation (see `supabase/functions/generate-captions`)

To customize or extend:
1. Update `SupabaseService.swift` for database operations
2. Modify `supabase/functions/generate-captions/index.ts` for caption generation logic
3. Modify `supabase/functions/generate-image/index.ts` for image generation logic
4. Update `AIImageGenerationService.swift` for client-side image generation features
5. Add Instagram API integration for posting (future enhancement)

## Next Steps

- [x] Integrate with Supabase backend
- [x] Implement data persistence and sync
- [x] Connect AI for content generation
- [x] Add AI image generation and editing
- [ ] Implement Instagram Graph API integration for automatic posting
- [ ] Add push notifications for post status updates
- [ ] Implement analytics and insights dashboard
- [ ] Add support for more social media platforms (Facebook, Twitter, LinkedIn)
- [ ] Offline mode with local caching
- [ ] Advanced scheduling with time zone support
- [ ] Image variation generation and style presets

## Design Highlights

- **Purple/Blue gradient theme** - Modern, professional color scheme
- **Dark mode optimized** - Beautiful contrast and easy on the eyes
- **Smooth animations** - Polished transitions and interactions
- **Intuitive navigation** - Tab-based main navigation with clear user flows
- **Responsive layouts** - Works great on iPhone and iPad

## License

This project is intended for demonstration purposes.

## Support

For questions or issues, please refer to the specification document in `docs/AI_Marketer_Specification.markdown`.
