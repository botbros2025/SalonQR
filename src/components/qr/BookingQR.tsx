'use client'

import { useEffect, useState, useRef } from 'react'
import QRCode from 'qrcode'

interface BookingQRProps {
  url: string
  salonName: string
  phone?: string
}

export default function BookingQR({ url, salonName, phone }: BookingQRProps) {
  const [qrSvg, setQrSvg] = useState<string>('')
  const [qrDataUrl, setQrDataUrl] = useState<string>('')
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    // Generate SVG for printing/scaling
    QRCode.toString(url, {
      type: 'svg',
      margin: 2,
      color: { dark: '#000000', light: '#ffffff' },
      errorCorrectionLevel: 'H'
    }).then(setQrSvg).catch(console.error)

    // Generate PNG Data URL for downloading
    QRCode.toDataURL(url, {
      margin: 2,
      width: 1024,
      color: { dark: '#000000', light: '#ffffff' },
      errorCorrectionLevel: 'H'
    }).then(setQrDataUrl).catch(console.error)
  }, [url])

  const downloadPNG = () => {
    if (!qrDataUrl) return
    const a = document.createElement('a')
    a.href = qrDataUrl
    a.download = `booking-qr-${salonName.replace(/\\s+/g, '-').toLowerCase()}.png`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
  }

  const downloadSVG = () => {
    if (!qrSvg) return
    const blob = new Blob([qrSvg], { type: 'image/svg+xml' })
    const svgUrl = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = svgUrl
    a.download = `booking-qr-${salonName.replace(/\\s+/g, '-').toLowerCase()}.svg`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(svgUrl)
  }

  const printQR = () => {
    if (!containerRef.current) return
    
    // Create an iframe to print just the QR poster
    const printWindow = window.open('', '_blank')
    if (!printWindow) return

    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <title>Print QR Code</title>
          <style>
            @page { margin: 0; }
            body { font-family: 'Inter', system-ui, -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: white; }
            .poster { background: #1E2E25; border-radius: 40px; padding: 60px 40px; width: 420px; text-align: center; color: white; position: relative; border-top: 12px solid #D4AF37; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
            h2 { font-size: 2.5rem; font-weight: 900; margin: 0; text-transform: uppercase; letter-spacing: -1px; }
            .highlight { color: #F3E5AB; }
            .subtitle { font-size: 1.2rem; font-weight: 500; color: rgba(255,255,255,0.7); margin: 10px 0 40px 0; }
            .qr-card { background: white; border-radius: 30px; padding: 30px; margin: 0 auto; box-shadow: 0 20px 40px rgba(0,0,0,0.4); position: relative; }
            .qr-corners { position: absolute; top: 15px; left: 15px; right: 15px; bottom: 15px; border: 4px solid #1E2E25; border-radius: 20px; z-index: 1; pointer-events: none; }
            .qr-corners::before { content: ''; position: absolute; top: -10px; bottom: -10px; left: 20px; right: 20px; background: white; }
            .qr-corners::after { content: ''; position: absolute; left: -10px; right: -10px; top: 20px; bottom: 20px; background: white; }
            .qr-inner { position: relative; z-index: 2; }
            svg { width: 100%; height: auto; display: block; max-width: 280px; margin: 0 auto; }
            .salon-info { border-top: 2px dashed #eee; margin-top: 20px; padding-top: 20px; color: #1E2E25; }
            h1 { font-size: 2rem; font-weight: 900; margin: 0; text-transform: uppercase; letter-spacing: -1px; line-height: 1.1; }
            .phone { font-size: 1.2rem; font-weight: 600; color: #666; margin-top: 8px; }
            .footer { margin-top: 40px; font-size: 0.8rem; font-weight: 700; letter-spacing: 4px; color: rgba(255,255,255,0.4); text-transform: uppercase; }
          </style>
        </head>
        <body>
          <div class="poster">
            <h2>Scan to <span class="highlight">Book</span></h2>
            <div class="subtitle">Instant Appointment Booking</div>
            <div class="qr-card">
              <div class="qr-corners"></div>
              <div class="qr-inner">
                ${qrSvg}
                <div class="salon-info">
                  <h1>${salonName}</h1>
                  ${phone ? `<div class="phone">${phone}</div>` : ''}
                  <div style="margin-top: 10px; font-size: 0.9rem; color: #8B9891; word-break: break-all;">${url}</div>
                </div>
              </div>
            </div>
            <div class="footer">Powered by SalonQR</div>
          </div>
          <script>
            window.onload = () => { setTimeout(() => { window.print(); window.close(); }, 500) }
          </script>
        </body>
      </html>
    `
    printWindow.document.write(html)
    printWindow.document.close()
  }

  return (
    <div className="max-w-md mx-auto w-full" ref={containerRef}>
      {/* Standee Frame */}
      <div className="bg-gradient-to-br from-[#1E2E25] via-[#2a4034] to-[#16231c] p-6 pt-10 rounded-[32px] shadow-2xl relative overflow-hidden mb-6 ring-4 ring-gray-900/5">
        
        {/* Top accent */}
        <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-[#D4AF37] via-[#F3E5AB] to-[#D4AF37]"></div>
        
        {/* Background Decorative elements */}
        <div className="absolute -right-16 -top-16 w-40 h-40 bg-white opacity-5 rounded-full blur-3xl pointer-events-none"></div>
        <div className="absolute -left-16 top-32 w-40 h-40 bg-[#D4AF37] opacity-5 rounded-full blur-3xl pointer-events-none"></div>

        <div className="text-center mb-8 relative z-10">
          <div className="inline-flex items-center justify-center gap-1.5 bg-white/10 border border-white/10 px-4 py-1 rounded-full text-white/90 text-xs font-bold tracking-widest uppercase mb-5 backdrop-blur-sm shadow-sm">
            <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse"></span>
            FAST & EASY
          </div>
          <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight uppercase leading-none">
            Scan to <span className="text-[#F3E5AB]">Book</span>
          </h2>
          <p className="text-white/60 font-medium mt-3 text-base sm:text-lg">Instant Appointment Booking</p>
        </div>

        <div className="bg-white p-3 rounded-3xl shadow-[0_20px_50px_rgba(0,0,0,0.3)] relative z-10 mx-1 sm:mx-4">
          {/* Decorative scanner corners */}
          <div className="absolute top-3 left-3 w-8 h-8 border-t-4 border-l-4 border-[#1E2E25] rounded-tl-xl pointer-events-none"></div>
          <div className="absolute top-3 right-3 w-8 h-8 border-t-4 border-r-4 border-[#1E2E25] rounded-tr-xl pointer-events-none"></div>
          <div className="absolute bottom-3 left-3 w-8 h-8 border-b-4 border-l-4 border-[#1E2E25] rounded-bl-xl pointer-events-none"></div>
          <div className="absolute bottom-3 right-3 w-8 h-8 border-b-4 border-r-4 border-[#1E2E25] rounded-br-xl pointer-events-none"></div>
          
          <div className="flex items-center justify-center py-6 px-6 relative z-0">
            {qrSvg ? (
              <div 
                className="w-full max-w-[220px] aspect-square mx-auto [&>svg]:w-full [&>svg]:h-full"
                dangerouslySetInnerHTML={{ __html: qrSvg }}
              />
            ) : (
              <div className="w-full max-w-[220px] aspect-square bg-gray-100 animate-pulse rounded-xl mx-auto" />
            )}
          </div>
          
          <div className="text-center pb-3 pt-4 border-t-2 border-dashed border-gray-100 mt-2 px-2">
            <p className="text-[#1E2E25] font-black text-xl sm:text-2xl tracking-tight truncate">{salonName}</p>
            {phone && <p className="text-gray-500 font-semibold text-sm mt-1">{phone}</p>}
            <p className="text-[#8B9891] text-xs mt-2 break-all font-medium">{url}</p>
          </div>
        </div>

        <div className="text-center mt-8 text-white/40 text-[10px] font-bold tracking-[0.2em] flex items-center justify-center gap-2">
          POWERED BY SALONQR 
        </div>
      </div>

      {/* Actions */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <button 
          onClick={() => { navigator.clipboard.writeText(url); alert('Link copied!') }}
          className="col-span-1 sm:col-span-2 py-3.5 px-4 bg-white border border-gray-200 hover:bg-gray-50 hover:border-gray-300 text-gray-800 font-bold rounded-2xl shadow-sm transition-all active:scale-[0.98]"
        >
          Copy Booking Link
        </button>
        <button 
          onClick={downloadPNG}
          className="py-3.5 px-4 bg-[#F3E5AB] hover:bg-[#eaddca] text-[#8F6A44] font-bold rounded-2xl shadow-sm transition-all active:scale-[0.98]"
        >
          Save Image
        </button>
        <button 
          onClick={printQR}
          className="py-3.5 px-4 bg-[#1E2E25] hover:bg-black text-white font-bold rounded-2xl shadow-sm transition-all active:scale-[0.98]"
        >
          Print Standee
        </button>
      </div>
    </div>
  )
}
