#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Local Website Testing with Docker${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Configuration
IMAGE_NAME="super-octo-adventure-local"
CONTAINER_NAME="website-test"
PORT=8080

# Stop and remove existing container if running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo -e "${YELLOW}Stopping existing container...${NC}"
    docker stop $CONTAINER_NAME > /dev/null 2>&1
fi

if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo -e "${YELLOW}Removing existing container...${NC}"
    docker rm $CONTAINER_NAME > /dev/null 2>&1
fi

# Build the Docker image
echo -e "${BLUE}Building Docker image...${NC}"
docker build -t $IMAGE_NAME -f docker/Dockerfile .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build successful!${NC}\n"
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

# Run the container with volume mounting for live changes
echo -e "${BLUE}Starting container on port $PORT...${NC}"
docker run -d \
    --name $CONTAINER_NAME \
    -p $PORT:80 \
    -v "$(pwd)/frontend:/usr/local/apache2/htdocs" \
    $IMAGE_NAME

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Container started successfully!${NC}\n"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Website is now accessible at:${NC}"
    echo -e "${GREEN}  http://localhost:$PORT${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    echo -e "${YELLOW}Tips:${NC}"
    echo -e "  - Edit files in ./frontend/ and refresh your browser to see changes"
    echo -e "  - Run 'docker logs $CONTAINER_NAME' to view Apache logs"
    echo -e "  - Run 'docker stop $CONTAINER_NAME' to stop the server"
    echo -e "  - Run './test-local.sh' again to rebuild and restart\n"
else
    echo -e "${RED}Failed to start container!${NC}"
    exit 1
fi
