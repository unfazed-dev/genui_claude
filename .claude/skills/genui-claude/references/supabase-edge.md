# Supabase Edge Functions

Deploy a secure backend proxy for GenUI Claude using Supabase Edge Functions.

## Overview

```
Flutter App                    Supabase Edge Function           Claude API
───────────                    ──────────────────────           ─────────────
     │                                   │                            │
     │  POST /claude-genui               │                            │
     │  + auth token                     │                            │
     │  + messages, tools                │                            │
     ├──────────────────────────────────▶│                            │
     │                                   │                            │
     │                                   │  Validate auth             │
     │                                   │  Add API key               │
     │                                   │                            │
     │                                   │  POST /messages            │
     │                                   ├───────────────────────────▶│
     │                                   │                            │
     │                                   │◀─── SSE stream ────────────│
     │◀───────── SSE stream ─────────────│                            │
     │                                   │                            │
```

## Setup

### 1. Initialize Supabase Functions

```bash
# In your project root
supabase init  # If not already initialized

# Create the function
supabase functions new claude-genui
```

### 2. Create Edge Function

**File:** `supabase/functions/claude-genui/index.ts`

```typescript
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
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Verify authorization
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Validate auth token (implement your auth logic)
    // For Supabase Auth:
    // const { data: { user }, error } = await supabaseClient.auth.getUser(token)
    // if (error || !user) { return 401 }

    // 3. Parse request
    const { messages, tools, systemPrompt, maxTokens, model }: GenUiRequest = await req.json()

    // 4. Validate required fields
    if (!messages || !Array.isArray(messages)) {
      return new Response(
        JSON.stringify({ error: 'Invalid messages array' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!tools || !Array.isArray(tools)) {
      return new Response(
        JSON.stringify({ error: 'Invalid tools array' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 5. Get API key from environment
    const apiKey = Deno.env.get('CLAUDE_API_KEY')
    if (!apiKey) {
      console.error('CLAUDE_API_KEY not set')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 6. Create Claude API client
    const anthropic = new Anthropic({ apiKey })

    // 7. Get model configuration
    const claudeModel = model ?? Deno.env.get('CLAUDE_MODEL') ?? 'claude-sonnet-4-20250514'
    const responseMaxTokens = maxTokens ?? parseInt(Deno.env.get('MAX_TOKENS') ?? '4096')

    // 8. Create streaming response
    const stream = await anthropic.messages.stream({
      model: claudeModel,
      max_tokens: responseMaxTokens,
      system: systemPrompt,
      messages,
      tools,
    })

    // 9. Return SSE stream
    const encoder = new TextEncoder()
    const readableStream = new ReadableStream({
      async start(controller) {
        try {
          for await (const event of stream) {
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

    // Handle Claude API errors
    if (error instanceof Anthropic.APIError) {
      return new Response(
        JSON.stringify({
          error: error.message,
          status: error.status,
          type: 'claude_api_error',
        }),
        { status: error.status ?? 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

### 3. Set Environment Variables

```bash
# Set secrets (stored securely, not in code)
supabase secrets set CLAUDE_API_KEY=sk-ant-api03-...

# Optional: Set model and token limits
supabase secrets set CLAUDE_MODEL=claude-sonnet-4-20250514
supabase secrets set MAX_TOKENS=4096
```

### 4. Deploy

```bash
# Deploy the function
supabase functions deploy claude-genui

# Test locally first (optional)
supabase functions serve claude-genui --env-file .env.local
```

### 5. Flutter Integration

```dart
final generator = ClaudeContentGenerator.proxy(
  proxyEndpoint: Uri.parse(
    'https://your-project.supabase.co/functions/v1/claude-genui',
  ),
  authToken: supabaseClient.auth.currentSession?.accessToken,
  proxyConfig: ProxyConfig(
    timeout: Duration(seconds: 120),
    includeHistory: true,
    maxHistoryMessages: 20,
  ),
);
```

## Authentication Patterns

### Supabase Auth Integration

```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req: Request) => {
  // Extract token
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return new Response(
      JSON.stringify({ error: 'Invalid authorization header' }),
      { status: 401 }
    )
  }

  const token = authHeader.substring(7)

  // Verify with Supabase
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
  )

  const { data: { user }, error } = await supabase.auth.getUser(token)

  if (error || !user) {
    return new Response(
      JSON.stringify({ error: 'Invalid or expired token' }),
      { status: 401 }
    )
  }

  // User is authenticated, proceed with request
  console.log(`Request from user: ${user.id}`)
  // ...
})
```

### Rate Limiting

```typescript
// Simple in-memory rate limiting (use Redis for production)
const rateLimits = new Map<string, { count: number; resetAt: number }>()

