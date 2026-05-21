#!/bin/bash
# Initial Server Setup Script
# Run this on your production/staging server before first deployment

set -e

echo "=========================================="
echo "Geodetic Suite - Server Setup Script"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Step 1: System Update${NC}"
sudo apt-get update
sudo apt-get upgrade -y

echo -e "${BLUE}Step 2: Install Docker${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed. You may need to log out and log back in."
else
    echo "Docker already installed."
fi

echo -e "${BLUE}Step 3: Install Docker Compose${NC}"
sudo apt-get install -y docker-compose-plugin

echo -e "${BLUE}Step 4: Create Deployment Directory${NC}"
sudo mkdir -p /opt/geodetic-suite
sudo chown $USER:$USER /opt/geodetic-suite

echo -e "${BLUE}Step 5: Clone Repository${NC}"
read -p "GitHub Repository URL (https://github.com/org/repo.git): " REPO_URL
cd /opt/geodetic-suite
git clone "$REPO_URL" .

echo -e "${BLUE}Step 6: Configure Environment${NC}"
if [ ! -f ".env.prod" ]; then
    cp .env.prod.example .env.prod
    echo "Created .env.prod - Please edit with your configuration"
    echo "Path: /opt/geodetic-suite/.env.prod"
fi

echo -e "${BLUE}Step 7: Create Docker Network${NC}"
docker network create geodetic-network 2>/dev/null || echo "Network already exists"

echo -e "${BLUE}Step 8: Configure Firewall${NC}"
if command -v ufw &> /dev/null; then
    sudo ufw allow 22/tcp   # SSH
    sudo ufw allow 80/tcp   # HTTP
    sudo ufw allow 443/tcp  # HTTPS
    sudo ufw allow 8000/tcp # Backend API
    sudo ufw allow 8501/tcp # Frontend
    echo "Firewall rules added"
fi

echo -e "${BLUE}Step 9: Setup Log Rotation${NC}"
cat << 'EOF' | sudo tee /etc/logrotate.d/geodetic-suite > /dev/null
/opt/geodetic-suite/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 $USER $USER
    sharedscripts
}
EOF

echo ""
echo -e "${GREEN}=========================================="
echo "Server Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Edit /opt/geodetic-suite/.env.prod with your configuration"
echo "2. Configure GitHub SSH key for automatic deployments:"
echo "   - Add your deployment public key to ~/.ssh/authorized_keys"
echo "3. First deployment: docker compose -f docker-compose.prod.yml up -d"
echo ""
echo "Verify installation:"
echo "- docker --version"
echo "- docker compose version"
echo "- docker network ls"
echo ""
