export default function Home() {
  return (
    <div className="flex flex-col flex-1 items-center justify-center min-h-screen bg-zinc-50 dark:bg-black p-8">
      <main className="flex flex-col items-center max-w-2xl text-center space-y-6">
        <h1 className="text-4xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100 sm:text-6xl">
          Welcome to SalonQR
        </h1>
        <p className="text-lg leading-8 text-zinc-600 dark:text-zinc-400">
          The easiest way to book and manage your salon appointments.
        </p>
        <div className="flex gap-4 mt-8">
          {/* Example of linking to their routes, although we don't know the exact branch IDs yet */}
          <a
            href="/b/demo"
            className="rounded-full bg-zinc-900 px-6 py-3 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 dark:bg-white dark:text-black dark:hover:bg-zinc-200"
          >
            Book Appointment
          </a>
        </div>
      </main>
    </div>
  );
}
