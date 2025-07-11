import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/

const API_BASE_URL = "http://private-lb-fp-75f4d042e793c434.elb.us-east-1.amazonaws.com"

export default defineConfig({
  plugins: [react()],
})
