# Supabase Setup for AI Marketer App

This guide will walk you through setting up Supabase for secure AI functionality in your app.

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - Name: `ai-marketer-app`
   - Database Password: (generate a strong password)
   - Region: Choose closest to your users
5. Click "Create new project"

## 2. Get Your Project Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (looks like: `https://your-project-id.supabase.co`)
   - **Project API Key** (anon/public key)

## 3. Update Your iOS App Configuration

1. Open `AIMarketerApp/Services/SupabaseService.swift`
2. Replace the placeholder values:
   ```swift
   private let supabaseURL = "YOUR_SUPABASE_URL" // Replace with your actual Supabase URL
   private let supabaseKey = "YOUR_SUPABASE_ANON_KEY" // Replace with your actual Supabase anon key
   ```

## 4. Set Up Edge Functions

### Install Supabase CLI

```bash
# Install via npm
npm install -g supabase

# Or via Homebrew (macOS)
brew install supabase/tap/supabase
```

### Initialize Supabase in Your Project

```bash
cd /Users/user/Desktop/CursorGitRepos/AIMarketerApp
supabase init
```

### Link to Your Project

```bash
supabase link --project-ref YOUR_PROJECT_ID
```

### Deploy the Edge Function

```bash
supabase functions deploy generate-captions
```

## 5. Set Up Environment Variables

1. In your Supabase dashboard, go to **Settings** → **Edge Functions**
2. Add the following environment variable:
   - **Name**: `OPENAI_API_KEY`
   - **Value**: Your OpenAI API key (starts with `sk-`)

## 6. Add Supabase SDK to Your iOS Project

1. Open your Xcode project
2. Go to **File** → **Add Package Dependencies**
3. Enter this URL: `https://github.com/supabase/supabase-swift`
4. Click **Add Package**
5. Select **Supabase** and click **Add Package**

## 7. Test the Integration

1. Build and run your app
2. Create a campaign with media items and marketing plan
3. Click "Generate Posts"
4. The app should now use AI to generate unique captions for each post

## Security Benefits

✅ **API Key Protection**: Your OpenAI API key is stored securely in Supabase Edge Functions environment variables
✅ **No Client Exposure**: The API key never reaches the client app
✅ **Rate Limiting**: Supabase provides built-in rate limiting
✅ **Authentication**: You can add user authentication later
✅ **Monitoring**: Supabase provides logs and monitoring for your functions

## Troubleshooting

### Common Issues:

1. **Function not found**: Make sure you deployed the function with `supabase functions deploy generate-captions`
2. **API key error**: Verify your OpenAI API key is set in the Edge Functions environment variables
3. **CORS errors**: The function includes CORS headers, but make sure your Supabase project allows your app's domain

### Debugging:

1. Check Supabase Edge Functions logs in the dashboard
2. Use `supabase functions logs generate-captions` to see real-time logs
3. Test the function directly in the Supabase dashboard

## Next Steps

Once this is working, you can:
- Add user authentication
- Implement image analysis for better captions
- Add more AI features like hashtag optimization
- Set up database storage for generated posts
