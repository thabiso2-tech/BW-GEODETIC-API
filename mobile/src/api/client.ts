import axios from 'axios'

const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8000'

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

export interface CoordinateData {
  latitude: number
  longitude: number
  height?: number
  source_crs?: string
  target_crs?: string
}

export const geodeticsAPI = {
  health: () => apiClient.get('/health'),
  
  transform: (data: CoordinateData) =>
    apiClient.post('/api/v1/transform', data),
  
  adjustCoordinates: (coordinates: CoordinateData[]) =>
    apiClient.post('/api/v1/adjust', { coordinates }),
}

export default apiClient
