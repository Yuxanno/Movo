export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { connectDB } = await import('./lib/db')
    try {
      await connectDB()
      console.log('✅ MongoDB Connected successfully!')
    } catch (err) {
      console.error('❌ MongoDB connection FAILED:', err)
    }
  }
}
