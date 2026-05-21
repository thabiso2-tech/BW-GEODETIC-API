#!/bin/bash

# GitHub Secrets Setup Script
# This script helps you set up GitHub Secrets for the deployment pipeline

set -e

REPO_OWNER="${1}"
REPO_NAME="${2}"

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "Usage: $0 <REPO_OWNER> <REPO_NAME>"
    echo "Example: $0 myorg my-geodetic-suite"
    exit 1
fi

echo "GitHub Secrets Setup for $REPO_OWNER/$REPO_NAME"
echo "================================================"
echo ""

# Function to encode values
encode_base64() {
    if command -v base64 &> /dev/null; then
        echo -n "$1" | base64 -w 0
    else
        echo "Please install base64 utility"
        exit 1
    fi
}

# Collect user input
echo "Please provide the following information:"
echo ""

read -p "Docker Hub Username: " DOCKER_USERNAME
read -sp "Docker Hub Personal Access Token: " DOCKER_PASSWORD
echo ""
read -p "Staging Server Hostname/IP: " STAGING_HOST
read -p "Staging SSH User: " STAGING_USER
read -p "Production Server Hostname/IP: " PROD_HOST
read -p "Production SSH User: " PROD_USER

echo ""
echo "Setup SSH Keys..."
echo "===================="
echo "Ensure your public keys are in ~/.ssh/authorized_keys on both servers"
echo ""

read -p "Path to SSH private key (default: ~/.ssh/id_rsa): " SSH_KEY_PATH
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_rsa}"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "SSH key not found at $SSH_KEY_PATH"
    exit 1
fi

STAGING_SSH_KEY=$(cat "$SSH_KEY_PATH" | base64 -w 0)
PROD_SSH_KEY=$(cat "$SSH_KEY_PATH" | base64 -w 0)

echo ""
echo "Creating GitHub Secrets..."
echo "=========================="
echo ""
echo "Copy and paste these commands in your terminal to create secrets via GitHub CLI:"
echo ""

cat << EOF
# Install GitHub CLI if not present: https://cli.github.com

gh secret set DOCKER_USERNAME -b "$DOCKER_USERNAME" -R "$REPO_OWNER/$REPO_NAME"
gh secret set DOCKER_PASSWORD -b "$DOCKER_PASSWORD" -R "$REPO_OWNER/$REPO_NAME"
gh secret set STAGING_HOST -b "$STAGING_HOST" -R "$REPO_OWNER/$REPO_NAME"
gh secret set STAGING_USER -b "$STAGING_USER" -R "$REPO_OWNER/$REPO_NAME"
gh secret set STAGING_SSH_KEY -b "$STAGING_SSH_KEY" -R "$REPO_OWNER/$REPO_NAME"
gh secret set PROD_HOST -b "$PROD_HOST" -R "$REPO_OWNER/$REPO_NAME"
gh secret set PROD_USER -b "$PROD_USER" -R "$REPO_OWNER/$REPO_NAME"
gh secret set PROD_SSH_KEY -b "$PROD_SSH_KEY" -R "$REPO_OWNER/$REPO_NAME"
EOF

echo ""
echo ""
echo "Alternatively, manually add them via GitHub Web UI:"
echo "https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions/new"
echo ""
echo "✓ Setup script completed!"
