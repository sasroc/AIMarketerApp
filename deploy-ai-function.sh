#!/bin/bash

echo "🚀 Deploying AI Function to Supabase"
echo "===================================="

# Check if access token is set
if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo "❌ SUPABASE_ACCESS_TOKEN not set!"
    echo ""
    echo "Please get your access token from:"
    echo "1. Go to https://supabase.com"
    echo "2. Account Settings → Access Tokens"
    echo "3. Generate new token"
    echo "4. Run: export SUPABASE_ACCESS_TOKEN=your_token_here"
    echo ""
    exit 1
fi

echo "✅ Access token found"

# Link the project
echo "🔗 Linking to Supabase project..."
supabase link --project-ref skuisuaymljmqlohcwem

if [ $? -eq 0 ]; then
    echo "✅ Project linked successfully"
else
    echo "❌ Failed to link project"
    exit 1
fi

# Deploy the function
echo "📦 Deploying Edge Function..."
supabase functions deploy generate-captions

if [ $? -eq 0 ]; then
    echo "✅ Edge Function deployed successfully!"
    echo ""
    echo "🎉 Next steps:"
    echo "1. Go to your Supabase dashboard"
    echo "2. Settings → Edge Functions"
    echo "3. Add environment variable: OPENAI_API_KEY = your_openai_key"
    echo "4. Test your app!"
else
    echo "❌ Failed to deploy function"
    exit 1
fi
