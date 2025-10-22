import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface MediaItemRequest {
  id: string
  type: string
  description: string
}

interface MarketingPlanRequest {
  description: string
  targetAudience: string
  tone: string
  hashtags: string[]
  callToAction: string
}

interface PostScheduleRequest {
  startDate?: string
  endDate?: string
  selectedDays: number[]
  postsPerDay: Record<number, number>
  contentGuidelines: string
}

interface CaptionGenerationRequest {
  mediaItems: MediaItemRequest[]
  marketingPlan: MarketingPlanRequest
  schedule: PostScheduleRequest
}

interface GeneratedPostResponse {
  id: string
  caption: string
  mediaItemId: string
  scheduledDate: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get OpenAI API key from environment variables
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OpenAI API key not found')
    }

    // Parse request body
    const { mediaItems, marketingPlan, schedule }: CaptionGenerationRequest = await req.json()

    // Validate required fields
    if (!mediaItems || mediaItems.length === 0) {
      throw new Error('Media items are required')
    }

    if (!marketingPlan.description) {
      throw new Error('Marketing plan description is required')
    }

    if (!schedule.startDate || !schedule.endDate) {
      throw new Error('Start and end dates are required')
    }

    // Generate posts based on schedule
    const posts = await generateScheduledPosts(
      mediaItems,
      marketingPlan,
      schedule,
      openaiApiKey
    )

    return new Response(
      JSON.stringify({ posts }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('Error generating captions:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})

async function generateScheduledPosts(
  mediaItems: MediaItemRequest[],
  marketingPlan: MarketingPlanRequest,
  schedule: PostScheduleRequest,
  openaiApiKey: string
): Promise<GeneratedPostResponse[]> {
  const posts: GeneratedPostResponse[] = []
  
  // Calculate total number of posts that will be generated (same logic as iOS)
  let totalPostsCount = 0
  const startDate = new Date(schedule.startDate!)
  const endDate = new Date(schedule.endDate!)
  let currentDate = new Date(startDate)
  
  while (currentDate <= endDate) {
    const dayOfWeek = currentDate.getDay() // 0 = Sunday, 1 = Monday, etc.
    const weekDay = dayOfWeek === 0 ? 7 : dayOfWeek // Convert to iOS format
    
    if (schedule.selectedDays.includes(weekDay)) {
      const postsForThisDay = schedule.postsPerDay[weekDay] || 1
      totalPostsCount += postsForThisDay
    }
    
    currentDate.setDate(currentDate.getDate() + 1)
  }
  
  // Generate captions for all posts (let iOS handle the scheduling)
  for (let i = 0; i < totalPostsCount; i++) {
    const mediaItem = mediaItems[i % mediaItems.length]
    
    const caption = await generateCaption(
      mediaItem,
      marketingPlan,
      schedule,
      openaiApiKey,
      {
        postNumber: i + 1,
        dayOfWeek: 'Unknown', // We don't need this for caption generation
        timeOfDay: 9, // Default time
        totalPosts: totalPostsCount,
        isFirstPostOfDay: false,
        isLastPostOfDay: i === totalPostsCount - 1
      }
    )

    posts.push({
      id: crypto.randomUUID(),
      caption,
      mediaItemId: mediaItem.id,
      scheduledDate: new Date().toISOString() // Placeholder - iOS will set the real date
    })
  }

  return posts
}

interface PostContext {
  postNumber: number
  dayOfWeek: string
  timeOfDay: number
  totalPosts: number
  isFirstPostOfDay: boolean
  isLastPostOfDay: boolean
}

async function generateCaption(
  mediaItem: MediaItemRequest,
  marketingPlan: MarketingPlanRequest,
  schedule: PostScheduleRequest,
  openaiApiKey: string,
  context: PostContext
): Promise<string> {
  const prompt = createCaptionPrompt(mediaItem, marketingPlan, schedule, context)

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'You are a professional social media content creator. Generate engaging, platform-appropriate captions that match the specified tone and target audience. IMPORTANT: Only return the caption text itself - do not include any meta information, post numbers, or context details in your response.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 250,
        temperature: 0.9,
      }),
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.statusText}`)
    }

    const data = await response.json()
    let caption = data.choices[0]?.message?.content?.trim() || 'Generated caption'
    
    // Clean up any unwanted meta information that might have slipped through
    caption = cleanCaption(caption)
    
    return caption
  } catch (error) {
    console.error('Error calling OpenAI API:', error)
    // Fallback to a basic caption if API fails
    return createFallbackCaption(marketingPlan)
  }
}

function createCaptionPrompt(
  mediaItem: MediaItemRequest,
  marketingPlan: MarketingPlanRequest,
  schedule: PostScheduleRequest,
  context: PostContext
): string {
  // Create different prompt variations for diversity
  const promptVariations = [
    `Create a unique social media caption for a ${mediaItem.type} post. This is post #${context.postNumber} of ${context.totalPosts}, scheduled for ${context.dayOfWeek} at ${getTimeDescription(context.timeOfDay)}.

Marketing Context:
- Description: ${marketingPlan.description}
- Target Audience: ${marketingPlan.targetAudience}
- Tone: ${marketingPlan.tone}
- Call to Action: ${marketingPlan.callToAction}
- Hashtags: ${marketingPlan.hashtags.join(', ')}

Content Guidelines: ${schedule.contentGuidelines}

${context.isFirstPostOfDay ? 'This is the first post of the day - make it attention-grabbing!' : ''}
${context.isLastPostOfDay ? 'This is the final post of the day - end with impact!' : ''}

Requirements:
1. Match the ${marketingPlan.tone} tone perfectly
2. Appeal specifically to: ${marketingPlan.targetAudience}
3. Include the call to action: ${marketingPlan.callToAction}
4. Use 3-5 relevant hashtags from the provided list
5. Make this caption completely unique and different from other posts
6. Length: 1-3 sentences plus hashtags
7. Be creative and engaging - this should feel like a standalone post

Generate ONLY the caption text - no meta information, post numbers, or context details.`,

    `Write a distinctive social media caption for a ${mediaItem.type} post. This is post #${context.postNumber} of ${context.totalPosts}, going live on ${context.dayOfWeek} at ${getTimeDescription(context.timeOfDay)}.

Campaign Details:
- Main Message: ${marketingPlan.description}
- Target Audience: ${marketingPlan.targetAudience}
- Brand Tone: ${marketingPlan.tone}
- Call to Action: ${marketingPlan.callToAction}
- Available Hashtags: ${marketingPlan.hashtags.join(', ')}

Content Guidelines: ${schedule.contentGuidelines}

${context.isFirstPostOfDay ? 'This is the opening post of the day - set the tone!' : ''}
${context.isLastPostOfDay ? 'This is the closing post of the day - leave them wanting more!' : ''}

Your task:
1. Capture the ${marketingPlan.tone} tone authentically
2. Speak directly to: ${marketingPlan.targetAudience}
3. Naturally incorporate: ${marketingPlan.callToAction}
4. Select 3-5 hashtags from the provided list
5. Make this caption stand out as completely unique
6. Keep it concise but impactful (1-3 sentences + hashtags)
7. Create something that feels fresh and original

Return ONLY the caption text - no meta information, post numbers, or context details.`,

    `Design a one-of-a-kind social media caption for a ${mediaItem.type} post. This is post #${context.postNumber} of ${context.totalPosts}, scheduled for ${context.dayOfWeek} at ${getTimeDescription(context.timeOfDay)}.

Brand Information:
- Core Message: ${marketingPlan.description}
- Target Audience: ${marketingPlan.targetAudience}
- Voice & Tone: ${marketingPlan.tone}
- Call to Action: ${marketingPlan.callToAction}
- Hashtag Options: ${marketingPlan.hashtags.join(', ')}

Content Guidelines: ${schedule.contentGuidelines}

${context.isFirstPostOfDay ? 'This is the day\'s first post - make a strong impression!' : ''}
${context.isLastPostOfDay ? 'This is the day\'s final post - end on a high note!' : ''}

Instructions:
1. Embody the ${marketingPlan.tone} tone throughout
2. Connect with: ${marketingPlan.targetAudience}
3. Include the call to action: ${marketingPlan.callToAction}
4. Choose 3-5 hashtags from the provided list
5. Ensure this caption is completely different from other posts
6. Length: 1-3 sentences plus hashtags
7. Be innovative and engaging

Output ONLY the caption text - no meta information, post numbers, or context details.`
  ]

  // Select a random prompt variation for diversity
  const selectedPrompt = promptVariations[context.postNumber % promptVariations.length]
  
  return selectedPrompt
}

function getTimeDescription(hour: number): string {
  if (hour < 6) return 'early morning'
  if (hour < 9) return 'morning'
  if (hour < 12) return 'late morning'
  if (hour < 14) return 'lunchtime'
  if (hour < 17) return 'afternoon'
  if (hour < 19) return 'late afternoon'
  if (hour < 21) return 'evening'
  return 'night'
}

function cleanCaption(caption: string): string {
  // Remove any meta information that might have slipped through
  const patterns = [
    /^\*\*Post #\d+ of \d+ Caption:\*\*\s*/i,
    /^Post #\d+ of \d+ Caption:\s*/i,
    /^\*\*Caption:\*\*\s*/i,
    /^Caption:\s*/i,
    /^\*\*Post #\d+:\*\*\s*/i,
    /^Post #\d+:\s*/i,
    /^\*\*.*?Caption.*?:\*\*\s*/i,
    /^.*?Caption.*?:\s*/i
  ]
  
  let cleaned = caption
  for (const pattern of patterns) {
    cleaned = cleaned.replace(pattern, '')
  }
  
  return cleaned.trim()
}

function createFallbackCaption(marketingPlan: MarketingPlanRequest): string {
  const hashtags = marketingPlan.hashtags.slice(0, 3).join(' ')
  return `${marketingPlan.description}\n\n${marketingPlan.callToAction}\n\n${hashtags}`
}
