# Authentication System Update

## What Changed

The application now uses **username/password authentication** instead of a single API key. Each user has their own account and can only access their own inventory.

## New Features

1. **User Signup**: Users can create accounts with username and password
2. **User Login**: Users authenticate with their credentials
3. **JWT Tokens**: Secure token-based authentication (tokens expire after 7 days)
4. **User Isolation**: Each user only sees their own inventory (username = householdId)
5. **Password Hashing**: Passwords are hashed using SHA-256 before storage

## Deployment Steps

### 1. Generate JWT Secret

```bash
openssl rand -hex 32
```

Save this value - you'll need it for deployment.

### 2. Deploy Updated Stack

```bash
sam build
sam deploy --guided
```

When prompted:
- **JwtSecret**: Enter the secret you generated above
- **Stack Name**: Use the same name as before (e.g., `CloudPantryTracker`)
- Answer other prompts as before

### 3. Update Frontend Config

Update `frontend/config.js`:
```javascript
const CONFIG = {
    API_BASE_URL: 'https://YOUR_API_URL.execute-api.us-west-2.amazonaws.com/Prod'
    // No API_KEY needed anymore!
};
```

### 4. Test the Application

1. Open `frontend/login.html` in your browser
2. Click "Sign Up" to create a new account
3. After signup, you'll be redirected to the main app
4. Your inventory is automatically loaded (no need to enter household ID)

## API Changes

### New Endpoints

- `POST /auth/signup` - Create new user account
- `POST /auth/login` - Login and get JWT token

### Updated Endpoints

All inventory endpoints now require authentication:
- `GET /inventory` - Requires `Authorization: Bearer <token>` header
- `POST /inventory` - Requires `Authorization: Bearer <token>` header
- `DELETE /inventory` - Requires `Authorization: Bearer <token>` header

### Removed

- API Key authentication (no longer needed)
- `X-API-Key` header (replaced with `Authorization: Bearer <token>`)

## Database Changes

### New Table: `PantryUsers`

Stores user accounts:
- `username` (Primary Key)
- `password` (hashed)
- `createdAt` (timestamp)

### Inventory Table

Still uses `householdId`, but now `householdId` = `username` for each user.

## Security Improvements

1. ✅ **Individual Accounts**: Each user has their own credentials
2. ✅ **Password Hashing**: Passwords are never stored in plain text
3. ✅ **JWT Tokens**: Secure, time-limited authentication tokens
4. ✅ **User Isolation**: Users can only access their own data
5. ✅ **Token Expiration**: Tokens expire after 7 days (users must re-login)

## Frontend Changes

### New Files

- `frontend/login.html` - Login/signup page
- `frontend/auth.js` - Authentication logic

### Updated Files

- `frontend/app.js` - Now uses JWT tokens instead of API key
- `frontend/index.html` - Removed household ID input (uses username)
- `frontend/config.example.js` - Removed API_KEY (no longer needed)

### User Flow

1. User visits app → Redirected to `login.html` if not logged in
2. User signs up or logs in → Receives JWT token
3. Token stored in `localStorage`
4. All API requests include `Authorization: Bearer <token>` header
5. If token expires → User redirected to login page

## Testing

### Test Signup

```bash
curl -X POST "https://YOUR_API_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}'
```

### Test Login

```bash
curl -X POST "https://YOUR_API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}'
```

### Test Inventory (with token)

```bash
TOKEN="your-jwt-token-here"
curl -H "Authorization: Bearer $TOKEN" \
  "https://YOUR_API_URL/inventory"
```

## Migration Notes

- **Existing Data**: If you had inventory data with the old system, it won't be accessible with the new authentication
- **API Key**: The old API key system is completely removed
- **Household IDs**: Now automatically set to the username

## Troubleshooting

**"Unauthorized" errors:**
- Make sure you're logged in (check `localStorage` for `authToken`)
- Token may have expired (7 days) - re-login
- Check that JWT_SECRET is set in Lambda environment variables

**Can't sign up:**
- Username must be at least 3 characters
- Password must be at least 6 characters
- Username must be unique

**Can't login:**
- Check username/password are correct
- Make sure user exists (try signup first)

