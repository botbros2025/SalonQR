'use client'

import { useState } from 'react'
import { Phone, Check, ArrowRight, ArrowLeft, Calendar as CalendarIcon, Clock } from 'lucide-react'

// Types (would normally be imported)
type Service = any
type Staff = any

interface BookingFormProps {
  branch: any
  services: Service[]
  staff: Staff[]
}

type BookingStep = 'service' | 'staff' | 'datetime' | 'details' | 'review' | 'confirmed'

export default function BookingForm({ branch, services, staff }: BookingFormProps) {
  const [step, setStep] = useState<BookingStep>('service')
  
  const [selectedService, setSelectedService] = useState<Service | null>(null)
  const [selectedStaff, setSelectedStaff] = useState<Staff | null | 'any'>(null)
  const [selectedDate, setSelectedDate] = useState<string>('')
  const [selectedTime, setSelectedTime] = useState<string>('')
  
  const [customerName, setCustomerName] = useState('')
  const [customerPhone, setCustomerPhone] = useState('')
  
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [bookingId, setBookingId] = useState('')

  // Group services by category
  const groupedServices = services.reduce((acc: any, service: any) => {
    const categoryName = service.service_categories?.name || 'OTHER'
    if (!acc[categoryName]) acc[categoryName] = []
    acc[categoryName].push(service)
    return acc
  }, {})

  const handleServiceSelect = (service: Service) => {
    setSelectedService(service)
  }

  const handleStaffSelect = (staffMember: Staff | 'any') => {
    setSelectedStaff(staffMember)
  }

  const handleTimeSelect = (date: string, time: string) => {
    setSelectedDate(date)
    setSelectedTime(time)
  }

  const handleSubmitDetails = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setStep('review')
  }

  const handleConfirmAppointment = async () => {
    setIsSubmitting(true)
    // Simulate API call
    setTimeout(() => {
      setIsSubmitting(false)
      setBookingId('MS-1628A')
      setStep('confirmed')
      window.scrollTo(0, 0)
    }, 1500)
  }

  const renderProgressBar = () => {
    const steps = ['service', 'staff', 'datetime', 'details', 'review']
    const currentIndex = steps.indexOf(step)
    
    if (step === 'confirmed') return null;

    return (
      <div className="flex w-full gap-2 mt-8 mb-12">
        {steps.map((s, idx) => (
          <div 
            key={s} 
            className={`h-0.5 flex-1 ${idx <= currentIndex ? 'bg-[#9A7B4F]' : 'bg-[#E5E0DB]'}`}
          />
        ))}
      </div>
    )
  }

  if (step === 'confirmed') {
    return (
      <div className="min-h-screen bg-[#FCFBF8] text-[#2C2A29] font-sans selection:bg-[#9A7B4F] selection:text-white flex flex-col items-center justify-center p-6">
        <div className="w-full max-w-md animate-in fade-in zoom-in-95 duration-500 text-center">
          <div className="w-16 h-16 bg-[#E6F4EA] text-[#1E8E3E] rounded-full flex items-center justify-center mx-auto mb-6">
            <Check className="w-8 h-8" />
          </div>
          
          <p className="text-[10px] font-bold tracking-[0.15em] text-[#9A7B4F] uppercase mb-4">APPOINTMENT CONFIRMED</p>
          <h2 className="text-4xl md:text-5xl font-serif font-normal tracking-tight text-[#2C2A29] mb-8 leading-tight">
            You're all set,<br/>
            <span className="italic text-[#9A7B4F]">{customerName}.</span>
          </h2>
          
          <div className="bg-white border border-[#E5E0DB] text-left p-6 mb-6">
            <p className="font-serif font-normal text-xl text-[#2C2A29] mb-1">{selectedService?.name}</p>
            <p className="text-xs font-normal text-[#736B66] mb-6">Indiranagar Studio</p>
            
            <div className="space-y-4">
              <div className="flex items-center gap-3 text-sm text-[#736B66]">
                <CalendarIcon className="w-4 h-4" />
                <span className="font-normal">{selectedDate || '2026-09-19'}</span>
              </div>
              <div className="flex items-center gap-3 text-sm text-[#736B66] pb-6 border-b border-[#E5E0DB]">
                <Clock className="w-4 h-4" />
                <span className="font-normal">{selectedTime} • {selectedStaff === 'any' ? 'Priya' : (selectedStaff as Staff)?.name || 'Stylist'}</span>
              </div>
            </div>
            
            <div className="pt-4 flex items-center gap-4">
              <p className="text-[10px] font-bold tracking-[0.15em] text-[#736B66] uppercase">BOOKING ID</p>
              <p className="text-xs font-bold text-[#2C2A29] tracking-wider">{bookingId}</p>
            </div>
          </div>

          <a 
            href={`tel:${branch.phone}`}
            className="bg-[#332E2C] hover:bg-black text-white text-xs font-bold tracking-[0.1em] px-8 py-4 w-full uppercase flex items-center justify-center gap-3 transition-colors mb-4"
          >
            <Phone className="w-4 h-4" /> CALL SALON
          </a>
          
          <button 
            onClick={() => window.location.reload()}
            className="text-xs font-normal text-[#736B66] hover:text-[#2C2A29] transition-colors"
          >
            Done
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#FCFBF8] text-[#2C2A29] font-sans selection:bg-[#9A7B4F] selection:text-white">
      {/* Header */}
      <header className="max-w-3xl mx-auto px-6 py-8 flex justify-between items-center">
        <div className="flex items-center gap-4">
          <div className="w-10 h-10 border border-[#9A7B4F] flex items-center justify-center text-[#9A7B4F] font-serif text-sm tracking-widest">
            {branch.name.substring(0, 2).toUpperCase()}
          </div>
          <div>
            <h1 className="font-serif font-semibold text-lg leading-tight">{branch.name}</h1>
            <p className="text-[10px] tracking-[0.2em] text-[#9A7B4F] uppercase">INDIRANAGAR STUDIO</p>
          </div>
        </div>
        {branch.phone && (
          <a href={`tel:${branch.phone}`} className="flex items-center gap-2 text-xs font-semibold tracking-widest text-[#9A7B4F] uppercase hover:opacity-80 transition-opacity">
            <Phone className="w-3 h-3" /> CALL SALON
          </a>
        )}
      </header>

      <main className="max-w-3xl mx-auto px-6 pb-24">
        {/* Hero Section */}
        <div className="mt-8">
          <div className="flex items-center gap-2 text-[10px] font-bold tracking-[0.15em] text-[#9A7B4F] uppercase mb-4">
            <span>✨</span> ONLINE BOOKING
          </div>
          <h2 className="text-5xl md:text-6xl text-[#2C2A29] font-serif tracking-tight leading-[1.1] mb-4">
            Make time <br/>
            <span className="italic text-[#9A7B4F]">for yourself.</span>
          </h2>
          <div className="flex items-center gap-2 text-sm text-[#736B66]">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
            {branch.address}, {branch.city}
          </div>
          
          {renderProgressBar()}
        </div>

        {/* STEP 1: SERVICE */}
        {step === 'service' && (
          <div className="animate-in fade-in duration-500">
            <p className="text-[10px] font-bold tracking-[0.15em] text-[#736B66] uppercase mb-3">01 / SERVICE</p>
            <h3 className="text-3xl font-serif text-[#2C2A29] mb-12">What are you in the mood for?</h3>

            <div className="space-y-12">
              {Object.keys(groupedServices).map((categoryName) => (
                <div key={categoryName}>
                  <h4 className="text-xs font-bold tracking-[0.15em] text-[#736B66] uppercase mb-4">{categoryName}</h4>
                  <div className="space-y-3">
                    {groupedServices[categoryName].map((service: Service) => {
                      const isSelected = selectedService?.id === service.id;
                      return (
                        <button
                          key={service.id}
                          onClick={() => handleServiceSelect(service)}
                          className={`w-full text-left bg-white p-6 transition-all border ${isSelected ? 'border-[#9A7B4F] ring-1 ring-[#9A7B4F]' : 'border-[#E5E0DB] hover:border-[#9A7B4F]'}`}
                        >
                          <div className="flex justify-between items-start">
                            <div>
                              <p className="font-semibold text-sm text-[#2C2A29]">{service.name}</p>
                              <p className="text-xs text-[#736B66] mt-1.5">{service.description}</p>
                            </div>
                            <div className="text-right">
                              <p className="font-semibold text-sm text-[#2C2A29]">₹{service.price}</p>
                              <p className="text-[11px] text-[#736B66] mt-1">{service.duration_minutes} min</p>
                            </div>
                          </div>
                        </button>
                      )
                    })}
                  </div>
                </div>
              ))}
            </div>

            {selectedService && (
              <div className="mt-12">
                <button 
                  onClick={() => setStep('staff')}
                  className="bg-[#332E2C] hover:bg-black text-white text-xs font-bold tracking-[0.1em] px-8 py-4 uppercase flex items-center gap-3 transition-colors"
                >
                  CONTINUE <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>
        )}

        {/* STEP 2: STAFF */}
        {step === 'staff' && (
          <div className="animate-in fade-in duration-500">
            <p className="text-[10px] font-bold tracking-[0.15em] text-[#736B66] uppercase mb-3">02 / PREFERENCE</p>
            <h3 className="text-3xl font-serif text-[#2C2A29] mb-12">Who would you like to see?</h3>
            
            <div className="space-y-3">
              <button
                onClick={() => handleStaffSelect('any')}
                className={`w-full text-left bg-white p-5 transition-all border flex items-center justify-between ${selectedStaff === 'any' ? 'border-[#9A7B4F] ring-1 ring-[#9A7B4F]' : 'border-[#E5E0DB] hover:border-[#9A7B4F]'}`}
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-[#FCFBF8] border border-[#E5E0DB] flex items-center justify-center text-[#9A7B4F]">
                    ✨
                  </div>
                  <div>
                    <p className="font-semibold text-sm text-[#2C2A29]">Anyone available</p>
                    <p className="text-[11px] text-[#736B66] mt-0.5">Your best available match</p>
                  </div>
                </div>
                {selectedStaff === 'any' && <Check className="w-5 h-5 text-[#9A7B4F]" />}
              </button>

              {staff.map(s => {
                const isSelected = selectedStaff !== 'any' && selectedStaff?.id === s.id;
                return (
                  <button
                    key={s.id}
                    onClick={() => handleStaffSelect(s)}
                    className={`w-full text-left bg-white p-5 transition-all border flex items-center justify-between ${isSelected ? 'border-[#9A7B4F] ring-1 ring-[#9A7B4F]' : 'border-[#E5E0DB] hover:border-[#9A7B4F]'}`}
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 rounded-full bg-[#FCFBF8] border border-[#E5E0DB] flex items-center justify-center text-[#9A7B4F] font-serif text-sm">
                        {s.name.charAt(0)}
                      </div>
                      <div>
                        <p className="font-semibold text-sm text-[#2C2A29]">{s.name}</p>
                        <p className="text-[11px] text-[#736B66] mt-0.5">Stylist</p>
                      </div>
                    </div>
                    {isSelected && <Check className="w-5 h-5 text-[#9A7B4F]" />}
                  </button>
                )
              })}
            </div>

            <div className="mt-12 flex items-center justify-between border-t border-[#E5E0DB] pt-8">
              <button 
                onClick={() => setStep('service')}
                className="flex items-center gap-2 text-xs font-semibold tracking-wider text-[#736B66] hover:text-[#2C2A29] transition-colors"
              >
                <ArrowLeft className="w-3 h-3" /> Back
              </button>
              <button 
                onClick={() => setStep('datetime')}
                disabled={!selectedStaff}
                className="bg-[#332E2C] disabled:opacity-50 disabled:cursor-not-allowed hover:bg-black text-white text-xs font-bold tracking-[0.1em] px-8 py-4 uppercase flex items-center gap-3 transition-colors"
              >
                CONTINUE <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* STEP 3: DATETIME */}
        {step === 'datetime' && (
          <div className="animate-in fade-in duration-500">
            <p className="text-[10px] font-bold tracking-[0.15em] text-[#736B66] uppercase mb-3">03 / DATE & TIME</p>
            <h3 className="text-3xl font-serif text-[#2C2A29] mb-12">Find a time that works.</h3>
            
            <div className="border border-[#E5E0DB] bg-white">
              <div className="flex items-center justify-between p-4 border-b border-[#E5E0DB]">
                <button className="p-2 text-[#736B66] hover:text-[#2C2A29]"><ArrowLeft className="w-4 h-4" /></button>
                <span className="text-sm font-semibold text-[#2C2A29] flex items-center gap-2">
                  <svg className="w-4 h-4 text-[#9A7B4F]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                  Sat, 19 Sept
                </span>
                <button className="p-2 text-[#736B66] hover:text-[#2C2A29]"><ArrowRight className="w-4 h-4" /></button>
              </div>
              <div className="grid grid-cols-3 gap-0 p-4 bg-[#FCFBF8]">
                {['10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM', '1:30 PM', '2:00 PM', '2:30 PM', '4:00 PM', '4:30 PM', '5:00 PM', '5:30 PM'].map((time) => {
                  const isSelected = selectedTime === time;
                  return (
                    <button
                      key={time}
                      onClick={() => handleTimeSelect('2026-09-19', time)}
                      className={`py-4 text-xs font-semibold text-center border transition-all
                        ${isSelected ? 'border-[#9A7B4F] text-[#9A7B4F] bg-white relative z-10 ring-1 ring-[#9A7B4F]' : 'border-transparent hover:border-[#E5E0DB] text-[#736B66] bg-white m-[1px]'}
                      `}
                    >
                      {time}
                    </button>
                  )
                })}
              </div>
            </div>

            <div className="mt-12 flex items-center justify-between border-t border-[#E5E0DB] pt-8">
              <button 
                onClick={() => setStep('staff')}
                className="flex items-center gap-2 text-xs font-semibold tracking-wider text-[#736B66] hover:text-[#2C2A29] transition-colors"
              >
                <ArrowLeft className="w-3 h-3" /> Back
              </button>
              <button 
                onClick={() => setStep('details')}
                disabled={!selectedTime}
                className="bg-[#332E2C] disabled:opacity-50 hover:bg-black text-white text-xs font-bold tracking-[0.1em] px-8 py-4 uppercase flex items-center gap-3 transition-colors"
              >
                CONTINUE <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* STEP 4: DETAILS */}
        {step === 'details' && (
          <div className="animate-in fade-in duration-500">
            <p className="text-[10px] font-bold tracking-[0.15em] text-[#736B66] uppercase mb-3">04 / YOUR DETAILS</p>
            <h3 className="text-3xl font-serif text-[#2C2A29] mb-4">Almost there.</h3>
            <p className="text-xs text-[#736B66] mb-12">We'll use these details to confirm your appointment.</p>
            
            <form onSubmit={handleSubmitDetails} className="space-y-6">
              <div>
                <label className="block text-xs font-bold tracking-wider text-[#2C2A29] mb-2">Name</label>
                <input 
                  required 
                  type="text" 
                  value={customerName}
                  onChange={(e) => setCustomerName(e.target.value)}
                  className="w-full bg-white border border-[#E5E0DB] p-4 text-sm outline-none focus:border-[#9A7B4F] focus:ring-1 focus:ring-[#9A7B4F] transition-all" 
                  placeholder="Your full name" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold tracking-wider text-[#2C2A29] mb-2">Phone number</label>
                <input 
                  required 
                  type="tel" 
                  value={customerPhone}
                  onChange={(e) => setCustomerPhone(e.target.value)}
                  className="w-full bg-white border border-[#E5E0DB] p-4 text-sm outline-none focus:border-[#9A7B4F] focus:ring-1 focus:ring-[#9A7B4F] transition-all" 
                  placeholder="+91 00000 00000" 
                />
              </div>
              
              <div className="mt-12 flex items-center justify-between border-t border-[#E5E0DB] pt-8">
                <button 
                  type="button"
                  onClick={() => setStep('datetime')}
                  className="flex items-center gap-2 text-xs font-semibold tracking-wider text-[#736B66] hover:text-[#2C2A29] transition-colors"
                >
                  <ArrowLeft className="w-3 h-3" /> Back
                </button>
                <button 
                  type="submit" 
                  className="bg-[#9A7B4F] hover:bg-[#856942] text-white text-xs font-bold tracking-[0.1em] px-8 py-4 uppercase flex items-center gap-3 transition-colors"
                >
                  CONTINUE <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            </form>
          </div>
        )}

        {/* STEP 5: REVIEW */}
        {step === 'review' && (
          <div className="animate-in fade-in duration-500">
            <p className="text-[10px] font-bold tracking-[0.15em] text-[#736B66] uppercase mb-3">REVIEW</p>
            <h3 className="text-3xl font-serif text-[#2C2A29] mb-12">Ready when you are.</h3>
            
            <div className="bg-white border border-[#E5E0DB]">
              <div className="flex items-center justify-between p-6 border-b border-[#E5E0DB]">
                <span className="text-xs text-[#736B66]">Service</span>
                <span className="text-sm font-semibold text-[#2C2A29]">{selectedService?.name}</span>
              </div>
              <div className="flex items-center justify-between p-6 border-b border-[#E5E0DB]">
                <span className="text-xs text-[#736B66]">When</span>
                <span className="text-sm font-semibold text-[#2C2A29]">Sat, 19 Sept • {selectedTime}</span>
              </div>
              <div className="flex items-center justify-between p-6 border-b border-[#E5E0DB]">
                <span className="text-xs text-[#736B66]">With</span>
                <span className="text-sm font-semibold text-[#2C2A29]">{selectedStaff === 'any' ? 'Anyone available' : (selectedStaff as Staff)?.name || 'Stylist'}</span>
              </div>
              <div className="flex items-center justify-between p-6">
                <span className="text-xs text-[#736B66]">For</span>
                <span className="text-sm font-semibold text-[#2C2A29]">{customerName}</span>
              </div>
            </div>
              
            <div className="mt-12 flex items-center justify-between border-t border-[#E5E0DB] pt-8">
              <button 
                type="button"
                onClick={() => setStep('details')}
                className="flex items-center gap-2 text-xs font-semibold tracking-wider text-[#736B66] hover:text-[#2C2A29] transition-colors"
              >
                <ArrowLeft className="w-3 h-3" /> Back
              </button>
              <button 
                onClick={handleConfirmAppointment}
                disabled={isSubmitting}
                className="bg-[#332E2C] hover:bg-black disabled:opacity-70 text-white text-xs font-bold tracking-[0.1em] px-8 py-4 uppercase flex items-center gap-3 transition-colors"
              >
                {isSubmitting ? 'CONFIRMING...' : 'CONFIRM APPOINTMENT'} {!isSubmitting && <Check className="w-4 h-4" />}
              </button>
            </div>
          </div>
        )}
      </main>

      {/* Global Footer Fallback */}
      {branch.phone && (
        <footer className="max-w-3xl mx-auto px-6 py-12">
          <p className="text-xs text-[#736B66] flex items-center gap-2">
            Prefer to call? 
            <a href={`tel:${branch.phone}`} className="font-bold text-[#9A7B4F] hover:underline flex items-center gap-1">
              <Phone className="w-3 h-3" /> {branch.phone}
            </a>
          </p>
        </footer>
      )}
    </div>
  )
}
