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
            body { font-family: system-ui, -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: white; }
            .poster { text-align: center; max-width: 500px; padding: 40px; border: 2px solid #f3f4f6; border-radius: 24px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); }
            h1 { font-size: 2.5rem; font-weight: 900; margin: 0 0 10px 0; color: #111827; }
            h2 { font-size: 1.5rem; font-weight: 700; margin: 0 0 30px 0; color: #4B5563; }
            .qr-container { display: inline-block; padding: 20px; background: white; border-radius: 16px; border: 1px solid #e5e7eb; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 30px; }
            svg { width: 300px; height: 300px; display: block; }
            p.instruction { font-size: 1.25rem; font-weight: 500; color: #6B7280; margin-bottom: 20px; }
            .phone { font-size: 1.5rem; font-weight: 700; color: #111827; display: flex; align-items: center; justify-content: center; gap: 8px; }
          </style>
        </head>
        <body>
          <div class="poster">
            <h2>SCAN TO BOOK</h2>
            <div class="qr-container">
              ${qrSvg}
            </div>
            <h1>${salonName}</h1>
            <p class="instruction">Book your appointment in seconds</p>
            ${phone ? `<div class="phone">📞 ${phone}</div>` : ''}
          </div>
          <script>
            window.onload = () => { window.print(); window.close(); }
          </script>
        </body>
      </html>
    `
    printWindow.document.write(html)
    printWindow.document.close()
  }

  return (
    <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm max-w-md mx-auto" ref={containerRef}>
      <div className="text-center mb-6">
        <h3 className="text-sm font-bold text-gray-400 uppercase tracking-wider mb-1">Customer Booking</h3>
        <div className="flex items-center justify-center gap-2 mb-2">
          <span className="w-2.5 h-2.5 rounded-full bg-green-500 animate-pulse"></span>
          <span className="font-medium text-gray-900">Online Booking Enabled</span>
        </div>
        <p className="text-sm text-gray-500 break-all">{url}</p>
      </div>

      <div className="bg-gray-50 p-6 rounded-xl flex items-center justify-center mb-6">
        {qrSvg ? (
          <div 
            className="w-48 h-48 bg-white p-2 rounded-lg shadow-sm border border-gray-100"
            dangerouslySetInnerHTML={{ __html: qrSvg }}
          />
        ) : (
          <div className="w-48 h-48 bg-gray-200 animate-pulse rounded-lg" />
        )}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <button 
          onClick={() => { navigator.clipboard.writeText(url); alert('Link copied!') }}
          className="col-span-2 py-2 px-4 bg-gray-100 hover:bg-gray-200 text-gray-800 font-medium rounded-lg transition-colors"
        >
          Copy Link
        </button>
        <button 
          onClick={downloadPNG}
          className="py-2 px-4 bg-blue-50 hover:bg-blue-100 text-blue-700 font-medium rounded-lg transition-colors"
        >
          Download PNG
        </button>
        <button 
          onClick={downloadSVG}
          className="py-2 px-4 bg-blue-50 hover:bg-blue-100 text-blue-700 font-medium rounded-lg transition-colors"
        >
          Download SVG
        </button>
        <button 
          onClick={printQR}
          className="col-span-2 py-3 px-4 bg-gray-900 hover:bg-black text-white font-semibold rounded-lg transition-colors mt-2"
        >
          Print Poster
        </button>
      </div>
    </div>
  )
}
