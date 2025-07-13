FROM node:18-alpine AS builder

# Define build arguments for environment variables
ARG VITE_BACKEND_ENDPOINT
ARG VITE_SERVER_HOSTNAME

# Set environment variables during the build process
ENV VITE_BACKEND_ENDPOINT=$VITE_BACKEND_ENDPOINT
ENV VITE_SERVER_HOSTNAME=$VITE_SERVER_HOSTNAME

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

RUN npm i -g serve

COPY . .

RUN npm run build

EXPOSE 3000

CMD [ "serve", "-s", "dist" ]