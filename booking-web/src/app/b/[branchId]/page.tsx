import { notFound } from 'next/navigation'
import { getBranchInfo, getBranchServices, getBranchStaff } from '@/app/actions/booking'
import BookingForm from '@/components/booking/BookingForm'
import { Metadata } from 'next'

interface PageProps {
  params: Promise<{ branchId: string }>
}

export async function generateMetadata(
  { params }: PageProps
): Promise<Metadata> {
  const { branchId } = await params
  const branch = await getBranchInfo(branchId)
  
  if (!branch) {
    return {
      title: 'Salon Not Found',
    }
  }

  return {
    title: `${branch.name} — Book Appointment`,
    description: `Book your appointment at ${branch.name} online.`,
  }
}

export default async function BookingPage({ params }: PageProps) {
  const { branchId } = await params
  
  const [branch, services, staff] = await Promise.all([
    getBranchInfo(branchId),
    getBranchServices(branchId),
    getBranchStaff(branchId),
  ])

  if (!branch || !branch.is_active) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen p-4 text-center">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Booking Unavailable</h1>
        <p className="text-gray-500 max-w-md">
          Online booking is currently unavailable for this salon. Please contact them directly.
        </p>
      </div>
    )
  }

  return (
    <main>
      <BookingForm 
        branch={branch} 
        services={services} 
        staff={staff} 
      />
    </main>
  )
}
