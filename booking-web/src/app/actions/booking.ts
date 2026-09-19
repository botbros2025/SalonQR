'use server'

import { createAdminClient } from '@/lib/supabase/admin'
import { Database } from '@/lib/supabase/types'

type Branch = Database['public']['Tables']['branches']['Row']
type Service = Database['public']['Tables']['services']['Row']
type Staff = Database['public']['Tables']['staff']['Row']

export async function getBranchInfo(branchId: string) {
  const supabase = createAdminClient()
  
  const { data, error } = await supabase
    .from('branches')
    .select('id, name, address, city, state, phone, business_hours, is_active')
    .eq('id', branchId)
    .single()
    
  if (error || !data) {
    console.error('Error fetching branch:', error)
    return null
  }
  
  return data
}

export async function getBranchServices(branchId: string) {
  const supabase = createAdminClient()
  
  const { data, error } = await supabase
    .from('services')
    .select(`
      id, name, description, duration_minutes, price, category_id,
      service_categories(name)
    `)
    .eq('branch_id', branchId)
    .eq('is_active', true)
    
  if (error) {
    console.error('Error fetching services:', error)
    return []
  }
  
  return data
}

export async function getBranchStaff(branchId: string) {
  const supabase = createAdminClient()
  
  const { data, error } = await supabase
    .from('staff')
    .select('id, name, is_active')
    .eq('branch_id', branchId)
    .eq('is_active', true)
    
  if (error) {
    console.error('Error fetching staff:', error)
    return []
  }
  
  return data
}

// In the future:
// export async function getAvailableSlots(branchId, serviceId, staffId, date) { ... }
// export async function createAppointment(data) { ... }
