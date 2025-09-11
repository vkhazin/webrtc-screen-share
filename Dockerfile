# Build stage
FROM node:18-slim AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci && npm cache clean --force

# Copy source files
COPY main.js ./
COPY public/ ./public/

# Production stage
FROM node:18-slim AS production

# Add metadata labels
LABEL maintainer="webrtc-screen-share"
LABEL description="WebRTC Screen Share Application"

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source files from builder stage
COPY --from=builder /app/main.js ./
COPY --from=builder /app/public ./public

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose the port that Cloud Run expects
EXPOSE 8080

# Start the application
CMD ["node", "main.js"]
