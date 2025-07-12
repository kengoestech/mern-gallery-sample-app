FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install
RUN npm i -g serve

# Copy the rest of the code
COPY . .

# Define build args BEFORE the build command
ARG VITE_BACKEND_ENDPOINT
ARG VITE_SERVER_HOSTNAME

# Build the Vite app using env vars
ENV VITE_BACKEND_ENDPOINT=$VITE_BACKEND_ENDPOINT
ENV VITE_SERVER_HOSTNAME=$VITE_SERVER_HOSTNAME
RUN npm run build

# Expose and serve the build
EXPOSE 3000
CMD ["serve", "-s", "dist"]
