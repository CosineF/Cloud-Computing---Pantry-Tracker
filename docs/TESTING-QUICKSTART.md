# Quick Testing Guide

## Option 1: Test Frontend with Mock Data (No Backend Needed) ⚡

This is the **fastest way** to test the UI without installing anything:

```bash
cd frontend
python3 -m http.server 8000
```

Then open `http://localhost:8000/index-mock.html` in your browser.

**Note:** This uses `app-mock.js` which simulates API calls. Data is stored in memory and will reset when you refresh the page.

---

## Option 2: Install SAM CLI and Test Locally

### Fix Homebrew Permissions (if needed)

If you got permission errors, run:

```bash
sudo chown -R $(whoami) /usr/local/opt /usr/local/share/doc /usr/local/share/man /usr/local/share/man/man1
```

Then try installing again:

```bash
brew install aws-sam-cli
```

### Alternative: Install SAM CLI Manually

1. Download from: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
2. Or use the installer script:
   ```bash
   curl -L https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-macos-arm64.zip -o aws-sam-cli.zip
   unzip aws-sam-cli.zip -d sam-install
   sudo ./sam-install/install
   ```

### Test with SAM CLI

Once SAM CLI is installed:

```bash
# Build
sam build

# Start local API (requires Docker to be running)
sam local start-api
```

In another terminal:
```bash
# Update frontend/app.js line 2 to:
# const API_BASE_URL = 'http://127.0.0.1:3000';

cd frontend
python3 -m http.server 8000
```

Open `http://localhost:8000` in your browser.

---

## Option 3: Deploy to AWS and Test

If you have AWS CLI configured:

```bash
# Build
sam build

# Deploy (will prompt for configuration)
sam deploy --guided
```

After deployment, update `frontend/app.js` with your API Gateway URL and serve the frontend.

---

## Option 4: Test API with curl (After Deployment)

Once you have an API URL:

```bash
# Get inventory
curl "https://YOUR_API_URL/inventory?householdId=test-1"

# Add item
curl -X POST "https://YOUR_API_URL/inventory" \
  -H "Content-Type: application/json" \
  -d '{"householdId":"test-1","name":"Milk","quantity":2}'

# Remove item
curl -X DELETE "https://YOUR_API_URL/inventory" \
  -H "Content-Type: application/json" \
  -d '{"householdId":"test-1","itemId":"ITEM_ID_HERE"}'
```

---

## Recommended: Start with Option 1

The mock version lets you test the UI immediately without any setup. Then move to Option 2 or 3 when you're ready to test the full stack.

