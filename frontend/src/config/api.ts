const DEFAULT_API_ORIGIN = 'http://localhost:5001'

function trimTrailingSlash(url: string): string {
  return url.replace(/\/+$/, '')
}

const envOrigin = (import.meta.env.VITE_API_BASE_URL || '').trim()
const isLocalBrowser =
  typeof window !== 'undefined' &&
  ['localhost', '127.0.0.1'].includes(window.location.hostname)

// In local Vite dev, prefer the same-origin /api proxy instead of hard-coding
// localhost:5001. This avoids CORS issues when Vite auto-switches from 3000 to 3001.
export const API_ORIGIN = trimTrailingSlash(
  isLocalBrowser ? '' : (envOrigin || DEFAULT_API_ORIGIN)
)
export const API_BASE_URL = API_ORIGIN ? `${API_ORIGIN}/api` : '/api'
