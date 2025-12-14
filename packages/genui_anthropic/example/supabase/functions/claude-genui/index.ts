// Supabase Edge Function for GenUI Anthropic Proxy
// This function acts as a secure backend proxy for Claude API calls,
// keeping your API key safe on the server side.
//
// Deploy with: supabase functions deploy claude-genui
//
// Required environment variables:
// - ANTHROPIC_API_KEY: Your Anthropic API key
//
// Optional environment variables:
// - CLAUDE_MODEL: Claude model to use (default: claude-sonnet-4-20250514)
// - MAX_TOKENS: Maximum tokens in response (default: 4096)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Anthropic from 'npm:@anthropic-ai/sdk'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GenUiRequest {
  messages: Anthropic.MessageParam[]
  tools: Anthropic.Tool[]
  systemPrompt: string
  maxTokens?: number
  model?: string
}

serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify authorization
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Validate the auth token with your auth system
    // For Supabase Auth, you would verify the JWT here:
    // const { data: { user }, error } = await supabaseClient.auth.getUser(token)
    // if (error || !user) { return unauthorized response }

    // Parse request body
    const { messages, tools, systemPrompt, maxTokens, model }: GenUiRequest = await req.json()

    // Validate required fields
    if (!messages || !Array.isArray(messages)) {
      return new Response(
        JSON.stringify({ error: 'Invalid messages array' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    if (!tools || !Array.isArray(tools)) {
      return new Response(
        JSON.stringify({ error: 'Invalid tools array' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Initialize Anthropic client
    const apiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!apiKey) {
      console.error('ANTHROPIC_API_KEY environment variable not set')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const anthropic = new Anthropic({ apiKey })

    // Get configuration from environment or request
    const claudeModel = model ?? Deno.env.get('CLAUDE_MODEL') ?? 'claude-sonnet-4-20250514'
    const responseMaxTokens = maxTokens ?? parseInt(Deno.env.get('MAX_TOKENS') ?? '4096')

    // Create streaming response
    const stream = await anthropic.messages.stream({
      model: claudeModel,
      max_tokens: responseMaxTokens,
      system: systemPrompt,
      messages,
      tools,
    })

    // Return SSE stream
    const encoder = new TextEncoder()
    const readableStream = new ReadableStream({
      async start(controller) {
        try {
          for await (const event of stream) {
            // Send each event as a newline-delimited JSON
            const data = JSON.stringify(event) + '\n'
            controller.enqueue(encoder.encode(data))
          }
          controller.close()
        } catch (error) {
          console.error('Stream error:', error)
          controller.error(error)
        }
      },
    })

    return new Response(readableStream, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    })

  } catch (error) {
    console.error('Function error:', error)

    // Handle Anthropic API errors
    if (error instanceof Anthropic.APIError) {
      return new Response(
        JSON.stringify({
          error: error.message,
          status: error.status,
          type: 'anthropic_api_error'
        }),
        {
          status: error.status ?? 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
