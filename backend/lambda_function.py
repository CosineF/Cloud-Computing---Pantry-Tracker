import json
import boto3
import os
import hashlib
import jwt
from datetime import datetime, timedelta
from decimal import Decimal
from botocore.exceptions import ClientError

# Initialize DynamoDB clients
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'PantryInventory')
users_table_name = os.environ.get('USERS_TABLE_NAME', 'PantryUsers')
jwt_secret = os.environ.get('JWT_SECRET', '')

table = dynamodb.Table(table_name)
users_table = dynamodb.Table(users_table_name)

def decimal_default(obj):
    """Convert Decimal to int/float for JSON serialization"""
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError

def hash_password(password):
    """Hash password using SHA-256 (simple approach for MVP)"""
    return hashlib.sha256(password.encode()).hexdigest()

def verify_password(password, hashed):
    """Verify password against hash"""
    return hash_password(password) == hashed

def generate_token(username):
    """Generate JWT token for user"""
    if not jwt_secret:
        raise ValueError("JWT_SECRET not configured")
    
    payload = {
        'username': username,
        'exp': datetime.utcnow() + timedelta(days=7),  # Token expires in 7 days
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, jwt_secret, algorithm='HS256')

def verify_token(token):
    """Verify and decode JWT token"""
    if not jwt_secret:
        return None
    
    try:
        payload = jwt.decode(token, jwt_secret, algorithms=['HS256'])
        return payload.get('username')
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def get_username_from_event(event):
    """Extract username from Authorization header"""
    headers = event.get('headers', {}) or {}
    auth_header = headers.get('Authorization') or headers.get('authorization', '')
    
    if not auth_header.startswith('Bearer '):
        return None
    
    token = auth_header.replace('Bearer ', '')
    return verify_token(token)

def lambda_handler(event, context):
    """
    Handle API Gateway requests for pantry inventory management
    
    Routes:
    - POST /auth/signup - Create new user account
    - POST /auth/login - Login and get JWT token
    - GET /inventory?householdId=xxx - Get all items for a household (requires auth)
    - POST /inventory - Add a new item (requires auth)
    - DELETE /inventory - Remove an item (requires auth)
    """
    
    # Enable CORS
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS'
    }
    
    # Handle preflight OPTIONS request
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': ''
        }
    
    try:
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        
        # Public routes (no authentication required)
        if http_method == 'POST' and '/auth/signup' in path:
            return signup(event, headers)
        elif http_method == 'POST' and '/auth/login' in path:
            return login(event, headers)
        
        # Protected routes (require authentication)
        username = get_username_from_event(event)
        if not username:
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({
                    'message': 'Unauthorized',
                    'error': 'Invalid or missing authentication token'
                })
            }
        
        # Route to appropriate handler
        if http_method == 'GET' and '/inventory' in path:
            return get_inventory(event, headers, username)
        elif http_method == 'POST' and '/inventory' in path:
            return add_item(event, headers, username)
        elif http_method == 'DELETE' and '/inventory' in path:
            return remove_item(event, headers, username)
        else:
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'message': 'Not found'})
            }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'message': 'Internal server error',
                'error': str(e)
            })
        }

def signup(event, headers):
    """Create a new user account"""
    try:
        body = json.loads(event.get('body', '{}'))
        username = body.get('username', '').strip().lower()
        password = body.get('password', '')
        
        # Validation
        if not username or len(username) < 3:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'Username must be at least 3 characters'})
            }
        
        if not password or len(password) < 6:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'Password must be at least 6 characters'})
            }
        
        # Check if user already exists
        try:
            users_table.get_item(Key={'username': username})
            response = users_table.get_item(Key={'username': username})
            if 'Item' in response:
                return {
                    'statusCode': 409,
                    'headers': headers,
                    'body': json.dumps({'message': 'Username already exists'})
                }
        except ClientError:
            pass
        
        # Create user
        hashed_password = hash_password(password)
        users_table.put_item(Item={
            'username': username,
            'password': hashed_password,
            'createdAt': datetime.utcnow().isoformat()
        })
        
        # Generate token
        token = generate_token(username)
        
        return {
            'statusCode': 201,
            'headers': headers,
            'body': json.dumps({
                'message': 'User created successfully',
                'token': token,
                'username': username
            })
        }
    
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'message': 'Invalid JSON in request body'})
        }
    except Exception as e:
        print(f"Signup error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': 'Error creating user', 'error': str(e)})
        }

