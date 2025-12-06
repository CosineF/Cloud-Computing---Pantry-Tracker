# API & Schema Documentation

## Base URL

```
https://{api-id}.execute-api.{region}.amazonaws.com/Prod
```

Example:
```
https://4avf297ep0.execute-api.us-west-2.amazonaws.com/Prod
```

## Authentication

All protected endpoints require JWT Bearer token authentication.

**Header Format**:
```
Authorization: Bearer <jwt-token>
```

**Token Acquisition**:
- Sign up: `POST /auth/signup` returns token
- Login: `POST /auth/login` returns token

**Token Expiration**: 7 days from issuance

---

## API Endpoints

### Authentication Endpoints

#### POST /auth/signup

Create a new user account.

**Request**:
```http
POST /auth/signup
Content-Type: application/json

{
  "username": "string (min 3 chars, lowercase)",
  "password": "string (min 6 chars)"
}
```

**Response** (201 Created):
```json
{
  "message": "User created successfully",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "username": "testuser"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid input (username too short, password too short)
- `409 Conflict`: Username already exists
- `500 Internal Server Error`: Server error

**Example**:
```bash
curl -X POST "https://API_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}'
```

---

#### POST /auth/login

Login with username and password.

**Request**:
```http
POST /auth/login
Content-Type: application/json

