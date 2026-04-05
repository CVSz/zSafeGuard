const AI_BASE_URL = process.env.AI_BASE_URL || 'http://localhost:8000'

export default async function handler(req, res) {
  try {
    const [metricsRes, reportRes, eventsRes] = await Promise.all([
      fetch(`${AI_BASE_URL}/metrics`),
      fetch(`${AI_BASE_URL}/report?window=100`),
      fetch(`${AI_BASE_URL}/events?limit=12`)
    ])

    if (!metricsRes.ok || !reportRes.ok || !eventsRes.ok) {
      throw new Error('Upstream AI service unavailable')
    }

    const [metrics, report, events] = await Promise.all([
      metricsRes.json(),
      reportRes.json(),
      eventsRes.json()
    ])

    res.status(200).json({
      service: metrics.service,
      status: metrics.status,
      events_total: metrics.events_total,
      risk_rate_last_50: metrics.risk_rate_last_50,
      report,
      events: events.events || []
    })
  } catch (error) {
    res.status(200).json({
      service: 'ai',
      status: 'degraded',
      events_total: 0,
      risk_rate_last_50: 0,
      report: {
        window: 100,
        total_events: 0,
        avg_score: 0,
        risk_distribution: { SAFE: 0, WARNING: 0, RISK: 0 },
        timeline: []
      },
      events: [],
      error: error.message
    })
  }
}
