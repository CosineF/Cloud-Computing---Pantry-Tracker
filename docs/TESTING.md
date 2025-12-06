# Testing Guide

This guide covers different ways to test the Cloud Pantry Tracker MVP.

## Table of Contents

1. [Local Lambda Testing](#local-lambda-testing)
2. [Frontend Testing](#frontend-testing)
3. [End-to-End Testing](#end-to-end-testing)
4. [API Testing with curl](#api-testing-with-curl)
5. [Browser Testing](#browser-testing)

---

## Local Lambda Testing

Test the Lambda function locally before deploying to AWS.

### Prerequisites

```bash
# Install AWS SAM CLI (if not already installed)
brew install aws-sam-cli  # macOS
# or follow: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

# Install Docker (required for local Lambda testing)
# Download from: https://www.docker.com/products/docker-desktop
```

### Step 1: Build the Application

```bash
cd /Users/kexinfeng/Documents/UBC/大四/436C/jwu100-kfeng11-capstone
sam build
```

### Step 2: Start Local API (Recommended)

This starts a local API Gateway that mimics the real one:

```bash
sam local start-api
```

You should see output like:
```
Mounting PantryInventoryFunction at http://127.0.0.1:3000/inventory [GET, POST, DELETE, OPTIONS]
...
```

### Step 3: Test Individual Functions

Alternatively, test individual Lambda invocations:

#### Test GET Inventory

```bash
sam local invoke PantryInventoryFunction \
  --event events/get-inventory-event.json
```

#### Test Add Item

```bash
sam local invoke PantryInventoryFunction \
  --event events/add-item-event.json
```

#### Test Remove Item

```bash
sam local invoke PantryInventoryFunction \
  --event events/remove-item-event.json
```

---

## Frontend Testing

### Option 1: Test with Local Lambda API

1. **Start the local API** (from previous section):
   ```bash
   sam local start-api
   ```

2. **Update frontend configuration**:
   Open `frontend/app.js` and temporarily change:
   ```javascript
   const API_BASE_URL = 'http://127.0.0.1:3000';
   ```

3. **Serve the frontend**:
   ```bash
   cd frontend
   python3 -m http.server 8000
   ```

4. **Open in browser**:
   Navigate to `http://localhost:8000`

5. **Test the application**:
   - Enter a household ID (e.g., `test-household`)
   - Click "Load Inventory" (should show empty)
   - Add some items
   - Verify items appear
   - Remove items and verify they disappear

### Option 2: Test with Mock Data (No Backend)

For quick UI testing without any backend:

1. **Create a mock version** of `app.js`:
   ```javascript
   // Mock data
   const mockItems = [
     { id: '1', name: 'Milk', quantity: 2 },
     { id: '2', name: 'Bread', quantity: 1 }
   ];

   function loadInventory() {
     displayInventory(mockItems);
   }

   function addItem() {
     const name = document.getElementById('itemName').value;
     const quantity = parseInt(document.getElementById('itemQuantity').value);
     mockItems.push({ id: Date.now().toString(), name, quantity });
     displayInventory(mockItems);
     document.getElementById('itemName').value = '';
   }

   function removeItem(itemId) {
     const index = mockItems.findIndex(item => item.id === itemId);
     if (index > -1) mockItems.splice(index, 1);
     displayInventory(mockItems);
   }
   ```

---

## End-to-End Testing

### Deploy to AWS First

```bash
sam build
sam deploy --guided
```

After deployment, note the API Gateway URL from the output.

### Update Frontend Configuration

1. Open `frontend/app.js`
2. Replace the API URL:
   ```javascript
   const API_BASE_URL = 'https://YOUR_API_ID.execute-api.YOUR_REGION.amazonaws.com/Prod';
   ```

### Serve Frontend

```bash
cd frontend
python3 -m http.server 8000
```

Open `http://localhost:8000` in your browser.

---

## API Testing with curl

Test the API directly using curl commands.

### Prerequisites

Replace `YOUR_API_URL` with your actual API Gateway URL.

### Test GET Inventory

```bash
curl "https://YOUR_API_URL/inventory?householdId=test-household-1"
```

**Expected Response:**
```json
{
  "householdId": "test-household-1",
  "items": [],
  "count": 0
}
```

### Test Add Item

```bash
curl -X POST "https://YOUR_API_URL/inventory" \
  -H "Content-Type: application/json" \
  -d '{
    "householdId": "test-household-1",
    "name": "Milk",
    "quantity": 2
  }'
```

**Expected Response:**
```json
{
  "message": "Item added successfully",
  "item": {
    "id": "test-household-1#abc12345",
    "name": "Milk",
    "quantity": 2
  }
}
```

### Test Get Inventory Again (should show the item)

```bash
curl "https://YOUR_API_URL/inventory?householdId=test-household-1"
```

### Test Remove Item

First, get the itemId from the previous response, then:

```bash
curl -X DELETE "https://YOUR_API_URL/inventory" \
  -H "Content-Type: application/json" \
  -d '{
    "householdId": "test-household-1",
    "itemId": "test-household-1#abc12345"
  }'
```

### Test Error Cases

#### Missing householdId (GET)
```bash
curl "https://YOUR_API_URL/inventory"
# Should return 400 error
```

#### Missing householdId (POST)
```bash
curl -X POST "https://YOUR_API_URL/inventory" \
  -H "Content-Type: application/json" \
  -d '{"name": "Bread", "quantity": 1}'
# Should return 400 error
```

#### Invalid quantity
```bash
curl -X POST "https://YOUR_API_URL/inventory" \
  -H "Content-Type: application/json" \
  -d '{
    "householdId": "test-household-1",
    "name": "Bread",
    "quantity": -1
  }'
# Should return 400 error
```

---

## Browser Testing

### Manual Test Checklist

1. **Initial Load**
   - [ ] Page loads without errors
   - [ ] Household ID input is visible
   - [ ] "Load Inventory" button works
   - [ ] Empty state message shows when no items

2. **Add Items**
   - [ ] Can add item with name and quantity
   - [ ] Item appears in inventory list immediately
   - [ ] Form clears after adding
   - [ ] Multiple items can be added
   - [ ] Items persist after page refresh (if using real API)

3. **Remove Items**
   - [ ] Remove button appears for each item
   - [ ] Confirmation dialog appears
   - [ ] Item is removed after confirmation
   - [ ] Item disappears from list immediately

4. **Error Handling**
   - [ ] Error messages display for invalid inputs
   - [ ] Network errors show user-friendly messages
   - [ ] Empty household ID shows error

5. **UI/UX**
   - [ ] Responsive design works on mobile
   - [ ] Buttons are clickable and responsive
   - [ ] Loading states appear during API calls
   - [ ] Success messages appear after actions

### Browser Developer Tools Testing

1. **Open Developer Console** (F12 or Cmd+Option+I)
2. **Check for Errors**: Look for any JavaScript errors
3. **Network Tab**: 
   - Monitor API requests
   - Check request/response payloads
   - Verify CORS headers are present
4. **Application Tab**: 
   - Check if any data is stored locally
   - Verify no sensitive data in localStorage

---

## Automated Testing Script

Create a simple test script to automate API testing:

### Create `test-api.sh`

```bash
#!/bin/bash

API_URL="${1:-http://127.0.0.1:3000}"
HOUSEHOLD_ID="test-household-$(date +%s)"

echo "Testing API at: $API_URL"
echo "Using household ID: $HOUSEHOLD_ID"
echo ""

# Test 1: Get empty inventory
echo "Test 1: Get empty inventory"
curl -s "$API_URL/inventory?householdId=$HOUSEHOLD_ID" | jq .
echo ""

# Test 2: Add item
echo "Test 2: Add item"
ADD_RESPONSE=$(curl -s -X POST "$API_URL/inventory" \
  -H "Content-Type: application/json" \
  -d "{\"householdId\":\"$HOUSEHOLD_ID\",\"name\":\"Milk\",\"quantity\":2}")
echo "$ADD_RESPONSE" | jq .
ITEM_ID=$(echo "$ADD_RESPONSE" | jq -r '.item.id')
echo ""

# Test 3: Get inventory (should have item)
echo "Test 3: Get inventory (should have item)"
curl -s "$API_URL/inventory?householdId=$HOUSEHOLD_ID" | jq .
echo ""

# Test 4: Remove item
echo "Test 4: Remove item"
curl -s -X DELETE "$API_URL/inventory" \
  -H "Content-Type: application/json" \
  -d "{\"householdId\":\"$HOUSEHOLD_ID\",\"itemId\":\"$ITEM_ID\"}" | jq .
echo ""

# Test 5: Get inventory (should be empty again)
echo "Test 5: Get inventory (should be empty again)"
curl -s "$API_URL/inventory?householdId=$HOUSEHOLD_ID" | jq .
echo ""

echo "All tests completed!"
```

**Usage:**
```bash
chmod +x test-api.sh

# Test local API
./test-api.sh

# Test deployed API
./test-api.sh https://YOUR_API_ID.execute-api.ca-central-1.amazonaws.com/Prod
```

---

## Quick Test Workflow

### Fastest Way to Test Everything:

1. **Start local API**:
   ```bash
   sam local start-api
   ```

2. **In another terminal, update and serve frontend**:
   ```bash
   # Edit frontend/app.js: change API_BASE_URL to 'http://127.0.0.1:3000'
   cd frontend
   python3 -m http.server 8000
   ```

3. **Open browser**: `http://localhost:8000`

4. **Test manually**:
   - Add a few items
   - Remove items
   - Refresh page and verify items persist (if using real DynamoDB)

5. **Check logs**: Watch the terminal running `sam local start-api` for Lambda execution logs

---

## Troubleshooting Tests

### Lambda function not found
- Make sure you ran `sam build` first
- Check that function name in `template.yaml` matches

### CORS errors in browser
- Verify CORS headers are in Lambda response
- Check browser console for specific CORS error messages

### DynamoDB errors
- For local testing, SAM uses DynamoDB Local (if configured)
- For deployed testing, check IAM permissions
- Verify table name matches in environment variables

### API Gateway 404
- Check the path matches exactly: `/inventory`
- Verify HTTP method (GET, POST, DELETE)
- Check SAM template event configuration

---

## Next Steps

After testing locally:
1. Deploy to AWS: `sam deploy --guided`
2. Update frontend API URL
3. Test with real AWS resources
4. Monitor CloudWatch logs for errors
5. Check DynamoDB console to verify data

