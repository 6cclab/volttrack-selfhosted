#!/bin/sh
set -e

echo "🚀 Initializing Garage S3 storage..."

# Wait for Garage to be ready
sleep 5

# Set Garage host
export GARAGE_RPC_HOST=garage:3901

# Check if node already exists
if garage status | grep -q "garage"; then
    echo "✅ Garage node already configured, skipping initialization"
else
    echo "📦 Connecting to Garage node..."
    
    # Get the node ID
    NODE_ID=$(garage node id | grep "^[0-9a-f]" | awk '{print $1}')
    echo "Node ID: $NODE_ID"
    
    # Create layout (single node)
    echo "🏗️  Creating single-node layout..."
    garage layout assign -z dc1 -c 1G "$NODE_ID"
    garage layout apply --version 1
    
    echo "✅ Layout created"
fi

# Check if bucket already exists
if garage bucket list | grep -q "$GARAGE_BUCKET"; then
    echo "✅ Bucket '$GARAGE_BUCKET' already exists"
else
    echo "🪣  Creating bucket: $GARAGE_BUCKET"
    garage bucket create "$GARAGE_BUCKET"
fi

# Check if key already exists
if garage key list | grep -q "$GARAGE_ACCESS_KEY"; then
    echo "✅ Access key '$GARAGE_ACCESS_KEY' already exists"
else
    echo "🔑 Creating access key: $GARAGE_ACCESS_KEY"
    garage key create "$GARAGE_ACCESS_KEY"
    
    # Import the secret key if provided
    if [ -n "$GARAGE_SECRET_KEY" ]; then
        garage key import "$GARAGE_ACCESS_KEY" "$GARAGE_SECRET_KEY"
        echo "✅ Imported custom secret key"
    fi
fi

# Allow the key to access the bucket
echo "🔗 Granting bucket permissions..."
garage bucket allow --read --write "$GARAGE_BUCKET" --key "$GARAGE_ACCESS_KEY"

# Get the actual secret key for display
SECRET_KEY=$(garage key info "$GARAGE_ACCESS_KEY" | grep "Secret key:" | awk '{print $3}')

echo ""
echo "✅ Garage initialization complete!"
echo ""
echo "=========================================="
echo "S3 Configuration:"
echo "=========================================="
echo "Endpoint:   http://garage:3900"
echo "Region:     garage"
echo "Bucket:     $GARAGE_BUCKET"
echo "Access Key: $GARAGE_ACCESS_KEY"
echo "Secret Key: $SECRET_KEY"
echo "=========================================="
echo ""
echo "Add these to your .env file if not already set:"
echo "AWS_ACCESS_KEY_ID=$GARAGE_ACCESS_KEY"
echo "AWS_SECRET_ACCESS_KEY=$SECRET_KEY"
echo "S3_ENDPOINT=http://garage:3900"
echo "AWS_BUCKET=$GARAGE_BUCKET"
echo "AWS_REGION=garage"
echo "FORCE_PATH_STYLE=true"
echo "=========================================="
