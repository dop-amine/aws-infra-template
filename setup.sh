#!/bin/bash

# Check if Homebrew is installed
if ! command -v brew &> /dev/null
then
    echo "Homebrew not found, installing now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Update Homebrew
brew update

# Install AWS CLI
if ! command -v aws &> /dev/null
then
    echo "Installing AWS CLI..."
    brew install awscli
else
    echo "AWS CLI is already installed."
fi

# Install Terraform
if ! command -v terraform &> /dev/null
then
    echo "Installing terraform..."
    brew install terraform
else
    echo "terraform is already installed."
fi

# Final message
echo "Setup complete. All necessary dependencies are installed."