function checkRateLimit(userId: string, limit: number = 100): boolean {
  const now = Date.now()
  const windowMs = 60 * 1000  // 1 minute window

  const userLimit = rateLimits.get(userId)

  if (!userLimit || now > userLimit.resetAt) {
    rateLimits.set(userId, { count: 1, resetAt: now + windowMs })
    return true
  }

  if (userLimit.count >= limit) {
    return false
  }

  userLimit.count++
  return true
}

// In handler:
if (!checkRateLimit(user.id)) {
  return new Response(
    JSON.stringify({ error: 'Rate limit exceeded' }),
    { status: 429 }
  )
}
```

## Alternative: Node.js/Express Backend

```typescript
import express from 'express'
import Anthropic from '@anthropic-ai/sdk'
import cors from 'cors'

const app = express()
app.use(cors())
app.use(express.json())

const anthropic = new Anthropic({
  apiKey: process.env.CLAUDE_API_KEY,
})

app.post('/api/claude-genui', async (req, res) => {
  // Verify auth
  const authHeader = req.headers.authorization
  if (!authHeader) {
    return res.status(401).json({ error: 'Unauthorized' })
  }
  // Validate token...

  const { messages, tools, systemPrompt, maxTokens, model } = req.body

  // Set SSE headers
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')

  try {
    const stream = await anthropic.messages.stream({
      model: model ?? 'claude-sonnet-4-20250514',
      max_tokens: maxTokens ?? 4096,
      system: systemPrompt,
      messages,
      tools,
    })

    for await (const event of stream) {
      res.write(JSON.stringify(event) + '\n')
    }

    res.end()
  } catch (error) {
    console.error('Stream error:', error)
    res.status(500).json({ error: 'Stream failed' })
  }
})

app.listen(3000, () => console.log('Server running on port 3000'))
```

## Security Checklist

### Required

- [ ] **API key in environment** - Never in code or client
- [ ] **Auth validation** - Verify user tokens before processing
- [ ] **HTTPS only** - All communication encrypted
- [ ] **Input validation** - Validate messages and tools arrays

### Recommended

- [ ] **Rate limiting** - Prevent abuse
- [ ] **Request logging** - Audit trail for debugging
- [ ] **Error sanitization** - Don't expose internal errors to clients
- [ ] **Token expiry** - Short-lived auth tokens
- [ ] **CORS restrictions** - Limit to your domains in production

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `CLAUDE_API_KEY` | Yes | Your Claude API key |
| `CLAUDE_MODEL` | No | Default model (claude-sonnet-4-20250514) |
| `MAX_TOKENS` | No | Default max tokens (4096) |
| `SUPABASE_URL` | No | For Supabase auth validation |
| `SUPABASE_ANON_KEY` | No | For Supabase auth validation |

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| 401 Unauthorized | Check auth token format: `Bearer <token>` |
| 500 Server Error | Check `CLAUDE_API_KEY` is set in secrets |
| Timeout | Increase client timeout in `ProxyConfig` |
| CORS errors | Verify `corsHeaders` include your domain |
| Empty response | Check tools array is valid JSON |

### Debug Logging

```typescript
// Add to edge function for debugging
console.log('Request body:', JSON.stringify(req.body, null, 2))
console.log('Auth header:', authHeader ? 'present' : 'missing')
console.log('Model:', claudeModel)
console.log('Max tokens:', responseMaxTokens)
```

### Local Testing

```bash
# Create .env.local
echo "CLAUDE_API_KEY=sk-ant-..." > .env.local

# Run locally
supabase functions serve claude-genui --env-file .env.local

# Test with curl
curl -X POST http://localhost:54321/functions/v1/claude-genui \
  -H "Authorization: Bearer test-token" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "tools": [],
    "systemPrompt": "You are helpful."
  }'
```

## Cost Considerations

- Claude API is billed per token
- Consider implementing:
  - **Token budgets per user**
  - **Request quotas**
  - **Usage tracking and alerts**
  - **Caching for repeated queries**
