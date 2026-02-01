#!/bin/bash
set -e

echo "🚀 VoltTrack Self-Hosted Setup"
echo "================================"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    
    echo ""
    echo "⚠️  IMPORTANT: Configure your .env file before starting!"
    echo ""
    echo "Required changes:"
    echo "  1. BETTER_AUTH_SECRET - Generate with: openssl rand -base64 32"
    echo "  2. POSTGRES_PASSWORD - Use a strong password"
    echo "  3. GARAGE_RPC_SECRET - Generate with: openssl rand -base64 32"
    echo "  4. MAPBOX_KEY - Get from https://www.mapbox.com/"
    echo ""
    echo "Optional changes:"
    echo "  - Update BETTER_AUTH_URL, API_URL, WEBSOCKET_URL for your domain"
    echo "  - Configure CORS_CONFIG for your domain"
    echo ""
    
    read -p "Press Enter to open .env in your default editor, or Ctrl+C to exit..."
    ${EDITOR:-nano} .env
    
    echo ""
fi

# Ask about S3
echo "S3 Storage Configuration"
echo "========================"
echo ""
echo "VoltTrack can generate reports and store them in S3-compatible storage."
echo ""
echo "Options:"
echo "  1. Use included Garage S3 (auto-configured, recommended)"
echo "  2. Use external S3 (AWS S3, MinIO, etc.)"
echo "  3. Skip S3 (reports feature disabled)"
echo ""

read -p "Choose option (1/2/3): " s3_option

if [ "$s3_option" = "1" ]; then
    PROFILE_ARG="--profile s3"
    echo ""
    echo "✅ Will start with Garage S3"
    echo "   Check 'docker logs volttrack-garage-init' after startup for credentials"
elif [ "$s3_option" = "2" ]; then
    PROFILE_ARG=""
    echo ""
    echo "✅ Using external S3"
    echo "   Make sure S3_ENDPOINT and AWS_* variables are configured in .env"
else
    PROFILE_ARG=""
    echo ""
    echo "⚠️  Starting without S3 (reports disabled)"
fi

echo ""
echo "Starting VoltTrack services..."
echo "==============================="
echo ""

# Start services
docker compose $PROFILE_ARG up -d

echo ""
echo "✅ VoltTrack is starting!"
echo ""
echo "Services:"
echo "  - Web App:      http://localhost:3000"
echo "  - API:          http://localhost:3001"
echo "  - API Docs:     http://localhost:3001/docs"
echo "  - Auth:         http://localhost:3002"
echo "  - WebSocket:    ws://localhost:3003"
echo "  - Redis Insight: http://localhost:8001"
echo ""

if [ "$s3_option" = "1" ]; then
    echo "📦 Garage S3 Credentials:"
    echo "   Run: docker logs volttrack-garage-init"
    echo ""
fi

echo "📊 Check status:"
echo "   docker compose ps"
echo ""
echo "📝 View logs:"
echo "   docker compose logs -f"
echo ""
echo "🛑 Stop services:"
echo "   docker compose down"
echo ""
