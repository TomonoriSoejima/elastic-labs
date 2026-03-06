#!/bin/bash

# Load environment variables
export $(cat .env | xargs)

# Initialize Go module and download dependencies
go mod tidy

# Run the application
go run main.go
