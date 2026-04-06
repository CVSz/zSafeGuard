const AI_BASE_URL = process.env.AI_BASE_URL || 'http://localhost:8000'

function randomFeatures() {
  return Array.from({ length: 5 }, () => Number(Math.random().toFixed(3)))
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST')
    return res.status(405).json({ error: 'Method not allowed' })
  }

  const batch = Math.min(Number(req.query.batch || 5), 20)

  try {
    const results = []
    for (let i = 0; i < batch; i += 1) {
      const response = await fetch(`${AI_BASE_URL}/analyze`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          features: randomFeatures(),
          source: 'dashboard-simulation'
        })
      })

      if (!response.ok) throw new Error('Failed to push simulation event')
      results.push(await response.json())
    }

    return res.status(200).json({ generated: results.length, latest: results.at(-1) || null })
  } catch (error) {
    return res.status(502).json({ error: error.message })
  }
}
