# AI Marketer App Specification

## Overview
This document outlines the requirements for building an AI-powered marketing app called "AI Marketer." The app allows users to upload media (images or videos), define a marketing plan, specify posting schedules, and generate text content for social media posts. The AI will then generate complete posts and automatically schedule them for upload to Instagram. Initially, focus on Instagram integration only.

The app should be built as an iOS application using SwiftUI for the user interface. It will require a backend server for processing AI requests, scheduling, and automated posting to handle tasks that cannot run reliably in the background on iOS (e.g., timed posts).

The app should use OpenAI's API for AI-driven content generation, specifically a cost-effective model like GPT-3.5-Turbo (or the latest equivalent cheap model; confirm current pricing and availability via OpenAI docs).

Include user authentication for account management. The frontend will be the iOS app, with a backend (e.g., Node.js/Express or Swift Vapor) for server-side logic.

**Key Goals:**
- User-friendly interface for non-technical marketers on mobile devices.
- Secure handling of user data and media.
- Reliable scheduling and posting to avoid API rate limits or errors.
- Start with MVP (Minimum Viable Product) features; expand later if needed.

## Target Users
- Small business owners, marketers, or influencers who want automated social media content creation and scheduling for Instagram via their iOS devices.

## Tech Stack Recommendations
- **Frontend (iOS App):** SwiftUI for UI components and navigation. Use Swift for app logic.
- **Backend:** Node.js with Express.js (or Swift with Vapor) for API endpoints; use a database like MongoDB or PostgreSQL for storing user data, media, schedules, and generated posts.
- **AI Integration:** OpenAI API (use a cheap model like `gpt-3.5-turbo`). Handle API keys securely on the backend (e.g., store in environment variables). API calls should be made from the backend to avoid exposing keys in the app.
- **Media Storage:** Use cloud storage like AWS S3 or Google Cloud Storage for uploaded images/videos. Integrate with iOS photo picker for uploads.
- **Scheduling:** Use a task scheduler like Node-Cron or a service like BullMQ on the backend for queuing and timing posts.
- **Instagram Integration:** Use Instagram Graph API (requires a Facebook Developer account, Business Account setup, and app review for posting permissions). Handle OAuth authentication via a web view in the iOS app, then store tokens securely on the backend.
- **Authentication:** Use Firebase Auth or custom JWT for user login/registration in the app, synced with backend.
- **Networking:** Alamofire or URLSession in Swift for API communication between app and backend.
- **Local Storage:** Core Data or UserDefaults for temporary data in the app.
- **Other:** Handle errors gracefully, log activities, and ensure compliance with Instagram's terms (e.g., no spam posting). Use push notifications (via APNs) for updates like post successes/failures.

## User Flow
1. User signs up/logs in via the iOS app.
2. User uploads media files from photo library or camera.
3. User inputs marketing plan details via forms.
4. User specifies posting frequency, days, times, and content guidelines.
5. App sends data to backend; AI generates post content (text + media pairing).
6. User reviews and approves generated posts in the app.
7. Backend schedules and automatically posts to Instagram at specified times; app receives notifications.

## Core Features
### 1. User Authentication
- Allow users to register with email/password or social login (e.g., Apple Sign In, Google).
- Secure login with tokens stored in Keychain.
- Profile management: Link Instagram account (via OAuth in a web view) for posting permissions; send tokens to backend.
- Must: Ensure users have a verified Instagram Business Account (guide them via in-app instructions or links).

### 2. Media Upload
- Interface: Use PHPickerViewController for selecting images (JPEG, PNG) and videos (MP4, up to 60 seconds for Instagram feed/posts) from library or UIImagePickerController for camera.
- Limits: Max 10 files per session; validate file types and sizes (e.g., <100MB per file).
- Storage: Upload to backend, which stores in cloud storage; store metadata (file URL, type) in database linked to user.
- Preview: Show thumbnails/previews in a SwiftUI grid or list after upload.

### 3. Marketing Plan Input
- Form: SwiftUI TextEditor or TextField for describing the marketing plan (e.g., "Promote our new coffee blends targeting young professionals with fun, energetic vibes").
- Optional: Additional fields like target audience, tone (e.g., Picker for professional, casual), hashtags, or calls-to-action.

