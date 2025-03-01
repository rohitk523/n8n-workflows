#!/bin/bash

# Ensure .env file exists
if [ ! -f .env ]; then
  echo "Error: .env file not found!"
  exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
  echo "docker-compose could not be found, installing..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

# Start ngrok service first
echo "Starting ngrok service..."
sudo docker-compose -f docker-compose.ngrok.yml up -d

# Wait for ngrok to establish the tunnel
echo "Waiting for ngrok to establish the tunnel..."
sleep 15

# Get the ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | cut -d'"' -f4)

if [ -z "$NGROK_URL" ]; then
  echo "Failed to get ngrok URL. Please check if ngrok is running properly."
  echo "You can check ngrok status at: http://localhost:4040"
  echo "Checking ngrok container logs:"
  sudo docker-compose -f docker-compose.ngrok.yml logs ngrok
  exit 1
fi

echo "Ngrok tunnel established at: $NGROK_URL"

# Update the .env file with the new webhook URL
sed -i "s|WEBHOOK_URL=.*|WEBHOOK_URL=$NGROK_URL|g" .env
echo "Updated .env file with webhook URL: $NGROK_URL"

# Now start n8n and postgres with the updated webhook URL
echo "Starting n8n and PostgreSQL services..."
sudo docker-compose up -d

echo "Setup complete! Your n8n instance is now accessible via ngrok at: $NGROK_URL"
echo "You can access the ngrok dashboard at: http://localhost:4040"