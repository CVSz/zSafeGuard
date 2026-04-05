#!/bin/bash

echo "Deploying zSafeGuard..."

docker build -t zsafe-ai .
minikube start
kubectl apply -f k8s/
uvicorn ai.main:app --reload &
cd dashboard && npm install && npm start &
cloudflared tunnel --url http://localhost:8000
