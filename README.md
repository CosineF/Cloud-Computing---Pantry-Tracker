# Cloud Pantry Tracker MVP

A simple, serverless inventory management application for households to track shared pantry items in real time.

## Architecture

```
[ Web App (JS) ]
        |
        v
[ API Gateway ]
        |
        v
[ Lambda Function ]
        |
        v
[ DynamoDB Table ]
```

## Features

- Add items to shared household inventory
- View current inventory for a household
- Remove items from inventory
- Simple, clean web interface
- Serverless architecture (low cost, scalable)

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- AWS SAM CLI installed ([Installation Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html))
- Python 3.11 (for local testing)

## Project Structure

```
.
├── backend/                  # Lambda function code
│   ├── lambda_function.py
│   └── requirements.txt
├── docs/                     # All project docs and guides (this folder)
│   ├── README.md
│   ├── TESTING.md
│   └── ... other guides
├── events/                   # Sample events for local SAM testing
├── frontend/                 # Web application (HTML/CSS/JS)
│   ├── app.js
│   ├── auth.js
│   └── config.js
├── template.yaml             # AWS SAM template
└── configure-aws.sh          # Helper script
```

## Deployment Instructions

1) Install AWS SAM CLI
```bash
# macOS
brew install aws-sam-cli
# Or follow official guide: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
```

2) Build the application
```bash
sam build
```

3) Deploy to AWS
```bash
sam deploy --guided
```
The `--guided` flag will prompt you for:
- Stack name: `pantry-tracker` (or your preferred name)
- AWS Region: `us-west-2` (or your preferred region)
- **JwtSecret**: Enter a secure JWT secret (e.g., `openssl rand -hex 32`)
  - This is used to sign JWT tokens for user authentication
  - Save this securely (you'll need it if you rotate secrets)
- **AlertEmail** (optional): Email for CloudWatch alarms
- **PagerDutyIntegrationKey** (optional): PagerDuty integration key
- Confirm changes before deploy: `Y`
- Allow SAM CLI IAM role creation: `Y`
- Disable rollback: `N`
- Save arguments to configuration file: `Y`

**Note:** The JWT secret is used to sign authentication tokens. Keep it secret and don't commit it to version control.

4) Get the API Gateway URL
```bash
aws cloudformation describe-stacks \
  --stack-name pantry-tracker \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text
```

5) Update frontend configuration
1. Copy the example config file:
   ```bash
   cp frontend/config.example.js frontend/config.js
   ```
2. Edit `frontend/config.js` and replace `YOUR_API_GATEWAY_URL` and `YOUR_REGION` with your actual API Gateway URL:
   ```javascript
   const CONFIG = {
       API_BASE_URL: 'https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/Prod'
   };
   ```
   **Note:** No API key needed! The system uses JWT tokens for authentication. Users sign up/login through the web interface.

See `docs/README-CONFIG.md` for detailed configuration instructions.

6) Serve the frontend
- Option A (local HTTP server for testing):
```bash
cd frontend
python3 -m http.server 8000
# Open http://localhost:8000 in your browser
```
- Option B (S3 + CloudFront production):
```bash
aws s3 mb s3://your-pantry-tracker-frontend
aws s3 sync frontend/ s3://your-pantry-tracker-frontend --acl public-read
aws s3 website s3://your-pantry-tracker-frontend --index-document index.html
```
- Option C: Any static hosting service (Netlify, Vercel, GitHub Pages, etc.)

## Usage

1. Open the web application in your browser (start with `frontend/login.html`)
2. Sign up for a new account or log in with existing credentials
3. After login, you'll be redirected to the main inventory page
4. Your inventory is automatically loaded (no need to enter household ID - it's derived from your username)
5. Add items by entering name and quantity, then clicking "Add Item"
6. Remove items by clicking the "Remove" button

## API Endpoints

**Authentication:** All inventory endpoints require a JWT token in the `Authorization: Bearer <token>` header. Users obtain tokens by signing up or logging in.

### POST /auth/signup
Create a new user account.
- Body:
```json
{
  "username": "alice",
  "password": "secure-password"
}
```
- Response: `{ "token": "eyJ0eXAiOiJKV1QiLCJhbGc..." }`

### POST /auth/login
Login and get JWT token.
- Body:
```json
{
  "username": "alice",
  "password": "secure-password"
}
```
- Response: `{ "token": "eyJ0eXAiOiJKV1QiLCJhbGc..." }`

### GET /inventory
Fetch all items for the authenticated user's household.
- Headers: `Authorization: Bearer <token>` (required)
- Note: `householdId` is automatically derived from the JWT token (username)
- Example:
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  "https://YOUR_API_URL/inventory"
```

### POST /inventory
Add a new item to the inventory.
- Headers: `Authorization: Bearer <token>` (required)
- Body:
```json
{
  "name": "Bread",
  "quantity": 1
}
```
- Note: `householdId` is automatically derived from the JWT token

### DELETE /inventory
Remove an item from the inventory.
- Headers: `Authorization: Bearer <token>` (required)
- Body:
```json
{
  "itemId": "alice#abc12345"
}
```

For complete API documentation, see `docs/API-SCHEMA.md`.

## DynamoDB Schema

- **Table: `PantryInventory`**
  - Primary Key: `householdId` (partition), `itemId` (sort)
  - Attributes: `name` (String), `quantity` (Number), `createdAt` (String ISO timestamp)

- **Table: `PantryUsers`**
  - Primary Key: `username` (partition)
  - Attributes: `password` (String, hashed), `createdAt` (String ISO timestamp)

For complete schema documentation, see `docs/API-SCHEMA.md`.

## Cost Estimation

With the simplified architecture (no S3, Cognito, or Rekognition):
- API Gateway: Free tier includes 1M requests/month
- Lambda: Free tier includes 1M requests/month and 400,000 GB-seconds
- DynamoDB: Free tier includes 25GB storage and 25 read/write units

Estimated monthly cost for MVP: < $5 (likely $0 within free tier limits).

## Smoke Test (Quick Deployment Verification)

After deployment, run a quick smoke test to verify everything works:

```bash
./smoke-test.sh https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/Prod
```

This will test:
- User signup
- User login
- Get inventory (empty)
- Add item
- Get inventory (with item)

Expected output: All tests should pass ✅

## Local Testing

Test Lambda function locally:
```bash
sam build
sam local invoke PantryInventoryFunction --event events/get-inventory-event.json
```

Sample events:
```json
{
  "httpMethod": "GET",
  "path": "/inventory",
  "queryStringParameters": { "householdId": "household-1" }
}
```
```json
{
  "httpMethod": "POST",
  "path": "/inventory",
  "body": "{\"householdId\":\"household-1\",\"name\":\"Milk\",\"quantity\":2}"
}
```

## Troubleshooting

- **CORS Issues:** Ensure the Lambda function includes CORS headers (already included).
- **API Gateway Not Found:** Verify `frontend/app.js` uses the API URL output from `sam deploy`.
- **DynamoDB Access Denied:** Confirm the Lambda execution role can read/write the table (handled by SAM template).

## Cleanup

Remove all AWS resources:
```bash
sam delete --stack-name pantry-tracker
```

## Future Enhancements

- Image upload and AI recognition (S3 + Rekognition)
- Expiry date tracking
- Shopping list generation
- Multi-household user management
- Mobile app
- Rate limiting and enhanced security
- Accessibility improvements (ARIA, keyboard navigation)

## License

This project is part of a capstone project for UBC CPSC 436C.
