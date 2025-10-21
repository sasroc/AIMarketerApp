# AI Marketer iOS App

An AI-powered marketing app that helps you create and schedule social media content automatically.

## Features

- 🎨 **Beautiful SwiftUI Interface** - Modern, intuitive design with dark mode support
- 📸 **Media Upload** - Select up to 10 images or videos from your photo library
- 📝 **Marketing Plan** - Define your campaign goals, target audience, and content tone
- 📅 **Smart Scheduling** - Schedule posts with custom date ranges, multiple posting days, and flexible times
- 🤖 **AI Content Generation** - Generate engaging post captions using AI
- ✏️ **Advanced Post Editing** - Edit post captions with cursor positioning and keyboard support
- 🗑️ **Post Management** - Delete posts with confirmation dialogs
- 📊 **Dashboard** - Track upcoming and posted content
- 👤 **User Authentication** - Secure login and account management

## Getting Started

### Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 16.0 or later (deployment target)

### Installation

1. Clone the repository
2. Open `AIMarketerApp.xcodeproj` in Xcode
3. Select your target device or simulator
4. Press `Cmd + R` to build and run

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
2. **Upload Media** - Select images or videos from your photo library
3. **Define Marketing Plan** - Describe your campaign, target audience, and choose a content tone
4. **Set Schedule** - Choose custom date ranges, select posting days, and set multiple times per day
5. **Add Guidelines** - Specify what the AI should include in your posts
6. **Generate Posts** - Let AI create engaging captions for your content
7. **Review & Edit** - Edit any captions before scheduling
8. **Schedule** - Confirm and schedule all posts

### Mock Services

Currently, the app uses mock services for:
- User authentication (stored locally)
- Content generation (placeholder captions)

To integrate with a real backend:
1. Update `AuthenticationService.swift` to call your authentication API
2. Update `ContentGenerationService.swift` to call your AI backend (OpenAI API)
3. Add Instagram API integration for posting

## Next Steps

- [ ] Integrate with backend API
- [ ] Connect to OpenAI for real content generation
- [ ] Implement Instagram Graph API integration
- [ ] Add push notifications for post status updates
- [ ] Implement analytics and insights
- [ ] Add support for more social media platforms

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
