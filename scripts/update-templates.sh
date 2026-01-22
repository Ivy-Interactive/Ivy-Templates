#!/usr/bin/env bash

set -e

# Configuration
PACKAGE_NAME="Ivy"
PACKAGE_NAME_LOWER=$(echo "$PACKAGE_NAME" | tr '[:upper:]' '[:lower:]')
NUGET_API="https://api.nuget.org/v3-flatcontainer"
TEMP_DIR="temp_nuget_extract"

echo "Fetching latest version of $PACKAGE_NAME from NuGet..."
LATEST_VERSION=$(curl -s "$NUGET_API/$PACKAGE_NAME_LOWER/index.json" | jq -r '.versions[-1]')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    echo "Error: Could not determine latest version of $PACKAGE_NAME"
    exit 1
fi

echo "Latest version is $LATEST_VERSION"

# Setup temp directory for extraction
mkdir -p "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Download and extract README.md and AGENTS.md
PACKAGE_URL="$NUGET_API/$PACKAGE_NAME_LOWER/$LATEST_VERSION/$PACKAGE_NAME_LOWER.$LATEST_VERSION.nupkg"
echo "Downloading $PACKAGE_URL..."
curl -L -s "$PACKAGE_URL" -o "$TEMP_DIR/package.nupkg"

unzip -o "$TEMP_DIR/package.nupkg" README.md AGENTS.md -d "$TEMP_DIR"

# Find all template projects (directories with .csproj)
PROJECTS=$(find . -maxdepth 2 -name "*.csproj")

UPDATED_ANY=false

# Determine sed command (portable -i)
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_CMD=("sed" "-i" "")
else
    SED_CMD=("sed" "-i")
fi

for PROJECT_PATH in $PROJECTS; do
    PROJECT_DIR=$(dirname "$PROJECT_PATH")
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    
    if [[ "$PROJECT_DIR" == . ]]; then continue; fi
    
    echo "Processing template: $PROJECT_DIR ($PROJECT_NAME)"
    
    # Update version in csproj
    "${SED_CMD[@]}" "s/PackageReference Include=\"Ivy\" Version=\"[^\"]*\"/PackageReference Include=\"Ivy\" Version=\"$LATEST_VERSION\"/" "$PROJECT_PATH"
    
    # Copy README.md and AGENTS.md
    if [ -f "$TEMP_DIR/README.md" ]; then
        cp "$TEMP_DIR/README.md" "$PROJECT_DIR/README.md"
    fi
    if [ -f "$TEMP_DIR/AGENTS.md" ]; then
        cp "$TEMP_DIR/AGENTS.md" "$PROJECT_DIR/AGENTS.md"
    fi
    
    # Verify build
    echo "Verifying build for $PROJECT_DIR..."
    # We use -p:IvyVersion to ensure it builds even if restore didn't pick up the change immediately
    if (cd "$PROJECT_DIR" && dotnet build); then
        echo "Build successful for $PROJECT_DIR."
        UPDATED_ANY=true
    else
        echo "Build failed for $PROJECT_DIR. Rolling back changes for this template."
        git checkout "$PROJECT_PATH"
        git checkout "$PROJECT_DIR/README.md" || true
        git checkout "$PROJECT_DIR/AGENTS.md" || true
    fi
done

if [ "$UPDATED_ANY" = true ]; then
    echo "Successfully updated templates to version $LATEST_VERSION"
else
    echo "No templates were updated successfully."
fi
