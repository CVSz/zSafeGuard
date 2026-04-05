import { useEffect, useState } from 'react'

export default function Home() {
  const [data, setData] = useState(null)

  useEffect(() => {
    fetch('http://localhost:8000/metrics').then(r => r.json()).then(setData)
  }, [])

  if (!data) return <p>Loading...</p>

  return (
    <div>
      <h1>zSafeGuard Dashboard</h1>
      <p>Service: {data.service}</p>
      <p>Status: {data.status}</p>
    </div>
  )
}
