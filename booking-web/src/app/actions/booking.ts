'use server'

import { createClient } from '@supabase/supabase-js'
import { Database } from '@/lib/supabase/types'

type Branch = Database['public']['Tables']['branches']['Row']
type Service = Database['public']['Tables']['services']['Row']
type Staff = Database['public']['Tables']['staff']['Row']

// Helper to create an anonymous client
function getSupabase() {
  return createClient<any>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}


export async function getBranchBookingData(slug: string) {
  const supabase = getSupabase()
  
  const { data, error } = await (supabase.rpc as any)(
    'get_public_branch_booking_data', { p_slug: slug }
  )
    
  if (error || !data || !data.branch) {
    console.error('Error fetching branch booking data:', error)
    return null
  }
  
  return data as unknown as {
    branch: Branch;
    services: (Service & { service_categories: { name: string } | null })[];
    staff: (Staff & { rating?: number; review_count?: number })[];
  }
}

export async function getBranchInfo(slug: string) {
  // Can just reuse the single RPC to get branch info for metadata
  const data = await getBranchBookingData(slug)
  return data ? data.branch : null
}

// In the future:
export async function getStaffAppointments(branchId: string, staffId: string, date: string) {
  const supabase = getSupabase()
  
  const { data, error } = await (supabase.rpc as any)(
    'get_public_staff_appointments',
    { p_branch_id: branchId, p_staff_id: staffId, p_date: date }
  )

  if (error) {
    console.error('Error fetching staff appointments:', error)
    return []
  }
 // console.log(data)
  
  return data || []

}

// Create appointment and handle client lookup/creation
export async function createAppointment(data: {
  tenantId: string
  branchId: string
  customerName: string
  customerPhone: string
  appointmentDate: string
  startTime: string
  endTime: string
  staffId: string | null
  services: any[]
}) {
  const supabase = getSupabase()

  try {

    console.log("final booking"+JSON.stringify(data));
    const { data: responseData, error } = await (supabase.rpc as any)(
      'create_public_booking',
      {
        p_tenant_id: data.tenantId,
        p_branch_id: data.branchId,
        p_customer_name: data.customerName,
        p_customer_phone: data.customerPhone,
        p_appointment_date: data.appointmentDate,
        p_start_time: data.startTime,
        p_end_time: data.endTime,
        p_staff_id: data.staffId,
        p_services: data.services
      }
    )

    if (error) {
      console.error('RPC Error creating appointment:', error)
      return { success: false, error: 'Failed to create appointment' }
    }

    if (!responseData || !responseData.success) {
      console.error('Failed to create appointment:', responseData?.error)
      return { success: false, error: responseData?.error || 'Failed to create appointment' }
    }

    return { success: true, appointmentId: responseData.appointmentId, bookingId: responseData.bookingId }
  } catch (error) {
    console.error('Unexpected error creating appointment:', error)
    return { success: false, error: 'Unexpected error occurred' }
  }
}
