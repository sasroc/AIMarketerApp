#!/bin/bash

echo "🚀 Setting up AI functionality for AI Marketer App"
echo "=================================================="

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Installing..."
    
    # Try different installation methods
    if command -v brew &> /dev/null; then
        echo "📦 Installing via Homebrew..."
        brew install supabase/tap/supabase
    elif command -v npm &> /dev/null; then
        echo "📦 Installing via npm..."
        npm install -g supabase
    else
        echo "❌ Please install Supabase CLI manually:"
        echo "   - Homebrew: brew install supabase/tap/supabase"
        echo "   - npm: npm install -g supabase"
        echo "   - Or visit: https://supabase.com/docs/guides/cli"
        exit 1
    fi
fi

echo "✅ Supabase CLI found"

# Initialize Supabase if not already done
if [ ! -f "supabase/config.toml" ]; then
    echo "🔧 Initializing Supabase..."
    supabase init
else
    echo "✅ Supabase already initialized"
fi

echo ""
echo "📋 Next Steps:"
echo "=============="
echo "1. Create a Supabase project at https://supabase.com"
echo "2. Get your project URL and API key from Settings → API"
echo "3. Update SupabaseService.swift with your credentials:"
echo "   - Replace 'YOUR_SUPABASE_URL' with your project URL"
echo "   - Replace 'YOUR_SUPABASE_ANON_KEY' with your API key"
echo ""
echo "4. Link your project:"
echo "   supabase link --project-ref YOUR_PROJECT_ID"
echo ""
echo "5. Set your OpenAI API key in Supabase:"
echo "   - Go to Settings → Edge Functions"
echo "   - Add environment variable: OPENAI_API_KEY = your_openai_key"
echo ""
echo "6. Deploy the Edge Function:"
echo "   supabase functions deploy generate-captions"
echo ""
echo "7. Add Supabase SDK to your Xcode project:"
echo "   - File → Add Package Dependencies"
echo "   - URL: https://github.com/supabase/supabase-swift"
echo ""
echo "🎉 After completing these steps, your app will use AI to generate unique captions!"
echo ""
echo "📖 For detailed instructions, see SUPABASE_SETUP.md"
