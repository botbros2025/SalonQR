'use client'

import { useState, useEffect } from 'react'
import { Phone, Check, ArrowRight, ArrowLeft, Calendar as CalendarIcon, Clock } from 'lucide-react'
import { getStaffAppointments, createAppointment } from '@/app/actions/booking'

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

  const [selectedServices, setSelectedServices] = useState<Service[]>([])
  const [selectedStaff, setSelectedStaff] = useState<Staff | null | 'any'>(null)
  const [selectedDate, setSelectedDate] = useState<string>('')
  const [selectedTime, setSelectedTime] = useState<string>('')

  const [customerName, setCustomerName] = useState('')
  const [customerPhone, setCustomerPhone] = useState('')

  const [isSubmitting, setIsSubmitting] = useState(false)
  const [bookingId, setBookingId] = useState('')
  const [activeCategory, setActiveCategory] = useState<string>('')

  const [appointments, setAppointments] = useState<any[]>([])
  const [isLoadingSlots, setIsLoadingSlots] = useState(false)

  // Future-proofing for multi-booking (e.g. classes, group sessions)
  // Set to >1 if the salon supports multiple concurrent clients per slot
  const MAX_BOOKINGS_PER_SLOT = 1

  const formatDuration = (minutes: number) => {
    if (!minutes) return '30 mins';
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    if (hours > 0) {
      return `${hours} hour${hours > 1 ? 's' : ''}${mins > 0 ? ` ${mins} min` : ''}`;
    }
    return `${mins} mins`;
  }

  const getTodayDateString = () => {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }

  useEffect(() => {
    // Attempt to load returning customer details from local storage
    const savedName = localStorage.getItem('salon_qr_client_name');
    const savedPhone = localStorage.getItem('salon_qr_client_phone');
    if (savedName) setCustomerName(savedName);
    if (savedPhone) setCustomerPhone(savedPhone);
  }, []);

  useEffect(() => {
    const fetchAppointments = async () => {
      const activeDate = selectedDate || getTodayDateString()

      // For now, if "any" is selected, we optimistically assume availability.
      if (!selectedStaff || selectedStaff === 'any') {
        setAppointments([])
        return
      }

      setIsLoadingSlots(true)
      const data = await getStaffAppointments(branch.id, selectedStaff.id, activeDate)
      setAppointments(data)
      setIsLoadingSlots(false)
    }

    if (step === 'datetime') {
      fetchAppointments()
    }
  }, [step, selectedDate, selectedStaff, branch.id])

  // Group services by category
  const groupedServices = services.reduce((acc: any, service: any) => {
    const categoryName = service.service_categories?.name || 'OTHER'
    if (!acc[categoryName]) acc[categoryName] = []
    acc[categoryName].push(service)
    return acc
  }, {})

  const handleServiceSelect = (service: Service) => {
    setSelectedServices(prev => {
      const isSelected = prev.some(s => s.id === service.id);
      if (isSelected) {
        return prev.filter(s => s.id !== service.id);
      } else {
        return [...prev, service];
      }
    });
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

    // Calculate total duration for end time
    const totalMins = selectedServices.reduce((sum, s) => sum + (s.duration_minutes || 0), 0);

    // Convert selectedTime (e.g. "2:30 PM") to 24-hour format
    const [timeStr, ampmStr] = selectedTime.split(' ');
    let [hours, minutes] = timeStr.split(':').map(Number);
    if (ampmStr === 'PM' && hours !== 12) hours += 12;
    if (ampmStr === 'AM' && hours === 12) hours = 0;

    // Calculate end time string
    const dateObj = new Date();
    dateObj.setHours(hours, minutes, 0);
    dateObj.setMinutes(dateObj.getMinutes() + totalMins);
    const endTime = `${String(dateObj.getHours()).padStart(2, '0')}:${String(dateObj.getMinutes()).padStart(2, '0')}:00`;
    const startTime24 = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`;

    const result = await createAppointment({
      tenantId: branch.tenant_id,
      branchId: branch.id,
      customerName,
      customerPhone,
      appointmentDate: selectedDate || getTodayDateString(),
      startTime: startTime24,
      endTime,
      staffId: selectedStaff === 'any' ? null : (selectedStaff as Staff)?.id,
      services: selectedServices
    });

    setIsSubmitting(false)

    if (result.success) {
      setBookingId(result.bookingId || 'MS-1628A')

      // Save client details for future bookings
      localStorage.setItem('salon_qr_client_name', customerName)
      localStorage.setItem('salon_qr_client_phone', customerPhone)

      setStep('confirmed')
      window.scrollTo(0, 0)
    } else {
      alert('Failed to book appointment. Please try again.');
    }
  }

  const handlePrevDay = () => {
    const d = new Date(selectedDate || getTodayDateString());
    d.setDate(d.getDate() - 1);
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    setSelectedDate(`${yyyy}-${mm}-${dd}`);
    setSelectedTime('');
  }

  const handleNextDay = () => {
    const d = new Date(selectedDate || getTodayDateString());
    d.setDate(d.getDate() + 1);
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    setSelectedDate(`${yyyy}-${mm}-${dd}`);
    setSelectedTime('');
  }

  const generateTimeSlots = (dateString: string) => {
    if (!branch.business_hours) return [];

    const date = new Date(dateString);
    const dayOfWeek = date.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
    const hours = branch.business_hours[dayOfWeek];

    if (!hours || hours.closed || !hours.open || !hours.close) return [];

    const slots = [];
    const [startHour, startMin] = hours.open.split(':').map(Number);
    const [endHour, endMin] = hours.close.split(':').map(Number);

    let currentHour = startHour;
    let currentMin = startMin;

    const now = new Date();
    const dateOnly = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const todayOnly = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // Return no slots for past dates
    if (dateOnly < todayOnly) return [];

    const isToday = dateOnly.getTime() === todayOnly.getTime();
    const currentMins = now.getHours() * 60 + now.getMinutes();

    while (currentHour < endHour || (currentHour === endHour && currentMin < endMin)) {
      const slotMins = currentHour * 60 + currentMin;

      // Only show slots that are in the future
      if (!isToday || slotMins > currentMins) {
        const ampm = currentHour >= 12 ? 'PM' : 'AM';
        const displayHour = currentHour > 12 ? currentHour - 12 : (currentHour === 0 ? 12 : currentHour);
        const displayMin = currentMin.toString().padStart(2, '0');
        slots.push(`${displayHour}:${displayMin} ${ampm}`);
      }

      currentMin += 30; // 30 min slots
      if (currentMin >= 60) {
        currentMin -= 60;
        currentHour += 1;
      }
    }

    return slots;
  }

  const checkSlotStatus = (timeString: string, activeDate: string): 'available' | 'booked' | 'exceeds_closing' => {
    let isStartBooked = false;
    let isDurationOverlapping = false;

    // Sum duration of all selected services, default to 30 mins if 0 or not set
    const totalDuration = selectedServices.reduce((total, s) => total + (s.duration_minutes || 0), 0);
    const serviceDuration = totalDuration > 0 ? totalDuration : 30;

    const [time, ampm] = timeString.split(' ');
    let [h, m] = time.split(':').map(Number);
    if (ampm === 'PM' && h !== 12) h += 12;
    if (ampm === 'AM' && h === 12) h = 0;

    const proposedStart = h * 60 + m;
    const proposedEnd = proposedStart + serviceDuration;

    // Check if the service duration exceeds business closing hours
    const dateObj = new Date(activeDate);
    const dayOfWeek = dateObj.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
    const hours = branch.business_hours?.[dayOfWeek];

    if (hours && hours.close && !hours.closed) {
      const [endHour, endMin] = hours.close.split(':').map(Number);
      const closingMins = endHour * 60 + endMin;
      if (proposedEnd > closingMins) {
        return 'exceeds_closing';
      }
    }

    appointments.forEach(app => {
      if (!app.start_time || !app.end_time) return;
      const [startH, startM] = app.start_time.split(':').map(Number);
      const appStart = startH * 60 + startM;

      const [endH, endM] = app.end_time.split(':').map(Number);
      const appEnd = endH * 60 + endM;

      // Check if the exact start time is already within an appointment
      if (proposedStart >= appStart && proposedStart < appEnd) {
        isStartBooked = true;
      }
      // Check if the proposed duration bleeds into this appointment
      else if (proposedStart < appEnd && appStart < proposedEnd) {
        isDurationOverlapping = true;
      }
    });

    if (isStartBooked) return 'booked';
    if (isDurationOverlapping) return 'exceeds_closing';

    return 'available';
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
            You're all set,<br />
            <span className="italic text-[#9A7B4F]">{customerName}.</span>
          </h2>

          <div className="bg-white border border-[#E5E0DB] text-left p-6 mb-6">
            <div className="flex justify-between items-start mb-1">
              <p className="font-serif font-normal text-xl text-[#2C2A29]">{selectedServices.map(s => s.name).join(', ')}</p>
              <p className="font-serif font-normal text-xl text-[#2C2A29] pl-4 whitespace-nowrap">₹{selectedServices.reduce((total, s) => total + (Number(s.price) || 0), 0)}</p>
            </div>
            <p className="text-xs font-normal text-[#736B66] mb-6">{formatDuration(selectedServices.reduce((sum, s) => sum + (s.duration_minutes || 0), 0))} • Indiranagar Studio</p>

            <div className="space-y-4">
              <div className="flex items-center gap-3 text-sm text-[#736B66]">
                <CalendarIcon className="w-4 h-4" />
                <span className="font-normal">{selectedDate ? new Date(selectedDate).toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' }) : new Date(getTodayDateString()).toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })}</span>
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
            Make time <br />
            <span className="italic text-[#9A7B4F]">for yourself.</span>
          </h2>
          <div className="flex items-center gap-2 text-sm text-[#736B66]">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
            {branch.address}, {branch.city}
          </div>

          {renderProgressBar()}
        </div>

        {/* STEP 1: SERVICE */}
        {step === 'service' && (() => {
          const categories = Object.keys(groupedServices)
          const currentCategory = activeCategory && categories.includes(activeCategory) ? activeCategory : categories[0]

          return (
            <div className="animate-in fade-in duration-500">
              <p className="text-[10px] font-bold tracking-[0.15em] text-[#736B66] uppercase mb-3">01 / SERVICE</p>
              <h3 className="text-3xl font-serif text-[#2C2A29] mb-8">What are you in the mood for?</h3>

              {/* Category Tabs */}
              {categories.length > 1 && (
                <div className="flex overflow-x-auto gap-4 mb-8 border-b border-[#E5E0DB]">
                  {categories.map((categoryName) => (
                    <button
                      key={categoryName}
                      onClick={() => setActiveCategory(categoryName)}
                      className={`whitespace-nowrap px-1 py-3 text-xs font-bold tracking-wider uppercase transition-colors relative ${currentCategory === categoryName
                        ? 'text-[#2C2A29]'
                        : 'text-[#736B66] hover:text-[#2C2A29]'
                        }`}
                    >
                      {categoryName}
                      {currentCategory === categoryName && (
                        <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#9A7B4F]" />
                      )}
                    </button>
                  ))}
                </div>
              )}

              <div className="space-y-3">
                {currentCategory && groupedServices[currentCategory]?.map((service: Service) => {
                  const isSelected = selectedServices.some(s => s.id === service.id);
                  return (
                    <button
                      key={service.id}
                      onClick={() => handleServiceSelect(service)}
                      className={`w-full text-left bg-white p-6 transition-all border ${isSelected ? 'border-[#9A7B4F] ring-1 ring-[#9A7B4F]' : 'border-[#E5E0DB] hover:border-[#9A7B4F]'}`}
                    >
                      <div className="flex justify-between items-start">
                        <div>
                          <p className="font-semibold text-sm text-[#2C2A29]">{service.name}</p>
                          {service.description && (
                            <p className="text-xs text-[#736B66] mt-1.5">{service.description}</p>
                          )}
                        </div>
                        <div className="text-right">
                          <p className="font-semibold text-sm text-[#2C2A29]">₹{service.price}</p>
                          <p className="text-[11px] text-[#736B66] mt-1">{formatDuration(service.duration_minutes)}</p>
                        </div>
                      </div>
                    </button>
                  )
                })}
              </div>

              {selectedServices.length > 0 && (
                <div className="mt-12 animate-in fade-in slide-in-from-bottom-2">
                  <div className="flex items-center justify-between mb-4 px-2">
                    <span className="text-xs font-semibold text-[#736B66] uppercase tracking-wider">{selectedServices.length} Selected</span>
                    <span className="text-sm font-semibold text-[#2C2A29]">₹{selectedServices.reduce((sum, s) => sum + (s.price || 0), 0)} • {formatDuration(selectedServices.reduce((sum, s) => sum + (s.duration_minutes || 0), 0))}</span>
                  </div>
                  <button
                    onClick={() => setStep('staff')}
                    className="bg-[#332E2C] hover:bg-black text-white text-xs font-bold tracking-[0.1em] px-8 py-4 uppercase flex items-center gap-3 transition-colors w-full justify-center"
                  >
                    CONTINUE <ArrowRight className="w-4 h-4" />
                  </button>
                </div>
              )}
            </div>
          )
        })()}

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
                        <p className="text-[11px] text-[#736B66] mt-0.5 flex items-center gap-1.5">
                          Stylist
                          {s.rating && (
                            <>
                              <span className="w-0.5 h-0.5 rounded-full bg-[#D1CCC8]" />
                              <span className="flex items-center gap-0.5 text-[#2C2A29]">
                                <span className="text-[#9A7B4F] text-[10px]">★</span>
                                <span className="font-semibold">{s.rating}</span>
                                <span className="text-[#736B66]">({s.review_count})</span>
                              </span>
                            </>
                          )}
                        </p>
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
        {step === 'datetime' && (() => {
          const activeDate = selectedDate || getTodayDateString();
          const timeSlots = generateTimeSlots(activeDate);
          const dateObj = new Date(activeDate);
          const formattedDate = dateObj.toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short' });

          const now = new Date();
          const todayOnly = new Date(now.getFullYear(), now.getMonth(), now.getDate());
          const currentDateOnly = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate());
          const isPrevDisabled = currentDateOnly <= todayOnly;

          const totalServiceDuration = selectedServices.reduce((total, s) => total + (s.duration_minutes || 0), 0);
          const formattedDuration = formatDuration(totalServiceDuration);

          return (
            <div className="animate-in fade-in duration-500">
              <p className="text-[10px] font-bold tracking-[0.15em] text-[#736B66] uppercase mb-3">03 / DATE & TIME</p>
              <div className="mb-12">
                <h3 className="text-3xl font-serif text-[#2C2A29] mb-2">Find a time that works.</h3>
                <p className="text-sm text-[#736B66]">Total service duration: <span className="font-semibold text-[#2C2A29]">{formattedDuration}</span></p>
              </div>

              <div className="border border-[#E5E0DB] bg-white mb-6">
                <div className="flex items-center justify-between p-4 border-b border-[#E5E0DB]">
                  <button
                    onClick={handlePrevDay}
                    disabled={isPrevDisabled}
                    className={`p-2 transition-colors ${isPrevDisabled ? 'text-[#D1CCC8] cursor-not-allowed' : 'text-[#736B66] hover:text-[#2C2A29]'}`}
                  >
                    <ArrowLeft className="w-4 h-4" />
                  </button>
                  <span className="text-sm font-semibold text-[#2C2A29] flex items-center gap-2">
                    <svg className="w-4 h-4 text-[#9A7B4F]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                    {formattedDate}
                  </span>
                  <button onClick={handleNextDay} className="p-2 text-[#736B66] hover:text-[#2C2A29]"><ArrowRight className="w-4 h-4" /></button>
                </div>
                <div className="grid grid-cols-3 gap-0 p-4 bg-[#FCFBF8] relative">
                  {isLoadingSlots && (
                    <div className="absolute inset-0 bg-[#FCFBF8]/50 backdrop-blur-[2px] z-20 flex items-center justify-center">
                      <div className="w-5 h-5 border-2 border-[#E5E0DB] border-t-[#9A7B4F] rounded-full animate-spin" />
                    </div>
                  )}
                  {timeSlots.length > 0 ? timeSlots.map((time) => {
                    const isSelected = selectedTime === time;
                    const slotStatus = checkSlotStatus(time, activeDate);
                    const isAvailable = slotStatus === 'available';

                    return (
                      <button
                        key={time}
                        disabled={!isAvailable}
                        onClick={() => handleTimeSelect(activeDate, time)}
                        className={`py-4 text-xs font-semibold text-center border transition-all relative overflow-hidden
                        ${isSelected ? 'border-[#9A7B4F] text-[#9A7B4F] bg-white z-10 ring-1 ring-[#9A7B4F]' :
                            slotStatus === 'booked' ? 'border-transparent bg-[#FFF0F0] text-[#E03E3E] opacity-70 cursor-not-allowed' :
                              slotStatus === 'exceeds_closing' ? 'border-transparent bg-[#FCFBF8] text-[#D1CCC8] opacity-60 cursor-not-allowed' :
                                'border-transparent hover:border-[#E5E0DB] text-[#736B66] bg-white m-[1px]'}
                      `}
                      >
                        {time}
                      </button>
                    )
                  }) : (
                    <div className="col-span-3 text-center py-8 text-sm text-[#736B66]">Salon is closed on this day.</div>
                  )}
                </div>
              </div>

              <div className="flex flex-wrap items-center gap-6 justify-center text-xs text-[#736B66]">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-white border border-[#E5E0DB]"></div>
                  <span>Available</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-[#E03E3E] border border-[#E03E3E]"></div>
                  <span>Booked</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-[#E5E0DB] border border-[#E5E0DB] opacity-60"></div>
                  <span>Not enough time</span>
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
          )
        })()}

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
                <span className="text-xs text-[#736B66]">Service{selectedServices.length > 1 ? 's' : ''}</span>
                <span className="text-sm font-semibold text-[#2C2A29] text-right max-w-[60%] truncate">{selectedServices.map(s => s.name).join(', ')}</span>
              </div>
              <div className="flex items-center justify-between p-6 border-b border-[#E5E0DB]">
                <span className="text-xs text-[#736B66]">When</span>
                <span className="text-sm font-semibold text-[#2C2A29]">{selectedDate ? new Date(selectedDate).toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short' }) : new Date(getTodayDateString()).toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short' })} • {selectedTime}</span>
              </div>
              <div className="flex items-center justify-between p-6 border-b border-[#E5E0DB]">
                <span className="text-xs text-[#736B66]">With</span>
                <span className="text-sm font-semibold text-[#2C2A29]">{selectedStaff === 'any' ? 'Anyone available' : (selectedStaff as Staff)?.name || 'Stylist'}</span>
              </div>
              <div className="flex items-center justify-between p-6 border-b border-[#E5E0DB]">
                <span className="text-xs text-[#736B66]">Total Duration</span>
                <span className="text-sm font-semibold text-[#2C2A29]">{formatDuration(selectedServices.reduce((sum, s) => sum + (s.duration_minutes || 0), 0))}</span>
              </div>
              <div className="flex items-center justify-between p-6 border-b border-[#E5E0DB]">
                <span className="text-xs text-[#736B66]">Total Price</span>
                <span className="text-sm font-semibold text-[#2C2A29]">₹{selectedServices.reduce((total, s) => total + (Number(s.price) || 0), 0)}</span>
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
