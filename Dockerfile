# Use Node.js 18 LTS as base image
FROM node:18-slim

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY main.js ./
COPY public/ ./public/

# Expose port (Cloud Run will provide PORT env var)
EXPOSE 8080

# Start the application
CMD ["node", "main.js"]