{
  "username": "string",
  "password": "string"
}
```

**Response** (200 OK):
```json
{
  "message": "Login successful",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "username": "testuser"
}
```

**Error Responses**:
- `400 Bad Request`: Missing username or password
- `401 Unauthorized`: Invalid username or password
- `500 Internal Server Error`: Server error

**Example**:
```bash
curl -X POST "https://API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}'
```

---

### Inventory Endpoints

All inventory endpoints require authentication.

#### GET /inventory

Get all inventory items for the authenticated user.

**Request**:
```http
GET /inventory
Authorization: Bearer <token>
```

**Response** (200 OK):
```json
{
  "householdId": "testuser",
  "items": [
    {
      "id": "testuser#abc12345",
      "name": "Milk",
      "quantity": 2,
      "createdAt": "2024-12-02T10:30:00.000000"
    },
    {
      "id": "testuser#def67890",
      "name": "Bread",
      "quantity": 1,
      "createdAt": "2024-12-02T11:15:00.000000"
    }
  ],
  "count": 2
}
```

**Empty Response** (200 OK):
```json
{
  "householdId": "testuser",
  "items": [],
  "count": 0
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing token
- `500 Internal Server Error`: Server error

**Example**:
```bash
curl -H "Authorization: Bearer $TOKEN" \
  "https://API_URL/inventory"
```

---

#### POST /inventory

Add a new item to the inventory.

**Request**:
```http
POST /inventory
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "string (required)",
  "quantity": "integer (min 1, default 1)"
}
```

**Response** (200 OK):
```json
{
  "message": "Item added successfully",
  "item": {
    "id": "testuser#abc12345",
    "name": "Milk",
    "quantity": 2
  }
}
```

**Error Responses**:
- `400 Bad Request`: Missing name or invalid quantity
- `401 Unauthorized`: Invalid or missing token
- `500 Internal Server Error`: Server error

**Example**:
```bash
curl -X POST "https://API_URL/inventory" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Milk","quantity":2}'
```

---

#### DELETE /inventory

Remove an item from the inventory.

**Request**:
```http
DELETE /inventory
Authorization: Bearer <token>
Content-Type: application/json

{
  "itemId": "string (required)"
}
```

**Response** (200 OK):
```json
{
  "message": "Item removed successfully",
  "itemId": "testuser#abc12345"
}
```

**Error Responses**:
- `400 Bad Request`: Missing itemId
- `401 Unauthorized`: Invalid or missing token
- `404 Not Found`: Item not found
- `500 Internal Server Error`: Server error

**Example**:
```bash
curl -X DELETE "https://API_URL/inventory" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"itemId":"testuser#abc12345"}'
```

---

## Data Schemas

### User Schema (DynamoDB: PantryUsers)

```json
{
  "username": "string (Partition Key)",
  "password": "string (SHA-256 hash)",
  "createdAt": "string (ISO 8601 timestamp)"
}
```

**Example**:
```json
{
  "username": "testuser",
  "password": "a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3",
  "createdAt": "2024-12-02T10:00:00.000000"
}
```

**Constraints**:
- `username`: 3-50 characters, lowercase, alphanumeric + underscore
- `password`: Stored as SHA-256 hash (64 hex characters)
- `createdAt`: ISO 8601 format timestamp

---

### Inventory Item Schema (DynamoDB: PantryInventory)

```json
{
  "householdId": "string (Partition Key, equals username)",
  "itemId": "string (Sort Key, format: {householdId}#{hash})",
  "name": "string",
  "quantity": "number (integer)",
  "createdAt": "string (ISO 8601 timestamp)"
}
```

**Example**:
```json
{
  "householdId": "testuser",
  "itemId": "testuser#abc12345",
  "name": "Milk",
  "quantity": 2,
  "createdAt": "2024-12-02T10:30:00.000000"
}
```

**Constraints**:
- `householdId`: Must match authenticated username
- `itemId`: Auto-generated, format: `{householdId}#{8-char-hash}`
- `name`: 1-100 characters, trimmed
- `quantity`: Positive integer, minimum 1
- `createdAt`: ISO 8601 format timestamp

---

### JWT Token Schema

**Header**:
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload**:
```json
{
  "username": "string",
  "exp": "number (Unix timestamp)",
  "iat": "number (Unix timestamp)"
}
```

**Example Payload**:
```json
{
  "username": "testuser",
  "exp": 1733184000,
  "iat": 1732579200
}
```

**Validation**:
- Signature verified using `JWT_SECRET`
- `exp` must be in the future
- `username` must exist in PantryUsers table

---

## Error Response Format

All error responses follow this format:

```json
{
  "message": "string (human-readable error message)",
  "error": "string (optional, detailed error for debugging)"
}
```

**HTTP Status Codes**:
- `200 OK`: Success
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request (validation error)
- `401 Unauthorized`: Authentication required or failed
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource already exists
- `500 Internal Server Error`: Server error

**Example Error Responses**:

```json
// 400 Bad Request
{
  "message": "Item name is required"
}

// 401 Unauthorized
{
  "message": "Unauthorized",
  "error": "Invalid or missing authentication token"
}

// 404 Not Found
{
  "message": "Item not found"
}

// 500 Internal Server Error
{
  "message": "Internal server error",
  "error": "Database connection failed"
}
```

---

## CORS

**Allowed Origins**: `*` (all origins)

**Allowed Headers**:
- `Content-Type`
- `Authorization`

**Allowed Methods**:
- `GET`
- `POST`
- `DELETE`
- `OPTIONS`

**Preflight Request**:
```http
OPTIONS /inventory
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type,Authorization
```

**Response**:
```http
200 OK
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET,POST,DELETE,OPTIONS
Access-Control-Allow-Headers: Content-Type,Authorization
```

---

## Rate Limiting

**Current Status**: Not implemented

**Planned**:
- Per-user rate limiting: 1000 requests/hour
- Per-IP rate limiting: 100 requests/minute
- Burst limit: 200 requests

**Response when rate limited**:
```http
429 Too Many Requests
{
  "message": "Rate limit exceeded",
  "retryAfter": 60
}
```

---

## Request/Response Examples

### Complete Authentication Flow

```bash
# 1. Sign up
SIGNUP_RESPONSE=$(curl -s -X POST "https://API_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}')

TOKEN=$(echo $SIGNUP_RESPONSE | jq -r '.token')
echo "Token: $TOKEN"

# 2. Get inventory (empty)
curl -H "Authorization: Bearer $TOKEN" \
  "https://API_URL/inventory"

# 3. Add item
curl -X POST "https://API_URL/inventory" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Milk","quantity":2}'

# 4. Get inventory (with item)
curl -H "Authorization: Bearer $TOKEN" \
  "https://API_URL/inventory"

# 5. Remove item
ITEM_ID="testuser#abc12345"
curl -X DELETE "https://API_URL/inventory" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"itemId\":\"$ITEM_ID\"}"
```

---

## Data Validation Rules

### Username
- **Type**: String
- **Length**: 3-50 characters
- **Format**: Lowercase, alphanumeric + underscore
- **Validation**: Server-side (Lambda)
- **Example**: `testuser`, `user_123`

### Password
- **Type**: String
- **Length**: Minimum 6 characters
- **Storage**: SHA-256 hash (64 hex characters)
- **Validation**: Server-side (Lambda)
- **Example**: `testpass123` → stored as hash

### Item Name
- **Type**: String
- **Length**: 1-100 characters
- **Format**: Trimmed, any characters
- **Validation**: Server-side (Lambda)
- **Example**: `Milk`, `Bread`, `Eggs (dozen)`

### Quantity
- **Type**: Integer
- **Range**: 1 to 2^31-1
- **Default**: 1
- **Validation**: Server-side (Lambda)
- **Example**: `1`, `2`, `10`

---

## API Versioning

**Current Version**: v1 (implicit)

**Versioning Strategy**: Not implemented (MVP)

**Future**: Add version prefix:
- `/v1/auth/signup`
- `/v1/inventory`

---

## Pagination

**Current Status**: Not implemented

**Planned**: For large inventories
```http
GET /inventory?limit=50&lastKey={itemId}
```

**Response**:
```json
{
  "items": [...],
  "count": 50,
  "lastKey": "testuser#xyz789",
  "hasMore": true
}
```

---

## Filtering & Sorting

**Current Status**: Not implemented

**Planned**:
- Filter by name: `GET /inventory?name=Milk`
- Sort by name: `GET /inventory?sort=name`
- Sort by quantity: `GET /inventory?sort=quantity&order=desc`

---

## Webhooks / Real-time Updates

**Current Status**: Not implemented

**Planned**: WebSocket or Server-Sent Events for real-time inventory updates

---

## API Documentation Tools

**Current**: This markdown document

**Future Options**:
- OpenAPI/Swagger specification
- Postman collection
- Interactive API documentation (Swagger UI)

---

## Testing the API

### Using curl

See examples above in each endpoint section.

### Using test-api.sh

```bash
./test-api.sh https://API_URL TOKEN
```

### Using Postman

1. Import collection (create from examples above)
2. Set environment variable: `API_URL`
3. Set environment variable: `TOKEN` (from login)
4. Run requests

---

## Schema Evolution

### Current Version (v1)

- User: `username`, `password`, `createdAt`
- Item: `householdId`, `itemId`, `name`, `quantity`, `createdAt`

### Future Additions

- User: `email`, `preferences`, `lastLogin`
- Item: `expiryDate`, `category`, `location`, `notes`

### Backward Compatibility

- New fields optional
- Old fields remain supported
- Version endpoint for client compatibility check

