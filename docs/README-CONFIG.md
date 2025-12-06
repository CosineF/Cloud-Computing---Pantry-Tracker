# Configuration Setup

## Quick Start

1. **Copy the example config file:**
   ```bash
   cp frontend/config.example.js frontend/config.js
   ```

2. **Edit `frontend/config.js`** and fill in your values:
   ```javascript
   const CONFIG = {
       API_BASE_URL: 'https://your-api-url.execute-api.us-west-2.amazonaws.com/Prod'
   };
   ```
   **Note:** No API key needed! The system uses JWT tokens for authentication.

3. **Done!** The app will now load your configuration.

## Security Notes

- ✅ `config.js` is in `.gitignore` and won't be committed to version control
- ✅ `config.example.js` is a template without real credentials
- ✅ No API keys needed - authentication uses JWT tokens obtained through login

## Getting Your API Values

### API Base URL
After deploying with `sam deploy`, you'll see the API Gateway URL in the output:
```
Key                 ApiGatewayUrl
Value               https://xxxxx.execute-api.us-west-2.amazonaws.com/Prod
```

### Authentication
The system uses JWT tokens for authentication. Users sign up and log in through the web interface (`frontend/login.html`), and tokens are automatically stored in the browser's localStorage. No API key configuration needed!

## Troubleshooting

**Error: "Configuration missing!"**
- Make sure `frontend/config.js` exists
- Check that it defines `CONFIG` object with `API_BASE_URL`

**Error: "Unauthorized"**
- Make sure you're logged in (check `frontend/login.html`)
- Verify your JWT token is valid (tokens expire after 7 days)
- Check that the API Base URL is correct
- Try logging out and logging back in

