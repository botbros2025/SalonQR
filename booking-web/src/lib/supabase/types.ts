export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      tenants: {
        Row: {
          id: string
          business_name: string
          schema_name: string
          status: 'TRIAL' | 'ACTIVE' | 'SUSPENDED' | 'PAST_DUE' | 'CANCELLED'
          owner_name: string
          owner_phone: string
          owner_email: string
          created_at: string
          updated_at: string
        }
      }
      branches: {
        Row: {
          id: string
          tenant_id: string
          name: string
          address: string
          city: string
          state: string
          pincode: string
          phone: string | null
          email: string | null
          business_hours: Json
          is_active: boolean
          created_at: string
          updated_at: string
        }
      }
      services: {
        Row: {
          id: string
          tenant_id: string
          category_id: string | null
          name: string
          description: string | null
          duration_minutes: number
          price: number
          is_active: boolean
          created_at: string
          updated_at: string
          branch_id: string
        }
      }
      service_categories: {
        Row: {
          id: string
          tenant_id: string
          name: string
          created_at: string
          updated_at: string
        }
      }
      staff: {
        Row: {
          id: string
          tenant_id: string
          user_id: string | null
          name: string
          phone: string
          auth_state: string
          is_active: boolean | null
          email: string | null
          created_at: string
          updated_at: string
          branch_id: string
        }
      }
      staff_shifts: {
        Row: {
          id: string
          tenant_id: string
          branch_id: string
          staff_id: string
          shift_date: string
          start_time: string
          end_time: string
          attendance_status: string | null
          created_at: string
          updated_at: string
        }
      }
      appointments: {
        Row: {
          id: string
          tenant_id: string
          branch_id: string
          client_id: string
          appointment_date: string
          start_time: string
          end_time: string
          status: 'SCHEDULED' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'BILLED' | 'CANCELLED' | 'NO_SHOW'
          source: string
          primary_staff_id: string | null
          notes: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          tenant_id: string
          branch_id: string
          client_id: string
          appointment_date: string
          start_time: string
          end_time: string
          status?: 'SCHEDULED' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'BILLED' | 'CANCELLED' | 'NO_SHOW'
          source?: string
          primary_staff_id?: string | null
          notes?: string | null
          created_by?: string
        }
      }
      clients: {
        Row: {
          id: string
          tenant_id: string
          name: string
          phone: string
          email: string | null
          created_at: string
          branch_id: string
        }
        Insert: {
          tenant_id: string
          name: string
          phone: string
          email?: string | null
          branch_id: string
        }
      }
    }
  }
}
