import { notFound } from 'next/navigation'
import { getBranchInfo, getBranchBookingData } from '@/app/actions/booking'
import BookingForm from '@/components/booking/BookingForm'
import { Metadata } from 'next'

interface PageProps {
  params: Promise<{ branchId: string }>
}

export async function generateMetadata(
  { params }: PageProps
): Promise<Metadata> {
  const { branchId } = await params
  const slug = branchId
  const branch = await getBranchInfo(slug)
  
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
  const slug = branchId
  
  const data = await getBranchBookingData(slug)
  const branch = data?.branch
  const services = data?.services || []
  const staff = data?.staff || []

  if (!branch || !branch.is_active) {
    return (
      <div className="min-h-screen bg-[#FDFBF7] text-[#1E2E25] font-sans selection:bg-[#9A7B4F] selection:text-white flex flex-col">
        {/* Header */}
        <header className="px-6 py-8 flex items-center justify-between max-w-7xl mx-auto w-full">
          <div className="font-serif">
            <h1 className="text-2xl text-[#1E2E25] leading-none tracking-tight">{branch?.name || 'Salon & Spa'}</h1>
          </div>
          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-[#4A5D52]">
            <a href="#" className="hover:text-[#1E2E25] transition-colors">Services</a>
            <a href="#" className="hover:text-[#1E2E25] transition-colors">Stylists</a>
            <a href="#" className="hover:text-[#1E2E25] transition-colors">Gallery</a>
            <a href="#" className="hover:text-[#1E2E25] transition-colors">Contact</a>
            <button className="bg-[#1E2E25] text-white px-6 py-2.5 rounded-full hover:bg-black transition-colors font-semibold">
              Book Appointment
            </button>
          </nav>
          <button className="md:hidden text-[#1E2E25]">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
          </button>
        </header>

        {/* Main Content */}
        <main className="flex-1 flex flex-col md:flex-row items-center max-w-7xl mx-auto w-full overflow-hidden">
          {/* Image - Left on Desktop, Top on Mobile */}
          <div className="w-full md:w-1/2 md:h-[600px] h-[350px] relative order-1 md:order-1 rounded-b-[40px] md:rounded-r-[120px] overflow-hidden mb-8 md:mb-0">
            <img 
              src="/dog-spa.jpg" 
              alt="Cute dog at spa" 
              className="absolute inset-0 w-full h-full object-cover"
            />
          </div>

          {/* Text Content - Right on Desktop, Bottom on Mobile */}
          <div className="w-full md:w-1/2 flex flex-col justify-center px-6 md:px-16 lg:px-24 order-2 md:order-2">
            <div className="inline-flex items-center gap-2 bg-[#F2E5D4] text-[#8F6A44] px-4 py-1.5 rounded-full text-sm font-bold tracking-wider uppercase mb-6 w-max">
              Oops! <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 2v20M17 5l-10 14M5 5l14 14M2 12h20" /></svg>
            </div>
            
            <h2 className="text-5xl md:text-6xl font-serif text-[#1E2E25] leading-[1.1] mb-6">
              Well, this is <br/> <span className="italic font-normal">awkward!</span>
            </h2>
            
            <p className="text-[#4A5D52] text-lg leading-relaxed mb-4 font-medium">
              The hair dryers are on, but the booking system is not! This salon hasn't set up their digital booking page yet.
            </p>
            
            <p className="text-[#8B9891] text-sm leading-relaxed mb-10">
              You might have to book the old-fashioned way and actually speak to a human on the phone. The horror!
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 mb-16 md:mb-0">
              <a 
                href={branch?.phone ? `tel:${branch.phone}` : '#'}
                className="bg-[#1E2E25] hover:bg-black text-white px-8 py-4 rounded-full font-semibold flex items-center justify-center gap-3 transition-colors shadow-lg shadow-[#1E2E25]/20"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg>
                Call Salon
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
              </a>
              <a 
                href="/"
                className="bg-[#E9EBE6] hover:bg-[#DFE2DA] text-[#1E2E25] px-8 py-4 rounded-full font-semibold flex items-center justify-center gap-3 transition-colors"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>
                Go to Home
              </a>
            </div>
          </div>
        </main>

        {/* Features Footer */}
        <footer className="w-full border-t border-[#E9EBE6] bg-[#FDFBF7] py-10 mt-auto hidden sm:block">
          <div className="max-w-6xl mx-auto px-6 grid grid-cols-2 md:grid-cols-4 gap-8">
            <div className="flex flex-col items-center text-center">
              <div className="w-12 h-12 rounded-full border border-[#D5DCD8] flex items-center justify-center text-[#8B9891] mb-3">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
              </div>
              <h4 className="font-bold text-sm text-[#1E2E25]">Online Booking</h4>
              <p className="text-xs text-[#8B9891] mt-1">Coming Soon</p>
            </div>
            
            <div className="flex flex-col items-center text-center">
              <div className="w-12 h-12 rounded-full border border-[#D5DCD8] flex items-center justify-center text-[#8B9891] mb-3">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="6" cy="6" r="3"></circle><circle cx="6" cy="18" r="3"></circle><line x1="20" y1="4" x2="8.12" y2="15.88"></line><line x1="14.47" y1="14.48" x2="20" y2="20"></line><line x1="8.12" y1="8.12" x2="12" y2="12"></line></svg>
              </div>
              <h4 className="font-bold text-sm text-[#1E2E25]">Amazing Services</h4>
              <p className="text-xs text-[#8B9891] mt-1">Still Available</p>
            </div>
            
            <div className="flex flex-col items-center text-center">
              <div className="w-12 h-12 rounded-full border border-[#D5DCD8] flex items-center justify-center text-[#8B9891] mb-3">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"></circle><path d="M8 14s1.5 2 4 2 4-2 4-2"></path><line x1="9" y1="9" x2="9.01" y2="9"></line><line x1="15" y1="9" x2="15.01" y2="9"></line></svg>
              </div>
              <h4 className="font-bold text-sm text-[#1E2E25]">Friendly Stylists</h4>
              <p className="text-xs text-[#8B9891] mt-1">Ready to help you</p>
            </div>
            
            <div className="flex flex-col items-center text-center">
              <div className="w-12 h-12 rounded-full border border-[#D5DCD8] flex items-center justify-center text-[#8B9891] mb-3">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path></svg>
              </div>
              <h4 className="font-bold text-sm text-[#1E2E25]">Great Hair Days</h4>
              <p className="text-xs text-[#8B9891] mt-1">Are always a call away</p>
            </div>
          </div>
        </footer>
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
