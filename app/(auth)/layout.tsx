export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 bg-gray-700 flex items-center justify-center">
      <div className="w-[375px] h-screen max-h-[812px] bg-[#f0f7f4] shadow-2xl overflow-hidden relative flex flex-col">
        {children}
      </div>
    </div>
  )
}