def login(event, headers):
    """Login user and return JWT token"""
    try:
        body = json.loads(event.get('body', '{}'))
        username = body.get('username', '').strip().lower()
        password = body.get('password', '')
        
        if not username or not password:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'Username and password are required'})
            }
        
        # Get user from database
        response = users_table.get_item(Key={'username': username})
        
        if 'Item' not in response:
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({'message': 'Invalid username or password'})
            }
        
        user = response['Item']
        stored_password = user.get('password', '')
        
        # Verify password
        if not verify_password(password, stored_password):
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({'message': 'Invalid username or password'})
            }
        
        # Generate token
        token = generate_token(username)
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': 'Login successful',
                'token': token,
                'username': username
            })
        }
    
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'message': 'Invalid JSON in request body'})
        }
    except Exception as e:
        print(f"Login error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': 'Error during login', 'error': str(e)})
        }

def get_inventory(event, headers, username):
    """Get all items for a household (using username as householdId)"""
    try:
        # Use username as householdId for simplicity
        household_id = username
        
        # Query DynamoDB for all items in this household
        response = table.query(
            KeyConditionExpression='householdId = :hid',
            ExpressionAttributeValues={
                ':hid': household_id
            }
        )
        
        items = response.get('Items', [])
        
        # Convert Decimal to int/float and normalize field names
        for item in items:
            if 'itemId' in item:
                item['id'] = item.pop('itemId')
            if 'quantity' in item:
                item['quantity'] = int(item['quantity'])
            if 'createdAt' in item:
                item['createdAt'] = str(item['createdAt'])
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'householdId': household_id,
                'items': items,
                'count': len(items)
            }, default=decimal_default)
        }
    
    except ClientError as e:
        print(f"DynamoDB error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': 'Database error', 'error': str(e)})
        }

def add_item(event, headers, username):
    """Add a new item to the inventory"""
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        # Use username as householdId
        household_id = username
        item_name = body.get('name', '').strip()
        quantity = body.get('quantity', 1)
        
        # Validation
        if not item_name:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'Item name is required'})
            }
        
        if not isinstance(quantity, int) or quantity < 1:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'Quantity must be a positive integer'})
            }
        
        # Generate item ID
        item_id = f"{household_id}#{hashlib.md5(f'{item_name}{datetime.now().isoformat()}'.encode()).hexdigest()[:8]}"
        
        # Create item record
        item = {
            'householdId': household_id,
            'itemId': item_id,
            'name': item_name,
            'quantity': quantity,
            'createdAt': datetime.utcnow().isoformat()
        }
        
        # Save to DynamoDB
        table.put_item(Item=item)
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': 'Item added successfully',
                'item': {
                    'id': item_id,
                    'name': item_name,
                    'quantity': quantity
                }
            })
        }
    
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'message': 'Invalid JSON in request body'})
        }
    except ClientError as e:
        print(f"DynamoDB error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': 'Database error', 'error': str(e)})
        }

def remove_item(event, headers, username):
    """Remove an item from the inventory"""
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        household_id = username  # Use username as householdId
        item_id = body.get('itemId')
        
        # Validation
        if not item_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'itemId is required'})
            }
        
        # Delete item from DynamoDB
        response = table.delete_item(
            Key={
                'householdId': household_id,
                'itemId': item_id
            },
            ReturnValues='ALL_OLD'
        )
        
        # Check if item existed
        if 'Attributes' not in response:
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'message': 'Item not found'})
            }
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': 'Item removed successfully',
                'itemId': item_id
            })
        }
    
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'message': 'Invalid JSON in request body'})
        }
    except ClientError as e:
        print(f"DynamoDB error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': 'Database error', 'error': str(e)})
        }
