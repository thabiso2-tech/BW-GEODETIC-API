# Botswana Geodetic Suite - Full Stack Guide

Complete guide for the web app, mobile app, and QGIS plugin.

## 📋 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  Botswana Geodetic Suite                 │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Web App    │  │  Mobile App  │  │ QGIS Plugin  │   │
│  │  (React)     │  │ (React Nat.) │  │  (Python)    │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│         │                 │                    │         │
│         └─────────────────┼────────────────────┘         │
│                           │                              │
│                    ┌──────▼──────┐                       │
│                    │  FastAPI    │                       │
│                    │  Backend    │                       │
│                    │  :8000      │                       │
│                    └─────────────┘                       │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## 🌐 Web Application

Modern React/TypeScript web application with real-time coordinate transformation.

### Features
- ✅ Interactive dashboard
- ✅ Coordinate transformation between CRS systems
- ✅ Real-time map visualization
- ✅ Historical data management
- ✅ Export/Import functionality
- ✅ Responsive design (mobile-friendly)

### Access
- **Development**: http://localhost:5173
- **Production**: http://yourdomain.com

### Running
```bash
# Development with hot reload
docker compose up web

# Production build
npm run build
docker build -t bw-geodetic-web .
```

### Technologies
- React 18
- TypeScript
- Vite
- Axios for API calls
- Zustand for state management
- Leaflet for maps
- CSS Grid/Flexbox

## 📱 Mobile Application

Cross-platform mobile app built with React Native/Expo for field operations.

### Features
- ✅ Real-time GPS location tracking
- ✅ Offline coordinate calculations
- ✅ Coordinate transformation on device
- ✅ Measurement history
- ✅ Data synchronization
- ✅ iOS & Android support

### Installation
```bash
# Install Expo CLI
npm install -g eas-cli expo-cli

# Navigate to mobile directory
cd mobile

# Install dependencies
npm install

# Run on Android
npm run android

# Run on iOS
npm run ios

# Run on web
npm run web
```

### Building for Release
```bash
# Build iOS
eas build --platform ios

# Build Android
eas build --platform android

# Build both
eas build
```

### Technologies
- React Native
- Expo
- expo-location (GPS)
- React Navigation
- Axios for API
- Zustand for state

### Environment
Create `.env` in `mobile` directory:
```
EXPO_PUBLIC_API_URL=https://api.yourdomain.com
```

## 🗺️ QGIS Plugin

Professional GIS integration plugin for QGIS Desktop.

### Features
- ✅ Coordinate transformation integration
- ✅ Batch processing of coordinates
- ✅ Direct QGIS map integration
- ✅ Export results to layers
- ✅ Historical tracking
- ✅ Supports QGIS 3.22+

### Installation

1. **Location**: Copy the `qgis_plugin` folder to your QGIS plugins directory:
   - **Linux**: `~/.local/share/QGIS/QGIS3/profiles/default/python/plugins/`
   - **macOS**: `~/Library/Application Support/QGIS/QGIS3/profiles/default/python/plugins/`
   - **Windows**: `%APPDATA%\QGIS\QGIS3\profiles\default\python\plugins\`

2. **Rename**: Rename folder to `bw_geodetic`

3. **Enable in QGIS**:
   - Open QGIS
   - Go to Plugins → Manage and Install Plugins
   - Search for "Botswana Geodetic"
   - Click Install Plugin

### Usage

1. **Open Plugin**: Plugins → Botswana Geodetic Suite → Transform Coordinates
2. **Enter Coordinates**: Input latitude, longitude, and height
3. **Select CRS**: Choose source and target coordinate systems
4. **Transform**: Click "Transform" button
5. **Add to Map**: Click "Add to Map as Point" to visualize results

### Requirements
```
QGIS >= 3.22
PyQGIS
requests
```

## 🚀 Deployment

### Development Environment
```bash
# Start all services
docker compose up

