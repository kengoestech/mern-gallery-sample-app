import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/

const API_BASE_URL = "private-lb-fp-3a5e927ca6890b41.elb.us-east-1.amazonaws.com"

export default defineConfig({
  plugins: [react()],
})
