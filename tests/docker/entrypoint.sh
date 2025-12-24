#!/bin/bash
set -e

echo "Starting Hardhat Node..."
npx hardhat node --hostname 0.0.0.0 &
NODE_PID=$!

echo "Waiting for Hardhat Node to start..."
sleep 5

echo "Deploying contracts..."
npx hardhat run scripts/deploy.js --network localhost

echo "Deployment complete!"

wait $NODE_PID