# Services available:
# - Backend API: http://localhost:8000
# - Web App: http://localhost:5173
# - Streamlit Frontend: http://localhost:8501
# - QGIS Plugin: Desktop application
```

### Production Environment
```bash
# Set environment variables
export DOCKER_USERNAME=your-username
export VERSION=1.0.0

# Deploy all services
docker compose -f docker-compose.prod.yml up -d

# Services available:
# - Backend API: http://localhost:8000
# - Web App: http://localhost:5173
# - Streamlit Frontend: http://localhost:8501
```

## 🔌 API Integration

### Base URL
- Development: `http://localhost:8000`
- Production: `https://api.yourdomain.com`

### Main Endpoints

#### Transform Coordinates
```bash
POST /api/v1/transform
Content-Type: application/json

{
  "latitude": 25.2608,
  "longitude": 25.9165,
  "height": 0,
  "source_crs": "EPSG:4326",
  "target_crs": "EPSG:3857"
}
```

#### Health Check
```bash
GET /health
```

#### Coordinate Adjustment
```bash
POST /api/v1/adjust
Content-Type: application/json

{
  "coordinates": [
    {"latitude": 25.2608, "longitude": 25.9165},
    {"latitude": 25.2610, "longitude": 25.9167}
  ]
}
```

## 📊 Data Management

### Coordinate Storage
- Web App: Browser localStorage (Zustand store)
- Mobile: Async Storage / Device local database
- Backend: Can persist to database (configure in production)

### Export Formats
- CSV
- GeoJSON
- Shapefile (via QGIS)
- KML

## 🔒 Security Considerations

1. **API Authentication**: Add JWT tokens for production
2. **CORS**: Configure CORS headers properly
3. **HTTPS**: Always use HTTPS in production
4. **API Keys**: Protect sensitive endpoints
5. **Data Privacy**: Handle coordinates securely

## 📦 Docker Images

### Building Images
```bash
# Backend
docker build -t bw-geodetic-backend:latest ./backend

# Web App
docker build -t bw-geodetic-web:latest ./web

# Frontend (Streamlit)
docker build -t bw-geodetic-frontend:latest ./frontend
```

### Pushing to Registry
```bash
# Tag images
docker tag bw-geodetic-backend:latest username/backend:1.0.0
docker tag bw-geodetic-web:latest username/web:1.0.0
docker tag bw-geodetic-frontend:latest username/frontend:1.0.0

# Push to Docker Hub
docker push username/backend:1.0.0
docker push username/web:1.0.0
docker push username/frontend:1.0.0
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
pip install pytest
pytest tests/
```

### Web App Tests
```bash
cd web
npm test
```

### Mobile Tests
```bash
cd mobile
npm test
```

## 📝 Project Structure

```
BW_Geodetic_Suite/
├── backend/              # FastAPI backend
│   ├── app/
│   │   ├── main.py
│   │   └── core/
│   ├── api/
│   │   └── v1/
│   │       └── adjust.py
│   └── requirements.txt
├── web/                  # React web app
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── api/
│   │   ├── store/
│   │   └── App.tsx
│   ├── package.json
│   └── Dockerfile
├── mobile/               # React Native mobile app
│   ├── src/
│   ├── App.tsx
│   ├── app.json
│   └── package.json
├── frontend/             # Streamlit dashboard
│   ├── app.py
│   └── requirements.txt
├── qgis_plugin/          # QGIS plugin
│   ├── plugin.py
│   └── metadata.txt
├── docker-compose.yml
├── docker-compose.prod.yml
└── FULL_STACK_GUIDE.md
```

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/name`
2. Commit changes: `git commit -am 'Add feature'`
3. Push to branch: `git push origin feature/name`
4. Submit pull request

## 📄 License

MIT License - See LICENSE file for details

## 📞 Support

For issues and questions:
- GitHub Issues: https://github.com/your-repo/issues
- Email: support@bw-geodetic.bw
