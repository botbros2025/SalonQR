export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      admin_users: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string
          email: string
          full_name: string | null
          id: string
          phone: string | null
          role: string
          updated_at: string | null
          username: string | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          email: string
          full_name?: string | null
          id: string
          phone?: string | null
          role?: string
          updated_at?: string | null
          username?: string | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          email?: string
          full_name?: string | null
          id?: string
          phone?: string | null
          role?: string
          updated_at?: string | null
          username?: string | null
        }
        Relationships: []
      }
      ai_model_config: {
        Row: {
          command: string
          created_at: string | null
          file_size: number | null
          id: string
          is_active: boolean | null
          minimum_app_version: string | null
          model_name: string
          model_url: string | null
          model_version: string
          platform: string
          sha256_checksum: string | null
          tenant_id: string
          updated_at: string | null
        }
        Insert: {
          command?: string
          created_at?: string | null
          file_size?: number | null
          id?: string
          is_active?: boolean | null
          minimum_app_version?: string | null
          model_name: string
          model_url?: string | null
          model_version: string
          platform: string
          sha256_checksum?: string | null
          tenant_id: string
          updated_at?: string | null
        }
        Update: {
          command?: string
          created_at?: string | null
          file_size?: number | null
          id?: string
          is_active?: boolean | null
          minimum_app_version?: string | null
          model_name?: string
          model_url?: string | null
          model_version?: string
          platform?: string
          sha256_checksum?: string | null
          tenant_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ai_model_config_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      appointment_services: {
        Row: {
          added_at: string
          added_by: string
          appointment_id: string
          branch_id: string
          duration_minutes: number
          id: string
          price: number
          removed_at: string | null
          removed_by: string | null
          service_id: string
          service_name: string
          staff_id: string | null
        }
        Insert: {
          added_at?: string
          added_by: string
          appointment_id: string
          branch_id: string
          duration_minutes: number
          id?: string
          price: number
          removed_at?: string | null
          removed_by?: string | null
          service_id: string
          service_name: string
          staff_id?: string | null
        }
        Update: {
          added_at?: string
          added_by?: string
          appointment_id?: string
          branch_id?: string
          duration_minutes?: number
          id?: string
          price?: number
          removed_at?: string | null
          removed_by?: string | null
          service_id?: string
          service_name?: string
          staff_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "appointment_services_added_by_fkey"
            columns: ["added_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_services_appointment_id_fkey"
            columns: ["appointment_id"]
            isOneToOne: false
            referencedRelation: "appointments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_services_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_services_removed_by_fkey"
            columns: ["removed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_services_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_services_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
        ]
      }
      appointments: {
        Row: {
          appointment_date: string
          billed_at: string | null
          branch_id: string
          cancellation_reason: string | null
          cancelled_at: string | null
          cancelled_by: string | null
          client_id: string
          completed_at: string | null
          confirmed_at: string | null
          created_at: string
          created_by: string
          end_time: string
          id: string
          internal_notes: string | null
          notes: string | null
          primary_staff_id: string | null
          source: Database["public"]["Enums"]["appointment_source"]
          start_time: string
          started_at: string | null
          status: Database["public"]["Enums"]["appointment_status"]
          tenant_id: string
          updated_at: string
        }
        Insert: {
          appointment_date: string
          billed_at?: string | null
          branch_id: string
          cancellation_reason?: string | null
          cancelled_at?: string | null
          cancelled_by?: string | null
          client_id: string
          completed_at?: string | null
          confirmed_at?: string | null
          created_at?: string
          created_by: string
          end_time: string
          id?: string
          internal_notes?: string | null
          notes?: string | null
          primary_staff_id?: string | null
          source?: Database["public"]["Enums"]["appointment_source"]
          start_time: string
          started_at?: string | null
          status?: Database["public"]["Enums"]["appointment_status"]
          tenant_id: string
          updated_at?: string
        }
        Update: {
          appointment_date?: string
          billed_at?: string | null
          branch_id?: string
          cancellation_reason?: string | null
          cancelled_at?: string | null
          cancelled_by?: string | null
          client_id?: string
          completed_at?: string | null
          confirmed_at?: string | null
          created_at?: string
          created_by?: string
          end_time?: string
          id?: string
          internal_notes?: string | null
          notes?: string | null
          primary_staff_id?: string | null
          source?: Database["public"]["Enums"]["appointment_source"]
          start_time?: string
          started_at?: string | null
          status?: Database["public"]["Enums"]["appointment_status"]
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "appointments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_cancelled_by_fkey"
            columns: ["cancelled_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_primary_staff_id_fkey"
            columns: ["primary_staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_logs: {
        Row: {
          action: string
          created_at: string
          id: string
          ip_address: unknown
          new_values: Json | null
          old_values: Json | null
          resource_id: string | null
          resource_type: string
          tenant_id: string
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          action: string
          created_at?: string
          id?: string
          ip_address?: unknown
          new_values?: Json | null
          old_values?: Json | null
          resource_id?: string | null
          resource_type: string
          tenant_id: string
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          action?: string
          created_at?: string
          id?: string
          ip_address?: unknown
          new_values?: Json | null
          old_values?: Json | null
          resource_id?: string | null
          resource_type?: string
          tenant_id?: string
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "audit_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      branches: {
        Row: {
          address: string | null
          business_hours: Json
          city: string | null
          created_at: string
          email: string | null
          id: string
          is_active: boolean
          name: string
          phone: string | null
          pincode: string | null
          state: string | null
          tenant_id: string
          updated_at: string
          website: string | null
        }
        Insert: {
          address?: string | null
          business_hours?: Json
          city?: string | null
          created_at?: string
          email?: string | null
          id?: string
          is_active?: boolean
          name: string
          phone?: string | null
          pincode?: string | null
          state?: string | null
          tenant_id: string
          updated_at?: string
          website?: string | null
        }
        Update: {
          address?: string | null
          business_hours?: Json
          city?: string | null
          created_at?: string
          email?: string | null
          id?: string
          is_active?: boolean
          name?: string
          phone?: string | null
          pincode?: string | null
          state?: string | null
          tenant_id?: string
          updated_at?: string
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "branches_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      client_notes: {
        Row: {
          branch_id: string
          client_id: string
          created_at: string
          created_by: string
          id: string
          note: string
          tenant_id: string
        }
        Insert: {
          branch_id: string
          client_id: string
          created_at?: string
          created_by: string
          id?: string
          note: string
          tenant_id: string
        }
        Update: {
          branch_id?: string
          client_id?: string
          created_at?: string
          created_by?: string
          id?: string
          note?: string
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "client_notes_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "client_notes_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "client_notes_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "client_notes_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      clients: {
        Row: {
          address: string | null
          branch_id: string
          city: string | null
          consent_for_marketing: boolean
          consent_given: boolean
          consent_given_at: string | null
          created_at: string
          data_retention_expires_at: string | null
          date_of_birth: string | null
          email: string | null
          gender: string | null
          id: string
          is_active: boolean
          last_visit_at: string | null
          name: string
          phone: string
          pincode: string | null
          preferred_staff_id: string | null
          referral_code: string | null
          source: Database["public"]["Enums"]["client_source"]
          tenant_id: string
          tier: Database["public"]["Enums"]["client_tier"]
          total_spend: number
          total_visits: number
          updated_at: string
        }
        Insert: {
          address?: string | null
          branch_id: string
          city?: string | null
          consent_for_marketing?: boolean
          consent_given?: boolean
          consent_given_at?: string | null
          created_at?: string
          data_retention_expires_at?: string | null
          date_of_birth?: string | null
          email?: string | null
          gender?: string | null
          id?: string
          is_active?: boolean
          last_visit_at?: string | null
          name: string
          phone: string
          pincode?: string | null
          preferred_staff_id?: string | null
          referral_code?: string | null
          source?: Database["public"]["Enums"]["client_source"]
          tenant_id: string
          tier?: Database["public"]["Enums"]["client_tier"]
          total_spend?: number
          total_visits?: number
          updated_at?: string
        }
        Update: {
          address?: string | null
          branch_id?: string
          city?: string | null
          consent_for_marketing?: boolean
          consent_given?: boolean
          consent_given_at?: string | null
          created_at?: string
          data_retention_expires_at?: string | null
          date_of_birth?: string | null
          email?: string | null
          gender?: string | null
          id?: string
          is_active?: boolean
          last_visit_at?: string | null
          name?: string
          phone?: string
          pincode?: string | null
          preferred_staff_id?: string | null
          referral_code?: string | null
          source?: Database["public"]["Enums"]["client_source"]
          tenant_id?: string
          tier?: Database["public"]["Enums"]["client_tier"]
          total_spend?: number
          total_visits?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "clients_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "clients_preferred_staff_id_fkey"
            columns: ["preferred_staff_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "clients_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      country_city_code_mapping: {
        Row: {
          cities: string[] | null
          city: string
          country_code: string
          created_at: string
          pincodes: string[] | null
          state_code: string
          updated_at: string
        }
        Insert: {
          cities?: string[] | null
          city?: string
          country_code: string
          created_at?: string
          pincodes?: string[] | null
          state_code: string
          updated_at?: string
        }
        Update: {
          cities?: string[] | null
          city?: string
          country_code?: string
          created_at?: string
          pincodes?: string[] | null
          state_code?: string
          updated_at?: string
        }
        Relationships: []
      }
      debug_logs: {
        Row: {
          created_at: string | null
          id: number
          message: string | null
        }
        Insert: {
          created_at?: string | null
          id?: number
          message?: string | null
        }
        Update: {
          created_at?: string | null
          id?: number
          message?: string | null
        }
        Relationships: []
      }
      feedback: {
        Row: {
          appointment_id: string
          branch_id: string
          client_id: string
          comment: string | null
          created_at: string
          id: string
          overall_rating: number
          responded_at: string | null
          responded_by: string | null
          response: string | null
          service_rating: number | null
          staff_id: string | null
          staff_rating: number | null
          status: string | null
          tags: Json | null
          tenant_id: string
          updated_at: string | null
        }
        Insert: {
          appointment_id: string
          branch_id: string
          client_id: string
          comment?: string | null
          created_at?: string
          id?: string
          overall_rating: number
          responded_at?: string | null
          responded_by?: string | null
          response?: string | null
          service_rating?: number | null
          staff_id?: string | null
          staff_rating?: number | null
          status?: string | null
          tags?: Json | null
          tenant_id: string
          updated_at?: string | null
        }
        Update: {
          appointment_id?: string
          branch_id?: string
          client_id?: string
          comment?: string | null
          created_at?: string
          id?: string
          overall_rating?: number
          responded_at?: string | null
          responded_by?: string | null
          response?: string | null
          service_rating?: number | null
          staff_id?: string | null
          staff_rating?: number | null
          status?: string | null
          tags?: Json | null
          tenant_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "feedback_appointment_id_fkey"
            columns: ["appointment_id"]
            isOneToOne: true
            referencedRelation: "appointments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feedback_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feedback_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feedback_responded_by_fkey"
            columns: ["responded_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feedback_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feedback_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      feedback_links: {
        Row: {
          appointment_id: string
          created_at: string | null
          expires_at: string | null
          id: string
          token: string
          used: boolean | null
        }
        Insert: {
          appointment_id: string
          created_at?: string | null
          expires_at?: string | null
          id?: string
          token: string
          used?: boolean | null
        }
        Update: {
          appointment_id?: string
          created_at?: string | null
          expires_at?: string | null
          id?: string
          token?: string
          used?: boolean | null
        }
        Relationships: []
      }
      inventory_items: {
        Row: {
          barcode: string | null
          branch_id: string | null
          cost_price: number
          created_at: string
          current_quantity: number
          description: string | null
          hsn_sac_code: string | null
          id: string
          is_active: boolean
          low_stock_alert_enabled: boolean
          min_quantity: number
          name: string
          reorder_quantity: number
          selling_price: number | null
          sku: string | null
          tax_rate: number | null
          tenant_id: string
          unit: Database["public"]["Enums"]["inventory_unit"]
          updated_at: string
        }
        Insert: {
          barcode?: string | null
          branch_id?: string | null
          cost_price?: number
          created_at?: string
          current_quantity?: number
          description?: string | null
          hsn_sac_code?: string | null
          id?: string
          is_active?: boolean
          low_stock_alert_enabled?: boolean
          min_quantity?: number
          name: string
          reorder_quantity?: number
          selling_price?: number | null
          sku?: string | null
          tax_rate?: number | null
          tenant_id: string
          unit?: Database["public"]["Enums"]["inventory_unit"]
          updated_at?: string
        }
        Update: {
          barcode?: string | null
          branch_id?: string | null
          cost_price?: number
          created_at?: string
          current_quantity?: number
          description?: string | null
          hsn_sac_code?: string | null
          id?: string
          is_active?: boolean
          low_stock_alert_enabled?: boolean
          min_quantity?: number
          name?: string
          reorder_quantity?: number
          selling_price?: number | null
          sku?: string | null
          tax_rate?: number | null
          tenant_id?: string
          unit?: Database["public"]["Enums"]["inventory_unit"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "inventory_items_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_items_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_transactions: {
        Row: {
          appointment_id: string | null
          branch_id: string | null
          created_at: string
          created_by: string
          id: string
          inventory_item_id: string
          notes: string | null
          purchase_order_id: string | null
          quantity: number
          quantity_after: number
          quantity_before: number
          tenant_id: string
          total_cost: number | null
          transaction_type: Database["public"]["Enums"]["transaction_type"]
          unit_cost: number | null
        }
        Insert: {
          appointment_id?: string | null
          branch_id?: string | null
          created_at?: string
          created_by: string
          id?: string
          inventory_item_id: string
          notes?: string | null
          purchase_order_id?: string | null
          quantity: number
          quantity_after: number
          quantity_before: number
          tenant_id: string
          total_cost?: number | null
          transaction_type: Database["public"]["Enums"]["transaction_type"]
          unit_cost?: number | null
        }
        Update: {
          appointment_id?: string | null
          branch_id?: string | null
          created_at?: string
          created_by?: string
          id?: string
          inventory_item_id?: string
          notes?: string | null
          purchase_order_id?: string | null
          quantity?: number
          quantity_after?: number
          quantity_before?: number
          tenant_id?: string
          total_cost?: number | null
          transaction_type?: Database["public"]["Enums"]["transaction_type"]
          unit_cost?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "inventory_transactions_appointment_id_fkey"
            columns: ["appointment_id"]
            isOneToOne: false
            referencedRelation: "appointments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_inventory_item_id_fkey"
            columns: ["inventory_item_id"]
            isOneToOne: false
            referencedRelation: "inventory_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_purchase_order_id_fkey"
            columns: ["purchase_order_id"]
            isOneToOne: false
            referencedRelation: "purchase_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      invoice_lines: {
        Row: {
          branch_id: string
          created_at: string
          description: string | null
          hsn_sac_code: string | null
          id: string
          invoice_id: string
          item_id: string | null
          item_name: string
          item_type: Database["public"]["Enums"]["line_item_type"]
          quantity: number
          staff_id: string | null
          subtotal: number
          tax_amount: number
          tax_rate: number
          total: number
          unit_price: number
        }
        Insert: {
          branch_id: string
          created_at?: string
          description?: string | null
          hsn_sac_code?: string | null
          id?: string
          invoice_id: string
          item_id?: string | null
          item_name: string
          item_type: Database["public"]["Enums"]["line_item_type"]
          quantity?: number
          staff_id?: string | null
          subtotal: number
          tax_amount?: number
          tax_rate?: number
          total: number
          unit_price: number
        }
        Update: {
          branch_id?: string
          created_at?: string
          description?: string | null
          hsn_sac_code?: string | null
          id?: string
          invoice_id?: string
          item_id?: string | null
          item_name?: string
          item_type?: Database["public"]["Enums"]["line_item_type"]
          quantity?: number
          staff_id?: string | null
          subtotal?: number
          tax_amount?: number
          tax_rate?: number
          total?: number
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "invoice_lines_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoice_lines_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoice_lines_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      invoices: {
        Row: {
          appointment_id: string | null
          balance_amount: number
          branch_id: string
          cgst: number
          client_id: string
          created_at: string
          created_by: string
          discount_amount: number
          discount_percentage: number
          gstin_applied: boolean
          id: string
          igst: number
          invoice_date: string
          invoice_number: string
          notes: string | null
          paid_amount: number
          pdf_url: string | null
          place_of_supply: string | null
          sgst: number
          status: Database["public"]["Enums"]["invoice_status"]
          subtotal: number
          tax_amount: number
          tax_percent: number | null
          tenant_id: string
          terms_and_conditions: string | null
          total_amount: number
          updated_at: string
        }
        Insert: {
          appointment_id?: string | null
          balance_amount?: number
          branch_id: string
          cgst?: number
          client_id: string
          created_at?: string
          created_by: string
          discount_amount?: number
          discount_percentage?: number
          gstin_applied?: boolean
          id?: string
          igst?: number
          invoice_date?: string
          invoice_number: string
          notes?: string | null
          paid_amount?: number
          pdf_url?: string | null
          place_of_supply?: string | null
          sgst?: number
          status?: Database["public"]["Enums"]["invoice_status"]
          subtotal?: number
          tax_amount?: number
          tax_percent?: number | null
          tenant_id: string
          terms_and_conditions?: string | null
          total_amount?: number
          updated_at?: string
        }
        Update: {
          appointment_id?: string | null
          balance_amount?: number
          branch_id?: string
          cgst?: number
          client_id?: string
          created_at?: string
          created_by?: string
          discount_amount?: number
          discount_percentage?: number
          gstin_applied?: boolean
          id?: string
          igst?: number
          invoice_date?: string
          invoice_number?: string
          notes?: string | null
          paid_amount?: number
          pdf_url?: string | null
          place_of_supply?: string | null
          sgst?: number
          status?: Database["public"]["Enums"]["invoice_status"]
          subtotal?: number
          tax_amount?: number
          tax_percent?: number | null
          tenant_id?: string
          terms_and_conditions?: string | null
          total_amount?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "invoices_appointment_id_fkey"
            columns: ["appointment_id"]
            isOneToOne: false
            referencedRelation: "appointments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_logs: {
        Row: {
          appointment_id: string | null
          body: string
          branch_id: string
          channel: Database["public"]["Enums"]["notification_channel"]
          created_at: string
          delivered_at: string | null
          error_message: string | null
          failed_at: string | null
          id: string
          invoice_id: string | null
          provider_message_id: string | null
          provider_response: Json | null
          read_at: string | null
          recipient_email: string | null
          recipient_id: string | null
          recipient_name: string | null
          recipient_phone: string | null
          sent_at: string | null
          status: Database["public"]["Enums"]["notification_status"]
          subject: string | null
          template_type: Database["public"]["Enums"]["template_type"] | null
          tenant_id: string
        }
        Insert: {
          appointment_id?: string | null
          body: string
          branch_id: string
          channel: Database["public"]["Enums"]["notification_channel"]
          created_at?: string
          delivered_at?: string | null
          error_message?: string | null
          failed_at?: string | null
          id?: string
          invoice_id?: string | null
          provider_message_id?: string | null
          provider_response?: Json | null
          read_at?: string | null
          recipient_email?: string | null
          recipient_id?: string | null
          recipient_name?: string | null
          recipient_phone?: string | null
          sent_at?: string | null
          status?: Database["public"]["Enums"]["notification_status"]
          subject?: string | null
          template_type?: Database["public"]["Enums"]["template_type"] | null
          tenant_id: string
        }
        Update: {
          appointment_id?: string | null
          body?: string
          branch_id?: string
          channel?: Database["public"]["Enums"]["notification_channel"]
          created_at?: string
          delivered_at?: string | null
          error_message?: string | null
          failed_at?: string | null
          id?: string
          invoice_id?: string | null
          provider_message_id?: string | null
          provider_response?: Json | null
          read_at?: string | null
          recipient_email?: string | null
          recipient_id?: string | null
          recipient_name?: string | null
          recipient_phone?: string | null
          sent_at?: string | null
          status?: Database["public"]["Enums"]["notification_status"]
          subject?: string | null
          template_type?: Database["public"]["Enums"]["template_type"] | null
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_logs_appointment_id_fkey"
            columns: ["appointment_id"]
            isOneToOne: false
            referencedRelation: "appointments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_logs_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_logs_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_logs_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_templates: {
        Row: {
          body: string
          branch_id: string | null
          channel: Database["public"]["Enums"]["notification_channel"]
          created_at: string
          id: string
          is_active: boolean
          is_system_default: boolean
          name: string
          provider_template_id: string | null
          subject: string | null
          tenant_id: string | null
          type: string
          updated_at: string
        }
        Insert: {
          body: string
          branch_id?: string | null
          channel: Database["public"]["Enums"]["notification_channel"]
          created_at?: string
          id?: string
          is_active?: boolean
          is_system_default?: boolean
          name: string
          provider_template_id?: string | null
          subject?: string | null
          tenant_id?: string | null
          type: string
          updated_at?: string
        }
        Update: {
          body?: string
          branch_id?: string | null
          channel?: Database["public"]["Enums"]["notification_channel"]
          created_at?: string
          id?: string
          is_active?: boolean
          is_system_default?: boolean
          name?: string
          provider_template_id?: string | null
          subject?: string | null
          tenant_id?: string | null
          type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_templates_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_templates_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          body: string
          branch_id: string | null
          channel: string
          created_at: string
          id: string
          is_read: boolean
          metadata: Json | null
          read_at: string | null
          reference_id: string | null
          reference_type: string | null
          staff_id: string | null
          template_id: string | null
          tenant_id: string
          title: string
          type: string
          user_id: string | null
        }
        Insert: {
          body: string
          branch_id?: string | null
          channel?: string
          created_at?: string
          id?: string
          is_read?: boolean
          metadata?: Json | null
          read_at?: string | null
          reference_id?: string | null
          reference_type?: string | null
          staff_id?: string | null
          template_id?: string | null
          tenant_id: string
          title: string
          type: string
          user_id?: string | null
        }
        Update: {
          body?: string
          branch_id?: string | null
          channel?: string
          created_at?: string
          id?: string
          is_read?: boolean
          metadata?: Json | null
          read_at?: string | null
          reference_id?: string | null
          reference_type?: string | null
          staff_id?: string | null
          template_id?: string | null
          tenant_id?: string
          title?: string
          type?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "notifications_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "notification_templates"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount: number
          branch_id: string
          created_at: string
          created_by: string
          id: string
          invoice_id: string
          notes: string | null
          payment_date: string
          payment_method: Database["public"]["Enums"]["payment_method"]
          reference_number: string | null
          tenant_id: string
          transaction_id: string | null
        }
        Insert: {
          amount: number
          branch_id: string
          created_at?: string
          created_by: string
          id?: string
          invoice_id: string
          notes?: string | null
          payment_date?: string
          payment_method: Database["public"]["Enums"]["payment_method"]
          reference_number?: string | null
          tenant_id: string
          transaction_id?: string | null
        }
        Update: {
          amount?: number
          branch_id?: string
          created_at?: string
          created_by?: string
          id?: string
          invoice_id?: string
          notes?: string | null
          payment_date?: string
          payment_method?: Database["public"]["Enums"]["payment_method"]
          reference_number?: string | null
          tenant_id?: string
          transaction_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      permissions: {
        Row: {
          action: string
          created_at: string
          description: string | null
          id: string
          resource: string
        }
        Insert: {
          action: string
          created_at?: string
          description?: string | null
          id?: string
          resource: string
        }
        Update: {
          action?: string
          created_at?: string
          description?: string | null
          id?: string
          resource?: string
        }
        Relationships: []
      }
      purchase_order_lines: {
        Row: {
          branch_id: string
          created_at: string
          id: string
          inventory_item_id: string
          purchase_order_id: string
          quantity: number
          quantity_received: number | null
          subtotal: number
          tax_amount: number
          tax_rate: number
          total: number
          unit_price: number
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          inventory_item_id: string
          purchase_order_id: string
          quantity: number
          quantity_received?: number | null
          subtotal: number
          tax_amount: number
          tax_rate?: number
          total: number
          unit_price: number
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          inventory_item_id?: string
          purchase_order_id?: string
          quantity?: number
          quantity_received?: number | null
          subtotal?: number
          tax_amount?: number
          tax_rate?: number
          total?: number
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "purchase_order_lines_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_order_lines_inventory_item_id_fkey"
            columns: ["inventory_item_id"]
            isOneToOne: false
            referencedRelation: "inventory_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_order_lines_purchase_order_id_fkey"
            columns: ["purchase_order_id"]
            isOneToOne: false
            referencedRelation: "purchase_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      purchase_orders: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          branch_id: string
          created_at: string
          created_by: string
          expected_delivery_date: string | null
          id: string
          notes: string | null
          order_date: string | null
          po_number: string
          received_date: string | null
          status: Database["public"]["Enums"]["po_status"]
          subtotal: number
          tax_amount: number
          tenant_id: string
          total_amount: number
          updated_at: string
          vendor_contact: string | null
          vendor_name: string
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          branch_id: string
          created_at?: string
          created_by: string
          expected_delivery_date?: string | null
          id?: string
          notes?: string | null
          order_date?: string | null
          po_number: string
          received_date?: string | null
          status?: Database["public"]["Enums"]["po_status"]
          subtotal?: number
          tax_amount?: number
          tenant_id: string
          total_amount?: number
          updated_at?: string
          vendor_contact?: string | null
          vendor_name: string
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          branch_id?: string
          created_at?: string
          created_by?: string
          expected_delivery_date?: string | null
          id?: string
          notes?: string | null
          order_date?: string | null
          po_number?: string
          received_date?: string | null
          status?: Database["public"]["Enums"]["po_status"]
          subtotal?: number
          tax_amount?: number
          tenant_id?: string
          total_amount?: number
          updated_at?: string
          vendor_contact?: string | null
          vendor_name?: string
        }
        Relationships: [
          {
            foreignKeyName: "purchase_orders_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_orders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_orders_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_orders_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      revenue_report_logs: {
        Row: {
          branch_id: string
          created_at: string
          id: string
          invoice_count: number
          paid_revenue: number
          pending_revenue: number
          report_date: string
          tenant_id: string
          total_revenue: number
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          invoice_count?: number
          paid_revenue?: number
          pending_revenue?: number
          report_date: string
          tenant_id: string
          total_revenue?: number
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          invoice_count?: number
          paid_revenue?: number
          pending_revenue?: number
          report_date?: string
          tenant_id?: string
          total_revenue?: number
        }
        Relationships: [
          {
            foreignKeyName: "revenue_report_logs_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "revenue_report_logs_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      review_media: {
        Row: {
          created_at: string | null
          id: string
          media_type: string | null
          review_id: string
          uploaded_by: string | null
          url: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          media_type?: string | null
          review_id: string
          uploaded_by?: string | null
          url: string
        }
        Update: {
          created_at?: string | null
          id?: string
          media_type?: string | null
          review_id?: string
          uploaded_by?: string | null
          url?: string
        }
        Relationships: [
          {
            foreignKeyName: "review_media_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "feedback"
            referencedColumns: ["id"]
          },
        ]
      }
      review_services: {
        Row: {
          created_at: string | null
          id: string
          rating: number
          review_id: string
          service_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          rating: number
          review_id: string
          service_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          rating?: number
          review_id?: string
          service_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "review_services_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "feedback"
            referencedColumns: ["id"]
          },
        ]
      }
      role_name: {
        Row: {
          name: string | null
        }
        Insert: {
          name?: string | null
        }
        Update: {
          name?: string | null
        }
        Relationships: []
      }
      role_permissions: {
        Row: {
          created_at: string
          permission_id: string
          role_id: string
        }
        Insert: {
          created_at?: string
          permission_id: string
          role_id: string
        }
        Update: {
          created_at?: string
          permission_id?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "role_permissions_permission_id_fkey"
            columns: ["permission_id"]
            isOneToOne: false
            referencedRelation: "permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "role_permissions_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
      roles: {
        Row: {
          created_at: string
          description: string | null
          id: string
          is_system_role: boolean
          name: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          is_system_role?: boolean
          name: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          is_system_role?: boolean
          name?: string
        }
        Relationships: []
      }
      service_categories: {
        Row: {
          branch_id: string
          created_at: string
          description: string | null
          display_order: number
          id: string
          image_url: string | null
          is_active: boolean
          name: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          description?: string | null
          display_order?: number
          id?: string
          image_url?: string | null
          is_active?: boolean
          name: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          description?: string | null
          display_order?: number
          id?: string
          image_url?: string | null
          is_active?: boolean
          name?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_categories_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_categories_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      service_inventory_items: {
        Row: {
          branch_id: string | null
          created_at: string
          id: string
          inventory_item_id: string
          quantity_per_service: number
          service_id: string
        }
        Insert: {
          branch_id?: string | null
          created_at?: string
          id?: string
          inventory_item_id: string
          quantity_per_service?: number
          service_id: string
        }
        Update: {
          branch_id?: string | null
          created_at?: string
          id?: string
          inventory_item_id?: string
          quantity_per_service?: number
          service_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_inventory_items_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_inventory_items_inventory_item_id_fkey"
            columns: ["inventory_item_id"]
            isOneToOne: false
            referencedRelation: "inventory_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_inventory_items_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      service_variants: {
        Row: {
          branch_id: string
          created_at: string
          duration_minutes: number
          id: string
          is_default: boolean | null
          name: string
          price: number
          service_id: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          duration_minutes: number
          id?: string
          is_default?: boolean | null
          name: string
          price: number
          service_id: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          duration_minutes?: number
          id?: string
          is_default?: boolean | null
          name?: string
          price?: number
          service_id?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_variants_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      services: {
        Row: {
          branch_id: string
          category_id: string | null
          color_theme: string | null
          created_at: string
          description: string | null
          duration_minutes: number
          hsn_sac_code: string | null
          id: string
          is_active: boolean
          name: string
          price: number
          tax_rate: number | null
          tenant_id: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          category_id?: string | null
          color_theme?: string | null
          created_at?: string
          description?: string | null
          duration_minutes: number
          hsn_sac_code?: string | null
          id?: string
          is_active?: boolean
          name: string
          price: number
          tax_rate?: number | null
          tenant_id: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          category_id?: string | null
          color_theme?: string | null
          created_at?: string
          description?: string | null
          duration_minutes?: number
          hsn_sac_code?: string | null
          id?: string
          is_active?: boolean
          name?: string
          price?: number
          tax_rate?: number | null
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "services_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "service_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      shift_templates: {
        Row: {
          branch_id: string
          created_at: string
          end_time: string
          id: string
          name: string
          start_time: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          end_time: string
          id?: string
          name: string
          start_time: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          end_time?: string
          id?: string
          name?: string
          start_time?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shift_templates_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shift_templates_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      social_accounts: {
        Row: {
          created_at: string | null
          handle: string
          id: string
          platform: string
          tenant_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          handle: string
          id?: string
          platform: string
          tenant_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          handle?: string
          id?: string
          platform?: string
          tenant_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "social_accounts_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff: {
        Row: {
          auth_state: Database["public"]["Enums"]["staff_auth_state"]
          branch_id: string
          created_at: string
          deleted_at: string | null
          email: string | null
          employee_code: string | null
          id: string
          invite_expiry: string | null
          invite_token: string | null
          is_active: boolean | null
          join_date: string | null
          last_invite_id: string | null
          name: string
          phone: string
          role: string | null
          salary: number | null
          system_role: string | null
          tenant_id: string
          updated_at: string
          user_id: string | null
        }
        Insert: {
          auth_state?: Database["public"]["Enums"]["staff_auth_state"]
          branch_id: string
          created_at?: string
          deleted_at?: string | null
          email?: string | null
          employee_code?: string | null
          id?: string
          invite_expiry?: string | null
          invite_token?: string | null
          is_active?: boolean | null
          join_date?: string | null
          last_invite_id?: string | null
          name: string
          phone: string
          role?: string | null
          salary?: number | null
          system_role?: string | null
          tenant_id: string
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          auth_state?: Database["public"]["Enums"]["staff_auth_state"]
          branch_id?: string
          created_at?: string
          deleted_at?: string | null
          email?: string | null
          employee_code?: string | null
          id?: string
          invite_expiry?: string | null
          invite_token?: string | null
          is_active?: boolean | null
          join_date?: string | null
          last_invite_id?: string | null
          name?: string
          phone?: string
          role?: string | null
          salary?: number | null
          system_role?: string | null
          tenant_id?: string
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "staff_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_last_invite_fk"
            columns: ["last_invite_id"]
            isOneToOne: false
            referencedRelation: "staff_invites"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_code_counter: {
        Row: {
          last_number: number
          year: string
        }
        Insert: {
          last_number?: number
          year: string
        }
        Update: {
          last_number?: number
          year?: string
        }
        Relationships: []
      }
      staff_compensation: {
        Row: {
          branch_id: string
          created_at: string
          deleted_at: string | null
          earning_type: string
          effective_from: string
          effective_to: string | null
          id: string
          is_active: boolean
          revenue_share_percent: number | null
          salary_amount: number | null
          staff_id: string
          target_amount: number | null
          target_commission_percent: number | null
          tenant_id: string
          updated_at: string
          user_id: string | null
        }
        Insert: {
          branch_id: string
          created_at?: string
          deleted_at?: string | null
          earning_type: string
          effective_from?: string
          effective_to?: string | null
          id?: string
          is_active?: boolean
          revenue_share_percent?: number | null
          salary_amount?: number | null
          staff_id: string
          target_amount?: number | null
          target_commission_percent?: number | null
          tenant_id: string
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          branch_id?: string
          created_at?: string
          deleted_at?: string | null
          earning_type?: string
          effective_from?: string
          effective_to?: string | null
          id?: string
          is_active?: boolean
          revenue_share_percent?: number | null
          salary_amount?: number | null
          staff_id?: string
          target_amount?: number | null
          target_commission_percent?: number | null
          tenant_id?: string
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "staff_compensation_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_compensation_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_compensation_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_invites: {
        Row: {
          created_at: string | null
          expires_at: string
          id: string
          staff_id: string
          token: string
          used: boolean | null
        }
        Insert: {
          created_at?: string | null
          expires_at: string
          id?: string
          staff_id: string
          token: string
          used?: boolean | null
        }
        Update: {
          created_at?: string | null
          expires_at?: string
          id?: string
          staff_id?: string
          token?: string
          used?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "staff_invites_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_metrics: {
        Row: {
          average_rating: number | null
          branch_id: string
          cancelled_appointments: number
          completed_appointments: number
          created_at: string
          metric_month: number
          metric_year: number
          staff_id: string
          tenant_id: string
          tips_received: number
          total_appointments: number
          total_ratings: number
          total_revenue_generated: number
          unverified_revenue: number
          updated_at: string
          verified_revenue: number
        }
        Insert: {
          average_rating?: number | null
          branch_id: string
          cancelled_appointments?: number
          completed_appointments?: number
          created_at?: string
          metric_month: number
          metric_year: number
          staff_id: string
          tenant_id: string
          tips_received?: number
          total_appointments?: number
          total_ratings?: number
          total_revenue_generated?: number
          unverified_revenue?: number
          updated_at?: string
          verified_revenue?: number
        }
        Update: {
          average_rating?: number | null
          branch_id?: string
          cancelled_appointments?: number
          completed_appointments?: number
          created_at?: string
          metric_month?: number
          metric_year?: number
          staff_id?: string
          tenant_id?: string
          tips_received?: number
          total_appointments?: number
          total_ratings?: number
          total_revenue_generated?: number
          unverified_revenue?: number
          updated_at?: string
          verified_revenue?: number
        }
        Relationships: [
          {
            foreignKeyName: "staff_metrics_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_metrics_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_metrics_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_profile: {
        Row: {
          account_holder_name: string | null
          account_number: string | null
          bio: string | null
          created_at: string | null
          dummy: string | null
          dummy1: string | null
          dummy10: string | null
          dummy11: string | null
          dummy12: string | null
          dummy13: string | null
          dummy14: string | null
          dummy15: string | null
          dummy16: string | null
          dummy2: string | null
          dummy3: string | null
          dummy4: string | null
          dummy5: string | null
          dummy6: string | null
          dummy7: string | null
          dummy8: string | null
          dummy9: string | null
          emergency_contact_name: string | null
          emergency_contact_phone: string | null
          emergency_contact_relation: string | null
          experience_years: number | null
          facebook: string | null
          ifsc_code: string | null
          instagram: string | null
          job_title: string | null
          pan_number: string | null
          shift_end: string | null
          shift_start: string | null
          specializations: Json | null
          staff_id: string
          updated_at: string | null
          upi_id: string | null
          website: string | null
        }
        Insert: {
          account_holder_name?: string | null
          account_number?: string | null
          bio?: string | null
          created_at?: string | null
          dummy?: string | null
          dummy1?: string | null
          dummy10?: string | null
          dummy11?: string | null
          dummy12?: string | null
          dummy13?: string | null
          dummy14?: string | null
          dummy15?: string | null
          dummy16?: string | null
          dummy2?: string | null
          dummy3?: string | null
          dummy4?: string | null
          dummy5?: string | null
          dummy6?: string | null
          dummy7?: string | null
          dummy8?: string | null
          dummy9?: string | null
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          emergency_contact_relation?: string | null
          experience_years?: number | null
          facebook?: string | null
          ifsc_code?: string | null
          instagram?: string | null
          job_title?: string | null
          pan_number?: string | null
          shift_end?: string | null
          shift_start?: string | null
          specializations?: Json | null
          staff_id: string
          updated_at?: string | null
          upi_id?: string | null
          website?: string | null
        }
        Update: {
          account_holder_name?: string | null
          account_number?: string | null
          bio?: string | null
          created_at?: string | null
          dummy?: string | null
          dummy1?: string | null
          dummy10?: string | null
          dummy11?: string | null
          dummy12?: string | null
          dummy13?: string | null
          dummy14?: string | null
          dummy15?: string | null
          dummy16?: string | null
          dummy2?: string | null
          dummy3?: string | null
          dummy4?: string | null
          dummy5?: string | null
          dummy6?: string | null
          dummy7?: string | null
          dummy8?: string | null
          dummy9?: string | null
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          emergency_contact_relation?: string | null
          experience_years?: number | null
          facebook?: string | null
          ifsc_code?: string | null
          instagram?: string | null
          job_title?: string | null
          pan_number?: string | null
          shift_end?: string | null
          shift_start?: string | null
          specializations?: Json | null
          staff_id?: string
          updated_at?: string | null
          upi_id?: string | null
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "staff_profile_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: true
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_salary_adjustments: {
        Row: {
          adjustment_month: number
          adjustment_type: string
          adjustment_year: number
          amount: number
          branch_id: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          reason: string | null
          staff_id: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          adjustment_month: number
          adjustment_type: string
          adjustment_year: number
          amount: number
          branch_id: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          reason?: string | null
          staff_id: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          adjustment_month?: number
          adjustment_type?: string
          adjustment_year?: number
          amount?: number
          branch_id?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          reason?: string | null
          staff_id?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "staff_salary_adjustments_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_salary_adjustments_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_salary_adjustments_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_salary_slips: {
        Row: {
          base_salary: number
          bonus_amount: number
          branch_id: string
          commission_amount: number
          compensation_id: string | null
          created_at: string
          deduction_amount: number
          deleted_at: string | null
          generated_revenue: number
          id: string
          net_salary: number
          notes: string | null
          paid_at: string | null
          payment_status: string
          salary_month: number
          salary_year: number
          staff_id: string
          tenant_id: string
          tip_amount: number
          updated_at: string
        }
        Insert: {
          base_salary?: number
          bonus_amount?: number
          branch_id: string
          commission_amount?: number
          compensation_id?: string | null
          created_at?: string
          deduction_amount?: number
          deleted_at?: string | null
          generated_revenue?: number
          id?: string
          net_salary: number
          notes?: string | null
          paid_at?: string | null
          payment_status?: string
          salary_month: number
          salary_year: number
          staff_id: string
          tenant_id: string
          tip_amount?: number
          updated_at?: string
        }
        Update: {
          base_salary?: number
          bonus_amount?: number
          branch_id?: string
          commission_amount?: number
          compensation_id?: string | null
          created_at?: string
          deduction_amount?: number
          deleted_at?: string | null
          generated_revenue?: number
          id?: string
          net_salary?: number
          notes?: string | null
          paid_at?: string | null
          payment_status?: string
          salary_month?: number
          salary_year?: number
          staff_id?: string
          tenant_id?: string
          tip_amount?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "staff_salary_slips_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_salary_slips_compensation_id_fkey"
            columns: ["compensation_id"]
            isOneToOne: false
            referencedRelation: "staff_compensation"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_salary_slips_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_salary_slips_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_shift_rules: {
        Row: {
          branch_id: string
          created_at: string | null
          effective_from: string
          effective_to: string | null
          end_time: string
          id: string
          is_active: boolean | null
          repeat_type: string
          staff_id: string
          start_time: string
          tenant_id: string
          updated_at: string | null
          weekday: string | null
        }
        Insert: {
          branch_id: string
          created_at?: string | null
          effective_from: string
          effective_to?: string | null
          end_time: string
          id?: string
          is_active?: boolean | null
          repeat_type: string
          staff_id: string
          start_time: string
          tenant_id: string
          updated_at?: string | null
          weekday?: string | null
        }
        Update: {
          branch_id?: string
          created_at?: string | null
          effective_from?: string
          effective_to?: string | null
          end_time?: string
          id?: string
          is_active?: boolean | null
          repeat_type?: string
          staff_id?: string
          start_time?: string
          tenant_id?: string
          updated_at?: string | null
          weekday?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_rule_branch"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_rule_staff"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_rule_tenant"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_shift_rules_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_shifts: {
        Row: {
          attendance_status: string | null
          branch_id: string
          created_at: string
          end_time: string
          id: string
          marked_at: string | null
          marked_by: string | null
          notes: string | null
          punch_in_at: string | null
          punch_out_at: string | null
          shift_date: string
          staff_id: string
          start_time: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          attendance_status?: string | null
          branch_id: string
          created_at?: string
          end_time: string
          id?: string
          marked_at?: string | null
          marked_by?: string | null
          notes?: string | null
          punch_in_at?: string | null
          punch_out_at?: string | null
          shift_date: string
          staff_id: string
          start_time: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          attendance_status?: string | null
          branch_id?: string
          created_at?: string
          end_time?: string
          id?: string
          marked_at?: string | null
          marked_by?: string | null
          notes?: string | null
          punch_in_at?: string | null
          punch_out_at?: string | null
          shift_date?: string
          staff_id?: string
          start_time?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "staff_shifts_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_shifts_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_shifts_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      subscriptions: {
        Row: {
          amount: number
          billing_cycle: string
          cancelled_at: string | null
          created_at: string
          currency: string
          current_period_end: string
          current_period_start: string
          id: string
          razorpay_customer_id: string | null
          razorpay_plan_id: string | null
          razorpay_subscription_id: string | null
          status: Database["public"]["Enums"]["subscription_status"]
          tenant_id: string
          trial_end: string | null
          updated_at: string
        }
        Insert: {
          amount?: number
          billing_cycle?: string
          cancelled_at?: string | null
          created_at?: string
          currency?: string
          current_period_end: string
          current_period_start?: string
          id?: string
          razorpay_customer_id?: string | null
          razorpay_plan_id?: string | null
          razorpay_subscription_id?: string | null
          status?: Database["public"]["Enums"]["subscription_status"]
          tenant_id: string
          trial_end?: string | null
          updated_at?: string
        }
        Update: {
          amount?: number
          billing_cycle?: string
          cancelled_at?: string | null
          created_at?: string
          currency?: string
          current_period_end?: string
          current_period_start?: string
          id?: string
          razorpay_customer_id?: string | null
          razorpay_plan_id?: string | null
          razorpay_subscription_id?: string | null
          status?: Database["public"]["Enums"]["subscription_status"]
          tenant_id?: string
          trial_end?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      support_categories: {
        Row: {
          created_at: string
          description: string | null
          display_order: number
          icon: string | null
          id: string
          is_active: boolean
          name: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          display_order?: number
          icon?: string | null
          id?: string
          is_active?: boolean
          name: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          display_order?: number
          icon?: string | null
          id?: string
          is_active?: boolean
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      support_faqs: {
        Row: {
          answer: string
          category_id: string
          created_at: string
          display_order: number
          id: string
          is_active: boolean
          question: string
          subcategory_id: string | null
          updated_at: string
        }
        Insert: {
          answer: string
          category_id: string
          created_at?: string
          display_order?: number
          id?: string
          is_active?: boolean
          question: string
          subcategory_id?: string | null
          updated_at?: string
        }
        Update: {
          answer?: string
          category_id?: string
          created_at?: string
          display_order?: number
          id?: string
          is_active?: boolean
          question?: string
          subcategory_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_faqs_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "support_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "support_faqs_subcategory_fk"
            columns: ["subcategory_id", "category_id"]
            isOneToOne: false
            referencedRelation: "support_subcategories"
            referencedColumns: ["id", "category_id"]
          },
        ]
      }
      support_flow_nodes: {
        Row: {
          created_at: string
          flow_id: string
          id: string
          message: string
          metadata: Json
          node_type: string
          sort_order: number
        }
        Insert: {
          created_at?: string
          flow_id: string
          id?: string
          message: string
          metadata?: Json
          node_type: string
          sort_order?: number
        }
        Update: {
          created_at?: string
          flow_id?: string
          id?: string
          message?: string
          metadata?: Json
          node_type?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "support_flow_nodes_flow_id_fkey"
            columns: ["flow_id"]
            isOneToOne: false
            referencedRelation: "support_flows"
            referencedColumns: ["id"]
          },
        ]
      }
      support_flow_options: {
        Row: {
          created_at: string
          id: string
          label: string
          metadata: Json
          next_node_id: string | null
          node_id: string
          sort_order: number
          value: string
        }
        Insert: {
          created_at?: string
          id?: string
          label: string
          metadata?: Json
          next_node_id?: string | null
          node_id: string
          sort_order?: number
          value: string
        }
        Update: {
          created_at?: string
          id?: string
          label?: string
          metadata?: Json
          next_node_id?: string | null
          node_id?: string
          sort_order?: number
          value?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_flow_options_next_node_id_fkey"
            columns: ["next_node_id"]
            isOneToOne: false
            referencedRelation: "support_flow_nodes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "support_flow_options_node_id_fkey"
            columns: ["node_id"]
            isOneToOne: false
            referencedRelation: "support_flow_nodes"
            referencedColumns: ["id"]
          },
        ]
      }
      support_flows: {
        Row: {
          category: string
          created_at: string
          id: string
          is_active: boolean
          name: string
          updated_at: string
          version: number
        }
        Insert: {
          category: string
          created_at?: string
          id?: string
          is_active?: boolean
          name: string
          updated_at?: string
          version?: number
        }
        Update: {
          category?: string
          created_at?: string
          id?: string
          is_active?: boolean
          name?: string
          updated_at?: string
          version?: number
        }
        Relationships: []
      }
      support_subcategories: {
        Row: {
          category_id: string
          created_at: string
          description: string | null
          display_order: number
          id: string
          is_active: boolean
          name: string
          updated_at: string
        }
        Insert: {
          category_id: string
          created_at?: string
          description?: string | null
          display_order?: number
          id?: string
          is_active?: boolean
          name: string
          updated_at?: string
        }
        Update: {
          category_id?: string
          created_at?: string
          description?: string | null
          display_order?: number
          id?: string
          is_active?: boolean
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_subcategories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "support_categories"
            referencedColumns: ["id"]
          },
        ]
      }
      support_ticket_messages: {
        Row: {
          attachment_url: string | null
          created_at: string | null
          id: string
          message: string
          sender_id: string
          sender_type: string | null
          ticket_id: string
        }
        Insert: {
          attachment_url?: string | null
          created_at?: string | null
          id?: string
          message: string
          sender_id: string
          sender_type?: string | null
          ticket_id: string
        }
        Update: {
          attachment_url?: string | null
          created_at?: string | null
          id?: string
          message?: string
          sender_id?: string
          sender_type?: string | null
          ticket_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_ticket_messages_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "support_tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      support_tickets: {
        Row: {
          attachment_url: string | null
          branch_id: string | null
          category: string | null
          created_at: string | null
          description: string
          id: string
          last_message_at: string | null
          last_message_id: string | null
          priority: string | null
          resolved_at: string | null
          resolved_by: string | null
          status: string | null
          subject: string
          tenant_id: string
          ticket_number: number
          updated_at: string | null
          user_id: string
        }
        Insert: {
          attachment_url?: string | null
          branch_id?: string | null
          category?: string | null
          created_at?: string | null
          description: string
          id?: string
          last_message_at?: string | null
          last_message_id?: string | null
          priority?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string | null
          subject: string
          tenant_id: string
          ticket_number?: never
          updated_at?: string | null
          user_id: string
        }
        Update: {
          attachment_url?: string | null
          branch_id?: string | null
          category?: string | null
          created_at?: string | null
          description?: string
          id?: string
          last_message_at?: string | null
          last_message_id?: string | null
          priority?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string | null
          subject?: string
          tenant_id?: string
          ticket_number?: never
          updated_at?: string | null
          user_id?: string
        }
        Relationships: []
      }
      tax_rates: {
        Row: {
          active: boolean | null
          cgst: number
          created_at: string | null
          id: string
          name: string
          sgst: number
          total: number | null
        }
        Insert: {
          active?: boolean | null
          cgst?: number
          created_at?: string | null
          id?: string
          name: string
          sgst?: number
          total?: number | null
        }
        Update: {
          active?: boolean | null
          cgst?: number
          created_at?: string | null
          id?: string
          name?: string
          sgst?: number
          total?: number | null
        }
        Relationships: []
      }
      tenant_settings: {
        Row: {
          advance_booking_days: number
          appointment_buffer_minutes: number
          cancellation_policy: string | null
          created_at: string
          daily_report_enabled: boolean
          daily_report_time: string
          default_appointment_duration: number
          default_tax_rate: number
          gold_threshold: number
          id: string
          platinum_threshold: number
          reminder_hours_before: number
          send_appointment_confirmations: boolean
          send_appointment_reminders: boolean
          send_birthday_greetings: boolean
          send_feedback_requests: boolean
          silver_threshold: number
          tenant_id: string
          theme_accent_color: string
          theme_font_family: string
          theme_primary_color: string
          updated_at: string
          weekly_report_day: number
          weekly_report_enabled: boolean
        }
        Insert: {
          advance_booking_days?: number
          appointment_buffer_minutes?: number
          cancellation_policy?: string | null
          created_at?: string
          daily_report_enabled?: boolean
          daily_report_time?: string
          default_appointment_duration?: number
          default_tax_rate?: number
          gold_threshold?: number
          id?: string
          platinum_threshold?: number
          reminder_hours_before?: number
          send_appointment_confirmations?: boolean
          send_appointment_reminders?: boolean
          send_birthday_greetings?: boolean
          send_feedback_requests?: boolean
          silver_threshold?: number
          tenant_id: string
          theme_accent_color?: string
          theme_font_family?: string
          theme_primary_color?: string
          updated_at?: string
          weekly_report_day?: number
          weekly_report_enabled?: boolean
        }
        Update: {
          advance_booking_days?: number
          appointment_buffer_minutes?: number
          cancellation_policy?: string | null
          created_at?: string
          daily_report_enabled?: boolean
          daily_report_time?: string
          default_appointment_duration?: number
          default_tax_rate?: number
          gold_threshold?: number
          id?: string
          platinum_threshold?: number
          reminder_hours_before?: number
          send_appointment_confirmations?: boolean
          send_appointment_reminders?: boolean
          send_birthday_greetings?: boolean
          send_feedback_requests?: boolean
          silver_threshold?: number
          tenant_id?: string
          theme_accent_color?: string
          theme_font_family?: string
          theme_primary_color?: string
          updated_at?: string
          weekly_report_day?: number
          weekly_report_enabled?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "tenant_settings_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: true
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      tenants: {
        Row: {
          business_name: string
          created_at: string
          gstin: string | null
          gstin_added_at: string | null
          has_gstin: boolean
          id: string
          onboarding_completed: boolean | null
          owner_email: string
          owner_name: string
          owner_phone: string
          proof_of_business_url: string | null
          proof_verification_status: Database["public"]["Enums"]["proof_verification_status"]
          proof_verified_at: string | null
          proof_verified_by: string | null
          schema_name: string
          status: Database["public"]["Enums"]["tenant_status"]
          trial_ends_at: string
          updated_at: string
        }
        Insert: {
          business_name: string
          created_at?: string
          gstin?: string | null
          gstin_added_at?: string | null
          has_gstin?: boolean
          id?: string
          onboarding_completed?: boolean | null
          owner_email: string
          owner_name: string
          owner_phone: string
          proof_of_business_url?: string | null
          proof_verification_status?: Database["public"]["Enums"]["proof_verification_status"]
          proof_verified_at?: string | null
          proof_verified_by?: string | null
          schema_name: string
          status?: Database["public"]["Enums"]["tenant_status"]
          trial_ends_at?: string
          updated_at?: string
        }
        Update: {
          business_name?: string
          created_at?: string
          gstin?: string | null
          gstin_added_at?: string | null
          has_gstin?: boolean
          id?: string
          onboarding_completed?: boolean | null
          owner_email?: string
          owner_name?: string
          owner_phone?: string
          proof_of_business_url?: string | null
          proof_verification_status?: Database["public"]["Enums"]["proof_verification_status"]
          proof_verified_at?: string | null
          proof_verified_by?: string | null
          schema_name?: string
          status?: Database["public"]["Enums"]["tenant_status"]
          trial_ends_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      user_devices: {
        Row: {
          created_at: string | null
          device_id: string
          id: string
          is_active: boolean | null
          last_active_at: string | null
          platform: string | null
          push_token: string | null
          tenant_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          device_id: string
          id?: string
          is_active?: boolean | null
          last_active_at?: string | null
          platform?: string | null
          push_token?: string | null
          tenant_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          device_id?: string
          id?: string
          is_active?: boolean | null
          last_active_at?: string | null
          platform?: string | null
          push_token?: string | null
          tenant_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_devices_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_preferences: {
        Row: {
          branch_id: string | null
          created_at: string
          id: string
          preferences: Json
          tenant_id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          branch_id?: string | null
          created_at?: string
          id?: string
          preferences?: Json
          tenant_id: string
          updated_at?: string
          user_id: string
        }
        Update: {
          branch_id?: string | null
          created_at?: string
          id?: string
          preferences?: Json
          tenant_id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          assigned_at: string
          assigned_by: string | null
          role_id: string
          tenant_id: string
          user_id: string
        }
        Insert: {
          assigned_at?: string
          assigned_by?: string | null
          role_id: string
          tenant_id: string
          user_id: string
        }
        Update: {
          assigned_at?: string
          assigned_by?: string | null
          role_id?: string
          tenant_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_sessions: {
        Row: {
          branch_id: string | null
          created_at: string | null
          device: string | null
          device_id: string | null
          dummy1: string | null
          dummy2: string | null
          dummy3: string | null
          dummy4: string | null
          dummy5: string | null
          id: string
          ip: string | null
          is_active: boolean | null
          location: string | null
          tenant_id: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          branch_id?: string | null
          created_at?: string | null
          device?: string | null
          device_id?: string | null
          dummy1?: string | null
          dummy2?: string | null
          dummy3?: string | null
          dummy4?: string | null
          dummy5?: string | null
          id?: string
          ip?: string | null
          is_active?: boolean | null
          location?: string | null
          tenant_id?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          branch_id?: string | null
          created_at?: string | null
          device?: string | null
          device_id?: string | null
          dummy1?: string | null
          dummy2?: string | null
          dummy3?: string | null
          dummy4?: string | null
          dummy5?: string | null
          id?: string
          ip?: string | null
          is_active?: boolean | null
          location?: string | null
          tenant_id?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_sessions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          address: string | null
          alternate_phone: number | null
          avatar_url: string | null
          consent_given: boolean
          consent_given_at: string | null
          created_at: string
          data_retention_expires_at: string | null
          date_of_birth: string | null
          email: string
          full_name: string
          gender: string | null
          id: string
          is_active: boolean
          join_date: string | null
          last_login_at: string | null
          login_alerts_enabled: boolean | null
          max_devices: number
          phone: string
          salary: number | null
          tenant_id: string
          updated_at: string
        }
        Insert: {
          address?: string | null
          alternate_phone?: number | null
          avatar_url?: string | null
          consent_given?: boolean
          consent_given_at?: string | null
          created_at?: string
          data_retention_expires_at?: string | null
          date_of_birth?: string | null
          email: string
          full_name: string
          gender?: string | null
          id?: string
          is_active?: boolean
          join_date?: string | null
          last_login_at?: string | null
          login_alerts_enabled?: boolean | null
          max_devices?: number
          phone: string
          salary?: number | null
          tenant_id: string
          updated_at?: string
        }
        Update: {
          address?: string | null
          alternate_phone?: number | null
          avatar_url?: string | null
          consent_given?: boolean
          consent_given_at?: string | null
          created_at?: string
          data_retention_expires_at?: string | null
          date_of_birth?: string | null
          email?: string
          full_name?: string
          gender?: string | null
          id?: string
          is_active?: boolean
          join_date?: string | null
          last_login_at?: string | null
          login_alerts_enabled?: boolean | null
          max_devices?: number
          phone?: string
          salary?: number | null
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "users_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      whatsapp_config: {
        Row: {
          api_key: string
          appointment_confirmation_template_id: string | null
          appointment_reminder_template_id: string | null
          birthday_template_id: string | null
          created_at: string
          feedback_template_id: string | null
          id: string
          invoice_template_id: string | null
          is_active: boolean
          low_stock_alert_template_id: string | null
          provider: Database["public"]["Enums"]["whatsapp_provider"]
          sender_name: string | null
          sender_phone: string
          tenant_id: string
          updated_at: string
          verified: boolean
          verified_at: string | null
        }
        Insert: {
          api_key: string
          appointment_confirmation_template_id?: string | null
          appointment_reminder_template_id?: string | null
          birthday_template_id?: string | null
          created_at?: string
          feedback_template_id?: string | null
          id?: string
          invoice_template_id?: string | null
          is_active?: boolean
          low_stock_alert_template_id?: string | null
          provider?: Database["public"]["Enums"]["whatsapp_provider"]
          sender_name?: string | null
          sender_phone: string
          tenant_id: string
          updated_at?: string
          verified?: boolean
          verified_at?: string | null
        }
        Update: {
          api_key?: string
          appointment_confirmation_template_id?: string | null
          appointment_reminder_template_id?: string | null
          birthday_template_id?: string | null
          created_at?: string
          feedback_template_id?: string | null
          id?: string
          invoice_template_id?: string | null
          is_active?: boolean
          low_stock_alert_template_id?: string | null
          provider?: Database["public"]["Enums"]["whatsapp_provider"]
          sender_name?: string | null
          sender_phone?: string
          tenant_id?: string
          updated_at?: string
          verified?: boolean
          verified_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "whatsapp_config_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: true
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_reply_to_ticket: {
        Args: { p_message: string; p_sender_id: string; p_ticket_id: string }
        Returns: undefined
      }
      admin_update_admin_user: {
        Args: {
          p_bio?: string
          p_full_name?: string
          p_phone?: string
          p_role?: string
          p_target_admin_id: string
        }
        Returns: undefined
      }
      admin_update_ticket_status: {
        Args: { p_status: string; p_ticket_id: string }
        Returns: undefined
      }
      check_email_exists: { Args: { email_to_check: string }; Returns: boolean }
      check_signup_availability:
        | {
            Args: { check_email: string; check_phone: string }
            Returns: string
          }
        | { Args: { check_phone: string }; Returns: string }
      create_appointment_notifications: {
        Args: { p_appointment_id: string; p_notification_type: string }
        Returns: undefined
      }
      create_feedback_notifications: {
        Args: { p_feedback_id: string }
        Returns: undefined
      }
      create_or_update_feedback_link: {
        Args: { p_appointment_id: string }
        Returns: {
          token: string
        }[]
      }
      create_payment_notifications: {
        Args: {
          p_amount: number
          p_invoice_id: string
          p_notification_type: string
        }
        Returns: undefined
      }
      create_security_notifications: {
        Args: {
          p_extra_data?: Json
          p_notification_type: string
          p_tenant_id: string
          p_user_id: string
        }
        Returns: undefined
      }
      create_staff_notifications: {
        Args: {
          p_branch_id: string
          p_extra_data?: Json
          p_notification_type: string
          p_reference_id: string
          p_staff_id: string
          p_tenant_id: string
        }
        Returns: undefined
      }
      current_tenant_id: { Args: never; Returns: string }
      current_user_role: { Args: never; Returns: string }
      generate_daily_revenue_summary: {
        Args: {
          p_branch_id: string
          p_report_date?: string
          p_tenant_id: string
        }
        Returns: Json
      }
      generate_invoice_number: {
        Args: { p_tenant_id: string }
        Returns: string
      }
      get_active_tax_rate: {
        Args: never
        Returns: {
          active: boolean | null
          cgst: number
          created_at: string | null
          id: string
          name: string
          sgst: number
          total: number | null
        }
        SetofOptions: {
          from: "*"
          to: "tax_rates"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      get_admin_profile: {
        Args: { p_admin_id: string }
        Returns: {
          avatar_url: string
          bio: string
          created_at: string
          email: string
          full_name: string
          id: string
          phone: string
          role: string
          username: string
        }[]
      }
      get_admin_staff_details: { Args: { p_staff_id: string }; Returns: Json }
      get_admin_support_dashboard_stats: {
        Args: never
        Returns: {
          open_count: number
          resolved_count: number
          total_count: number
          urgent_count: number
        }[]
      }
      get_admin_support_ticket_details: {
        Args: { p_ticket_id: string }
        Returns: {
          business_name: string
          category: string
          created_at: string
          description: string
          id: string
          owner_email: string
          owner_name: string
          priority: string
          status: string
          subject: string
          subscription_plan: string
          tenant_status: string
          ticket_number: number
          updated_at: string
          user_email: string
          user_full_name: string
        }[]
      }
      get_admin_support_ticket_messages: {
        Args: { p_ticket_id: string }
        Returns: {
          created_at: string
          id: string
          message: string
          sender_type: string
          user_full_name: string
        }[]
      }
      get_admin_support_tickets_paginated: {
        Args: {
          p_limit: number
          p_offset: number
          p_priority?: string
          p_search?: string
          p_sort_by?: string
          p_sort_order?: string
          p_status?: string
        }
        Returns: {
          business_name: string
          category: string
          created_at: string
          id: string
          priority: string
          status: string
          subject: string
          ticket_number: number
          total_count: number
          updated_at: string
        }[]
      }
      get_admin_tenant_branch_clients_paginated: {
        Args: {
          p_branch_id: string
          p_limit: number
          p_offset: number
          p_search?: string
          p_status?: string
          p_tenant_id: string
        }
        Returns: Json
      }
      get_admin_tenant_branches: {
        Args: { p_tenant_id: string }
        Returns: {
          address: string | null
          business_hours: Json
          city: string | null
          created_at: string
          email: string | null
          id: string
          is_active: boolean
          name: string
          phone: string | null
          pincode: string | null
          state: string | null
          tenant_id: string
          updated_at: string
          website: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "branches"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_admin_tenant_client_summary: {
        Args: { p_tenant_id: string }
        Returns: {
          branch_id: string
          top_clients: Json
          total_customers: number
          total_revenue: number
          vip_customers: number
        }[]
      }
      get_admin_tenant_clients: {
        Args: { p_tenant_id: string }
        Returns: {
          address: string | null
          branch_id: string
          city: string | null
          consent_for_marketing: boolean
          consent_given: boolean
          consent_given_at: string | null
          created_at: string
          data_retention_expires_at: string | null
          date_of_birth: string | null
          email: string | null
          gender: string | null
          id: string
          is_active: boolean
          last_visit_at: string | null
          name: string
          phone: string
          pincode: string | null
          preferred_staff_id: string | null
          referral_code: string | null
          source: Database["public"]["Enums"]["client_source"]
          tenant_id: string
          tier: Database["public"]["Enums"]["client_tier"]
          total_spend: number
          total_visits: number
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "clients"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_admin_tenant_staff: {
        Args: { p_tenant_id: string }
        Returns: {
          auth_state: Database["public"]["Enums"]["staff_auth_state"]
          branch_id: string
          created_at: string
          deleted_at: string | null
          email: string | null
          employee_code: string | null
          id: string
          invite_expiry: string | null
          invite_token: string | null
          is_active: boolean | null
          join_date: string | null
          last_invite_id: string | null
          name: string
          phone: string
          role: string | null
          salary: number | null
          system_role: string | null
          tenant_id: string
          updated_at: string
          user_id: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "staff"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_all_admin_users: {
        Args: never
        Returns: {
          avatar_url: string | null
          bio: string | null
          created_at: string
          email: string
          full_name: string | null
          id: string
          phone: string | null
          role: string
          updated_at: string | null
          username: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "admin_users"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_invite_details: { Args: { invite_token: string }; Returns: Json }
      get_primary_role: { Args: { p_user_id: string }; Returns: string }
      get_public_branch_booking_data: {
        Args: { p_branch_id: string }
        Returns: Json
      }
      get_public_staff_appointments: {
        Args: { p_branch_id: string; p_date: string; p_staff_id: string }
        Returns: {
          end_time: string
          start_time: string
          status: string
        }[]
      }
      get_user_permissions: {
        Args: never
        Returns: {
          action: string
          resource: string
        }[]
      }
      get_user_tenant_id: { Args: never; Returns: string }
      process_daily_revenue_reports: { Args: never; Returns: undefined }
      recalculate_staff_revenue: {
        Args: { p_month: number; p_staff_id: string; p_year: number }
        Returns: undefined
      }
      update_admin_avatar_url: {
        Args: { p_admin_id: string; p_avatar_url: string }
        Returns: undefined
      }
      update_admin_profile:
        | {
            Args: {
              p_admin_id: string
              p_bio?: string
              p_full_name?: string
              p_phone?: string
              p_username?: string
            }
            Returns: undefined
          }
        | {
            Args: {
              p_admin_id: string
              p_avatar_url?: string
              p_bio?: string
              p_full_name?: string
              p_phone?: string
              p_username?: string
            }
            Returns: undefined
          }
      user_has_permission: {
        Args: { p_action: string; p_resource: string }
        Returns: boolean
      }
    }
    Enums: {
      appointment_source: "MANUAL" | "WHATSAPP" | "ONLINE" | "WALK_IN"
      appointment_status:
        | "SCHEDULED"
        | "CONFIRMED"
        | "IN_PROGRESS"
        | "COMPLETED"
        | "BILLED"
        | "CANCELLED"
        | "NO_SHOW"
      client_source: "WALK_IN" | "WHATSAPP" | "REFERRAL" | "ONLINE" | "OTHER"
      client_tier: "REGULAR" | "SILVER" | "GOLD" | "PLATINUM"
      inventory_unit:
        | "PIECE"
        | "LITER"
        | "KILOGRAM"
        | "MILLILITER"
        | "GRAM"
        | "BOX"
        | "BOTTLE"
      invoice_status:
        | "DRAFT"
        | "PENDING"
        | "PAID"
        | "PARTIALLY_PAID"
        | "CANCELLED"
      line_item_type: "SERVICE" | "PRODUCT"
      notification_channel: "WHATSAPP" | "EMAIL" | "SMS" | "PUSH" | "IN_APP"
      notification_status: "PENDING" | "SENT" | "DELIVERED" | "READ" | "FAILED"
      payment_method:
        | "CASH"
        | "CARD"
        | "UPI"
        | "WALLET"
        | "BANK_TRANSFER"
        | "OTHER"
      po_status:
        | "DRAFT"
        | "PENDING_APPROVAL"
        | "APPROVED"
        | "ORDERED"
        | "RECEIVED"
        | "CANCELLED"
      proof_verification_status: "PENDING" | "VERIFIED" | "REJECTED"
      staff_auth_state: "uninvited" | "invited" | "authenticated"
      staff_employment_state: "active" | "disabled"
      subscription_status:
        | "TRIAL"
        | "ACTIVE"
        | "PAST_DUE"
        | "CANCELLED"
        | "PAUSED"
      template_type:
        | "APPOINTMENT_CONFIRMATION"
        | "APPOINTMENT_REMINDER"
        | "INVOICE"
        | "FEEDBACK_REQUEST"
        | "BIRTHDAY_GREETING"
        | "LOW_STOCK_ALERT"
        | "DAILY_REPORT"
        | "WEEKLY_REPORT"
        | "CUSTOM"
      tenant_status: "TRIAL" | "ACTIVE" | "SUSPENDED" | "PAST_DUE" | "CANCELLED"
      transaction_type:
        | "PURCHASE"
        | "ADJUSTMENT"
        | "DEDUCTION"
        | "RETURN"
        | "TRANSFER"
      whatsapp_provider: "GUPSHUP" | "TWILIO" | "META"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      appointment_source: ["MANUAL", "WHATSAPP", "ONLINE", "WALK_IN"],
      appointment_status: [
        "SCHEDULED",
        "CONFIRMED",
        "IN_PROGRESS",
        "COMPLETED",
        "BILLED",
        "CANCELLED",
        "NO_SHOW",
      ],
      client_source: ["WALK_IN", "WHATSAPP", "REFERRAL", "ONLINE", "OTHER"],
      client_tier: ["REGULAR", "SILVER", "GOLD", "PLATINUM"],
      inventory_unit: [
        "PIECE",
        "LITER",
        "KILOGRAM",
        "MILLILITER",
        "GRAM",
        "BOX",
        "BOTTLE",
      ],
      invoice_status: [
        "DRAFT",
        "PENDING",
        "PAID",
        "PARTIALLY_PAID",
        "CANCELLED",
      ],
      line_item_type: ["SERVICE", "PRODUCT"],
      notification_channel: ["WHATSAPP", "EMAIL", "SMS", "PUSH", "IN_APP"],
      notification_status: ["PENDING", "SENT", "DELIVERED", "READ", "FAILED"],
      payment_method: [
        "CASH",
        "CARD",
        "UPI",
        "WALLET",
        "BANK_TRANSFER",
        "OTHER",
      ],
      po_status: [
        "DRAFT",
        "PENDING_APPROVAL",
        "APPROVED",
        "ORDERED",
        "RECEIVED",
        "CANCELLED",
      ],
      proof_verification_status: ["PENDING", "VERIFIED", "REJECTED"],
      staff_auth_state: ["uninvited", "invited", "authenticated"],
      staff_employment_state: ["active", "disabled"],
      subscription_status: [
        "TRIAL",
        "ACTIVE",
        "PAST_DUE",
        "CANCELLED",
        "PAUSED",
      ],
      template_type: [
        "APPOINTMENT_CONFIRMATION",
        "APPOINTMENT_REMINDER",
        "INVOICE",
        "FEEDBACK_REQUEST",
        "BIRTHDAY_GREETING",
        "LOW_STOCK_ALERT",
        "DAILY_REPORT",
        "WEEKLY_REPORT",
        "CUSTOM",
      ],
      tenant_status: ["TRIAL", "ACTIVE", "SUSPENDED", "PAST_DUE", "CANCELLED"],
      transaction_type: [
        "PURCHASE",
        "ADJUSTMENT",
        "DEDUCTION",
        "RETURN",
        "TRANSFER",
      ],
      whatsapp_provider: ["GUPSHUP", "TWILIO", "META"],
    },
  },
} as const
