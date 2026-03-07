import { NextRequest, NextResponse } from 'next/server'
import { syncBookmarks } from '@/lib/x-sync'

export async function POST(request: NextRequest): Promise<NextResponse> {
  let body: { authToken?: string; ct0?: string } = {}
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 })
  }

  const { authToken, ct0 } = body
  if (!authToken?.trim() || !ct0?.trim()) {
    return NextResponse.json({ error: 'authToken and ct0 are required' }, { status: 400 })
  }

  try {
    const result = await syncBookmarks(authToken.trim(), ct0.trim())
    return NextResponse.json(result)
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Failed to fetch from Twitter' },
      { status: 500 },
    )
  }
}
