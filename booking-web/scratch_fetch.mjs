import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://qzuakhzajvrrvznvyelg.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6dWFraHphanZycnZ6bnZ5ZWxnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzMwNTYzOCwiZXhwIjoyMDc4ODgxNjM4fQ.MzvfjO7IdmvXDxUBGrxrzsyywoPFnsyX6RGxmfXk6fY'
)

async function run() {
  const { data, error } = await supabase.from('appointments').select('*').limit(1)
  console.log(JSON.stringify(data, null, 2))
  console.log("Error:", error)
}

run()
