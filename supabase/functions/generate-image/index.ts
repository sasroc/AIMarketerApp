import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ImageGenerationRequest {
  prompt: string
  mode: 'generate' | 'edit'
  imageData?: string // Base64 encoded image for editing
  size?: '1024x1024' | '1024x1792' | '1792x1024'
}

interface ImageGenerationResponse {
  imageUrl: string
  revisedPrompt?: string
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
    const { prompt, mode, imageData, size }: ImageGenerationRequest = await req.json()

    // Validate required fields
    if (!prompt || prompt.trim().length === 0) {
      throw new Error('Prompt is required')
    }

    if (!mode || !['generate', 'edit'].includes(mode)) {
      throw new Error('Mode must be either "generate" or "edit"')
    }

    if (mode === 'edit' && !imageData) {
      throw new Error('Image data is required for edit mode')
    }

    let result: ImageGenerationResponse

    if (mode === 'generate') {
      // Generate new image using DALL-E 3
      result = await generateImage(prompt, size || '1024x1024', openaiApiKey)
    } else {
      // Edit existing image using DALL-E 2 (DALL-E 3 doesn't support edits yet)
      result = await editImage(prompt, imageData!, openaiApiKey)
    }

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('Error generating/editing image:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})

async function generateImage(
  prompt: string,
  size: string,
  openaiApiKey: string
): Promise<ImageGenerationResponse> {
  console.log('Generating image with DALL-E 3...')
  
  try {
    const response = await fetch('https://api.openai.com/v1/images/generations', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'dall-e-3',
        prompt: prompt,
        n: 1,
        size: size,
        quality: 'standard',
        response_format: 'url'
      }),
    })

    if (!response.ok) {
      const errorData = await response.json()
      throw new Error(`OpenAI API error: ${errorData.error?.message || response.statusText}`)
    }

    const data = await response.json()
    
    if (!data.data || data.data.length === 0) {
      throw new Error('No image generated')
    }

    return {
      imageUrl: data.data[0].url,
      revisedPrompt: data.data[0].revised_prompt
    }
  } catch (error) {
    console.error('Error calling DALL-E 3:', error)
    throw error
  }
}

async function editImage(
  prompt: string,
  imageData: string,
  openaiApiKey: string
): Promise<ImageGenerationResponse> {
  console.log('Editing image with DALL-E 2...')
  
  try {
    // Convert base64 to blob
    const base64Data = imageData.split(',')[1] || imageData
    const binaryData = Uint8Array.from(atob(base64Data), c => c.charCodeAt(0))
    
    // Create FormData for multipart upload
    const formData = new FormData()
    const imageBlob = new Blob([binaryData], { type: 'image/png' })
    formData.append('image', imageBlob, 'image.png')
    formData.append('prompt', prompt)
    formData.append('n', '1')
    formData.append('size', '1024x1024')
    formData.append('response_format', 'url')

    const response = await fetch('https://api.openai.com/v1/images/edits', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
      },
      body: formData,
    })

    if (!response.ok) {
      const errorData = await response.json()
      throw new Error(`OpenAI API error: ${errorData.error?.message || response.statusText}`)
    }

    const data = await response.json()
    
    if (!data.data || data.data.length === 0) {
      throw new Error('No image generated')
    }

    return {
      imageUrl: data.data[0].url
    }
  } catch (error) {
    console.error('Error calling DALL-E 2 for image editing:', error)
    throw error
  }
}

