import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WebsiteAnalysisRequest {
  url: string
}

interface BusinessAnalysisResult {
  summary: string
  valueProposition: string
  description: string
  colors: string[]
  logoUrl?: string
  images: string[]
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get the authenticated user
    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const { url }: WebsiteAnalysisRequest = await req.json()

    if (!url) {
      return new Response(
        JSON.stringify({ error: 'URL is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Analyze website
    const analysis = await analyzeWebsite(url)

    return new Response(
      JSON.stringify(analysis),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error analyzing website:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

async function analyzeWebsite(url: string): Promise<BusinessAnalysisResult> {
  try {
    // Fetch the website HTML
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    })

    if (!response.ok) {
      throw new Error(`Failed to fetch website: ${response.statusText}`)
    }

    const html = await response.text()

    // Extract information using regex and basic parsing
    const title = extractTitle(html)
    const description = extractMetaDescription(html)
    const colors = extractColors(html)
    const logoUrl = extractLogo(html, url)
    const images = extractImages(html, url)

    // Use OpenAI to generate comprehensive analysis
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OPENAI_API_KEY not configured')
    }

    const analysis = await generateBusinessAnalysis(
      url,
      title,
      description,
      html.substring(0, 5000), // First 5000 chars for context
      openaiApiKey
    )

    return {
      summary: analysis.summary,
      valueProposition: analysis.valueProposition,
      description: analysis.description || description || 'No description available',
      colors: colors,
      logoUrl: logoUrl,
      images: images.slice(0, 10) // Limit to 10 images
    }
  } catch (error) {
    console.error('Error in analyzeWebsite:', error)
    // Return fallback analysis
    return {
      summary: `Business website at ${url}`,
      valueProposition: 'Unable to extract value proposition automatically',
      description: 'Unable to analyze website content',
      colors: [],
      images: []
    }
  }
}

function extractTitle(html: string): string {
  const titleMatch = html.match(/<title[^>]*>([^<]+)<\/title>/i)
  return titleMatch ? titleMatch[1].trim() : ''
}

function extractMetaDescription(html: string): string {
  const descMatch = html.match(/<meta[^>]*name=["']description["'][^>]*content=["']([^"']+)["']/i)
  return descMatch ? descMatch[1].trim() : ''
}

function extractColors(html: string): string[] {
  const colors: Set<string> = new Set()
  
  // Extract hex colors
  const hexMatches = html.match(/#[0-9A-Fa-f]{6}/g)
  if (hexMatches) {
    hexMatches.forEach(color => colors.add(color.toUpperCase()))
  }

  // Extract rgb colors and convert to hex
  const rgbMatches = html.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/g)
  if (rgbMatches) {
    rgbMatches.forEach(rgb => {
      const match = rgb.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/)
      if (match) {
        const r = parseInt(match[1])
        const g = parseInt(match[2])
        const b = parseInt(match[3])
        const hex = `#${[r, g, b].map(x => {
          const hex = x.toString(16)
          return hex.length === 1 ? '0' + hex : hex
        }).join('').toUpperCase()}`
        colors.add(hex)
      }
    })
  }

  // Filter out common non-brand colors (black, white, grays)
  const filtered = Array.from(colors).filter(color => {
    const r = parseInt(color.slice(1, 3), 16)
    const g = parseInt(color.slice(3, 5), 16)
    const b = parseInt(color.slice(5, 7), 16)
    // Exclude very dark, very light, and gray colors
    const brightness = (r + g + b) / 3
    const saturation = Math.max(r, g, b) - Math.min(r, g, b)
    return brightness > 30 && brightness < 225 && saturation > 20
  })

  return filtered.slice(0, 5) // Return top 5 colors
}

function extractLogo(html: string, baseUrl: string): string | undefined {
  // Look for common logo patterns
  const patterns = [
    /<img[^>]*class=["'][^"']*logo[^"']*["'][^>]*src=["']([^"']+)["']/i,
    /<img[^>]*id=["'][^"']*logo[^"']*["'][^>]*src=["']([^"']+)["']/i,
    /<img[^>]*alt=["'][^"']*logo[^"']*["'][^>]*src=["']([^"']+)["']/i,
    /<link[^>]*rel=["']icon["'][^>]*href=["']([^"']+)["']/i,
    /<link[^>]*rel=["']shortcut icon["'][^>]*href=["']([^"']+)["']/i
  ]

  for (const pattern of patterns) {
    const match = html.match(pattern)
    if (match) {
      const logoUrl = match[1]
      return resolveUrl(logoUrl, baseUrl)
    }
  }

  return undefined
}

function extractImages(html: string, baseUrl: string): string[] {
  const images: string[] = []
  const imgMatches = html.matchAll(/<img[^>]*src=["']([^"']+)["']/gi)
  
  for (const match of imgMatches) {
    const imgUrl = resolveUrl(match[1], baseUrl)
    // Filter out very small images (likely icons) and common non-content images
    if (!imgUrl.includes('icon') && !imgUrl.includes('logo') && !imgUrl.includes('avatar')) {
      images.push(imgUrl)
    }
  }

  return images.slice(0, 10) // Limit to 10 images
}

function resolveUrl(url: string, baseUrl: string): string {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url
  }
  if (url.startsWith('//')) {
    return `https:${url}`
  }
  if (url.startsWith('/')) {
    const base = new URL(baseUrl)
    return `${base.protocol}//${base.host}${url}`
  }
  const base = new URL(baseUrl)
  return `${base.protocol}//${base.host}/${url}`
}

async function generateBusinessAnalysis(
  url: string,
  title: string,
  description: string,
  htmlSnippet: string,
  openaiApiKey: string
): Promise<{ summary: string; valueProposition: string; description: string }> {
  try {
    const prompt = `Analyze this business website and provide:
1. A comprehensive business summary (2-3 sentences)
2. The value proposition (what makes this business unique, 1-2 sentences)
3. A detailed business description (3-4 sentences)

Website URL: ${url}
Title: ${title}
Meta Description: ${description}
HTML Content (first 5000 chars): ${htmlSnippet}

Provide your response as JSON with keys: "summary", "valueProposition", "description"`

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
            content: 'You are a business analyst. Analyze websites and extract key business information. Always respond with valid JSON only.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 500,
        temperature: 0.7,
      }),
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.statusText}`)
    }

    const data = await response.json()
    const content = data.choices[0]?.message?.content?.trim() || '{}'
    
    // Try to parse JSON from response
    let analysis
    try {
      // Remove markdown code blocks if present
      const cleaned = content.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim()
      analysis = JSON.parse(cleaned)
    } catch {
      // If JSON parsing fails, create structured response from text
      const lines = content.split('\n')
      analysis = {
        summary: lines[0] || 'Business website',
        valueProposition: lines[1] || 'Value proposition not available',
        description: lines.slice(2).join(' ') || description || 'No description available'
      }
    }

    return {
      summary: analysis.summary || title || 'Business website',
      valueProposition: analysis.valueProposition || 'Value proposition not available',
      description: analysis.description || description || 'No description available'
    }
  } catch (error) {
    console.error('Error generating business analysis:', error)
    return {
      summary: title || `Business website at ${url}`,
      valueProposition: 'Unable to extract value proposition',
      description: description || 'No description available'
    }
  }
}

