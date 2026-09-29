import { notFound } from 'next/navigation'
import { getBranchInfo } from '@/app/actions/booking'
import BookingQR from '@/components/qr/BookingQR'
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
    return { title: 'Not Found' }
  }

  return { title: `${branch.name} — QR Generator` }
}

export default async function QRPage({ params }: PageProps) {
  const { branchId } = await params
  const slug = branchId
  const branch = await getBranchInfo(slug)
  
  if (!branch) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen p-6 text-center bg-[#FCFBF8]">
        <div className="w-16 h-16 bg-[#2C2A29] text-white rounded-full flex items-center justify-center mb-6 font-serif text-3xl italic">
          ?
        </div>
        <h1 className="text-4xl font-serif text-[#2C2A29] mb-4 tracking-tight">Well, this is awkward.</h1>
        <p className="text-[#736B66] max-w-sm mx-auto leading-relaxed">
          The hair dryers are on, but the booking system is not! This salon hasn't set up their digital booking page yet. You might have to book the old-fashioned way and actually speak to a human on the phone. The horror!
        </p>
      </div>
    )
  }

  // Determine the base URL (using localhost for development, or your production domain)
  // In a real app, you might use an environment variable like process.env.NEXT_PUBLIC_BASE_URL
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'
  const bookingUrl = `${baseUrl}/b/${branch.id}`

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-2xl text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">QR Generator</h1>
        <p className="text-gray-500">Generate, download, or print a QR code for {branch.name}</p>
      </div>

      <BookingQR 
        url={bookingUrl} 
        salonName={branch.name} 
        phone={branch.phone || undefined} 
      />
      
      <div className="mt-8">
        <a 
          href={`/b/${branch.id}`}
          className="text-sm font-medium text-blue-600 hover:text-blue-800 transition-colors"
        >
          &larr; Back to Booking Page
        </a>
      </div>
    </div>
  )
}
