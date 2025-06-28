# MERN Image Gallery Todo Sample App

- Frontend: React, Bootstrap.
- Backend: Node.js, Express
- Database: Mongo (running locally for storing tasks)
- Object Storage: S3

## Project Structure

This project contains the following components:
- **/backend** - This directory contains the Node.js application that handles the server-side logic and interacts with the database. This directory contains configuration settings for uploading images to AWS S3. The uploadConfig.js file is responsible for configuring the S3 client to connect to the S3 endpoint. This allows the backend application to store and retrieve images associated with the image items.
- **/frontend** - The frontend directory contains the React application that handles the user interface and interacts with the backend. 

## How to run the App

### Pre-requisite
- Make sure that Docker is installed on your machine
- You have an AWS account and have acquired AWS Access key and Secret key
- You have created an AWS S3 bucket

## Starting up backend locally

1. Initialize NodeJS

```
cd backend/
npm install

```

2. Prepare the environment variables. Create an `.env` file. Please check `./backend/.env.sample` for the example

```
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
S3_BUCKET_NAME=mysamplebucket
MONGODB_URI=mongodb://mongodb:27017/todos
AWS_REGION=us-east-1
```

> [!IMPORTANT]  
> Make sure to change the environment variable values to your own AWS Credentials, Bucket name and MongoDB IP Address.

3. Start the backend server:


```
node index.js
```

You will see the message that the backend service has successfully started at port `5000`.

### Running via Docker

1. Build the image using the Dockerfile inside the **/backend** folder

```
docker buildx build -t mern-backend:latest .
```

2. Run the container.

```
docker run -p 5000:5000 -d mern-backend:latest
```

### To test backend API

You can use a simple curl command to test that backend is working.

```
curl http://localhost:5000/api/todos
```

Successful Sample Response:
```
[{"_id":"66e188403dc0b65d621ed93b","text":"test","__v":0},{"_id":"66e188443dc0b65d621ed93d","text":"test","__v":0},{"_id":"66e18e723dc0b65d621ed94b","text":"testasdfasdf","__v":0}]

or

[] # If no data has been saved
```

```
curl -o - -I http://localhost:5000/api/todos
```

Successful Sample Response:
```
HTTP/1.1 200 OK
X-Powered-By: Express
Access-Control-Allow-Origin: *
Content-Type: application/json; charset=utf-8
Content-Length: 180
ETag: W/"b4-Vp+SzbhhBnU4jDrGb4Kt5t1t06U"
Date: Thu, 12 Sep 2024 03:33:06 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

You can also use Postman for more details you can check here: 

[![Postman Api Testing Tutorial for beginners](https://img.youtube.com/vi/MFxk5BZulVU/0.jpg)](https://www.youtube.com/watch?v=MFxk5BZulVU)


## Start the frontend in development mode locally

Open a new terminal and run the following command:

```
cd frontend/
npm run dev
```

By now, you should see the following message

```
VITE v5.4.2  ready in 110 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help

```

### Running via Docker

1. Build the image using the Dockerfile inside the **/frontend** folder

```
docker buildx build -t mern-frontend:latest .
```

2. Run the container.

```
docker run -p 3000:3000 -d mern-frontend:latest
```

## Running the whole stack using Docker

```
docker compose -f compose.yml up -d --build
```

> [!NOTE]  
> Make sure to change and check `environment` on **frontend** and **backend** service. Frontend uses `VITE_BACKEND_ENDPOINT` and `VITE_SERVER_HOSTNAME`. 
>
> Keep `VITE_BACKEND_ENDPOINT` to the value of `localhost` even the backend is deployed as a service in docker compose. This is because frontend do not communicate internally when serving HTML files. Your local browser tries to find that endpoint from your local network instead of the frontend container trying to connect to the endpoint. Only change the endpoint when the backend is deployed in a different server.
>
> To use `VITE_SERVER_HOSTNAME` always run this command first `export VITE_SERVER_HOSTNAME=$(hostname)` in whatever environment you are deploying.