### 4. Scheduling Options
- Posts per week: Stepper or TextField for number (e.g., 3-7).
- Days: Multi-select List or Toggle buttons for days of the week (e.g., Mon, Wed, Fri).
- Times: DatePicker (time mode) for each selected day (e.g., 9:00 AM, 2:00 PM); allow multiple times per day if needed.
- Validation: Ensure total posts align with frequency (e.g., if 3 posts/week and 3 days selected, schedule one per day).
- Timezone: Use device's timezone.

### 5. Content Generation Guidelines
- Text input: TextEditor for specifying what text should be generated for each post (e.g., "Include product description, emoji, and a question to engage users").
- AI Prompting: Backend constructs prompts for OpenAI based on user inputs (e.g., "Generate Instagram caption for [media description] based on marketing plan: [plan]. Follow guidelines: [user guidelines]. Keep under 150 characters.").

### 6. Post Generation
- Trigger: Button to "Generate Posts" sends data to backend.
- Process:
  - Backend uses OpenAI API to generate text captions for each post.
  - Pair generated text with uploaded media (e.g., cycle through media if fewer than posts).
  - Generate enough posts to cover the schedule (e.g., for 4 weeks ahead, or user-specified duration).
- Output: App fetches and displays generated posts in a preview ScrollView or List, showing media + caption.
- Editing: Allow user to edit captions in TextFields before approving and sending to backend for scheduling.
- Model Usage: Use `gpt-3.5-turbo` for cost efficiency; fallback to a similar cheap model if deprecated.

### 7. Scheduling and Auto-Upload
- After approval, backend saves schedule in database (e.g., post ID, media URL, caption, scheduled time).
- Backend Scheduler: Use a cron job or queue to check for due posts and trigger Instagram API calls.
- Instagram Posting:
  - Use Graph API endpoint for creating media (e.g., POST /user_id/media for images/videos).
  - Handle publishing (POST /media_id/publish).
  - Support feed posts (images/videos with captions).
- Error Handling: If post fails (e.g., API error), notify user via push notification and retry once.
- Compliance: Ensure posts adhere to Instagram rules; log all posts for auditing.

## Additional Requirements
### UI/UX
- Use SwiftUI for responsive, native iOS design (support iPhone and iPad).
- Intuitive forms with validation (e.g., required fields, alerts for errors).
- Dashboard: TabView or NavigationStack showing upcoming schedules, past posts, and basic analytics (e.g., post status).
- Loading indicators (ProgressView) for AI generation and uploads.
- Dark mode support.

### Security and Privacy
- Encrypt sensitive data (e.g., API keys on backend).
- Use HTTPS for all API calls.
- User consent for Instagram access and photo library permissions.
- Comply with App Store guidelines, GDPR/CCPA if applicable.

### Testing
- Unit tests for app logic (e.g., view models) and backend (e.g., AI prompting, scheduling).
- Integration tests for OpenAI and Instagram APIs.
- Manual testing on simulators/devices: Upload media, generate posts, schedule, and verify Instagram uploads.
- Test background notifications.

### Deployment
- iOS App: Submit to App Store; use TestFlight for beta.
- Backend: Host on cloud platform (e.g., Heroku/AWS).
- Environment variables for API keys.
- Monitoring: Use tools like Sentry for error tracking.

### Potential Extensions (Post-MVP)
- Support for more platforms (e.g., Facebook, Twitter).
- Advanced AI features (e.g., image captioning with vision models).
- Analytics integration (e.g., fetch Instagram insights via API).
- Subscription model for premium features (in-app purchases).

## Timeline and Deliverables
- **Week 1:** Setup iOS project structure, authentication, and media upload.
- **Week 2:** Integrate backend with OpenAI for content generation.
- **Week 3:** Add scheduling UI in app and backend logic.
- **Week 4:** Instagram API integration and testing.
- **Week 5:** UI polish, error handling, notifications, and deployment.

Provide regular updates via [tool of choice, e.g., GitHub/Trello]. If any clarifications needed, discuss before proceeding.