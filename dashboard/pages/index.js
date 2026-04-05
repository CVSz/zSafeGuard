import { useEffect, useMemo, useState } from 'react'

const AI_BASE_URL = process.env.NEXT_PUBLIC_AI_BASE_URL || 'http://localhost:8000'

function ScoreBadge({ risk }) {
  const color = risk === 'RISK' ? '#dc2626' : risk === 'WARNING' ? '#d97706' : '#16a34a'
  return (
    <span style={{ backgroundColor: `${color}22`, color, borderRadius: 999, padding: '2px 10px', fontWeight: 700 }}>
      {risk}
    </span>
  )
}

export default function Home() {
  const [data, setData] = useState(null)
  const [streamState, setStreamState] = useState('connecting')
  const [streamEvent, setStreamEvent] = useState(null)
  const [isSimulating, setIsSimulating] = useState(false)

  const loadStats = async () => {
    const response = await fetch('/api/stats')
    const payload = await response.json()
    setData(payload)
  }

  useEffect(() => {
    loadStats()
    const timer = setInterval(loadStats, 4000)
    return () => clearInterval(timer)
  }, [])

  useEffect(() => {
    const eventSource = new EventSource(`${AI_BASE_URL}/stream?interval_seconds=1.5`)
    eventSource.onopen = () => setStreamState('connected')
    eventSource.onerror = () => setStreamState('disconnected')
    eventSource.onmessage = event => {
      const message = JSON.parse(event.data)
      if (message.type === 'risk_event') {
        setStreamEvent(message.payload)
      }
    }

    return () => eventSource.close()
  }, [])

  const riskPercentages = useMemo(() => {
    if (!data?.report?.total_events) return { safe: 0, warning: 0, risk: 0 }
    const total = data.report.total_events
    const dist = data.report.risk_distribution
    return {
      safe: Math.round((dist.SAFE / total) * 100),
      warning: Math.round((dist.WARNING / total) * 100),
      risk: Math.round((dist.RISK / total) * 100)
    }
  }, [data])

  const runSimulation = async () => {
    setIsSimulating(true)
    await fetch('/api/simulate?batch=8', { method: 'POST' })
    await loadStats()
    setIsSimulating(false)
  }

  if (!data) return <p>Loading real-time dashboard...</p>

  return (
    <main style={{ fontFamily: 'Arial, sans-serif', maxWidth: 960, margin: '0 auto', padding: 24 }}>
      <h1>zSafeGuard Real-time Risk Dashboard</h1>
      <p>
        API status: <strong>{data.status}</strong> · Stream: <strong>{streamState}</strong>
      </p>

      <button
        onClick={runSimulation}
        disabled={isSimulating}
        style={{ marginBottom: 20, background: '#111827', color: '#fff', border: 0, borderRadius: 8, padding: '10px 14px', cursor: 'pointer' }}
      >
        {isSimulating ? 'Generating events...' : 'Generate simulation batch'}
      </button>

      <section style={{ display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: 12 }}>
        <div style={{ border: '1px solid #e5e7eb', borderRadius: 10, padding: 12 }}>
          <p>Total events</p>
          <h2>{data.events_total}</h2>
        </div>
        <div style={{ border: '1px solid #e5e7eb', borderRadius: 10, padding: 12 }}>
          <p>Avg score</p>
          <h2>{data.report.avg_score}</h2>
        </div>
        <div style={{ border: '1px solid #e5e7eb', borderRadius: 10, padding: 12 }}>
          <p>Risk rate (last 50)</p>
          <h2>{Math.round(data.risk_rate_last_50 * 100)}%</h2>
        </div>
        <div style={{ border: '1px solid #e5e7eb', borderRadius: 10, padding: 12 }}>
          <p>Latest stream event</p>
          <h2>{streamEvent?.risk || 'N/A'}</h2>
        </div>
      </section>

      <section style={{ marginTop: 20, border: '1px solid #e5e7eb', borderRadius: 10, padding: 12 }}>
        <h3>Risk distribution</h3>
        <p>SAFE: {riskPercentages.safe}% · WARNING: {riskPercentages.warning}% · RISK: {riskPercentages.risk}%</p>
        <div style={{ height: 16, background: '#f3f4f6', borderRadius: 999, overflow: 'hidden', display: 'flex' }}>
          <div style={{ width: `${riskPercentages.safe}%`, background: '#16a34a' }} />
          <div style={{ width: `${riskPercentages.warning}%`, background: '#d97706' }} />
          <div style={{ width: `${riskPercentages.risk}%`, background: '#dc2626' }} />
        </div>
      </section>

      <section style={{ marginTop: 20 }}>
        <h3>Recent events</h3>
        <table width="100%" cellPadding="8" style={{ borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ textAlign: 'left', borderBottom: '1px solid #e5e7eb' }}>
              <th>Timestamp</th>
              <th>Source</th>
              <th>Score</th>
              <th>Risk</th>
            </tr>
          </thead>
          <tbody>
            {data.events.map(event => (
              <tr key={`${event.timestamp}-${event.source}`} style={{ borderBottom: '1px solid #f3f4f6' }}>
                <td>{new Date(event.timestamp).toLocaleString()}</td>
                <td>{event.source}</td>
                <td>{event.score.toFixed(3)}</td>
                <td><ScoreBadge risk={event.risk} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </main>
  )
}
