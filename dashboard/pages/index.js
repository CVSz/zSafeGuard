import { useEffect, useState } from 'react'

export default function Home() {
  const [data, setData] = useState(null)

  useEffect(() => {
    fetch('/api/stats').then(r => r.json()).then(setData)
  }, [])

  if (!data) return <p>Loading...</p>

  return (
    <div>
      <h1>zSafeGuard Dashboard</h1>
      <p>Users: {data.users}</p>
      <p>Threats: {data.threats}</p>
      <p>Revenue: ${data.revenue}</p>
    </div>
  )
}
