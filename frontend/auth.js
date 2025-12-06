// Authentication functions

const API_BASE_URL = (typeof CONFIG !== 'undefined' && CONFIG.API_BASE_URL) ? CONFIG.API_BASE_URL : '';

function switchTab(tab) {
    // Update tab buttons
    document.querySelectorAll('.tab-button').forEach(btn => btn.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
    
    if (tab === 'login') {
        document.querySelector('.tab-button:first-child').classList.add('active');
        document.getElementById('login-tab').classList.add('active');
    } else {
        document.querySelector('.tab-button:last-child').classList.add('active');
        document.getElementById('signup-tab').classList.add('active');
    }
}

function showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error';
    errorDiv.textContent = message;
    const container = document.querySelector('.login-container');
    container.insertBefore(errorDiv, container.firstChild);
    setTimeout(() => errorDiv.remove(), 5000);
}

function showSuccess(message) {
    const successDiv = document.createElement('div');
    successDiv.className = 'success';
    successDiv.textContent = message;
    const container = document.querySelector('.login-container');
    container.insertBefore(successDiv, container.firstChild);
    setTimeout(() => successDiv.remove(), 3000);
}

async function handleLogin(event) {
    event.preventDefault();
    const button = document.getElementById('login-button');
    button.disabled = true;
    button.textContent = 'Logging in...';

    const username = document.getElementById('login-username').value.trim().toLowerCase();
    const password = document.getElementById('login-password').value;

    try {
        const response = await fetch(`${API_BASE_URL}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ username, password })
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || 'Login failed');
        }

        // Store token and username
        localStorage.setItem('authToken', data.token);
        localStorage.setItem('username', data.username);

        showSuccess('Login successful! Redirecting...');
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 1000);

    } catch (error) {
        console.error('Login error:', error);
        showError(error.message || 'Login failed. Please check your credentials.');
        button.disabled = false;
        button.textContent = 'Login';
    }
}

async function handleSignup(event) {
    event.preventDefault();
    const button = document.getElementById('signup-button');
    button.disabled = true;
    button.textContent = 'Creating account...';

    const username = document.getElementById('signup-username').value.trim().toLowerCase();
    const password = document.getElementById('signup-password').value;

    try {
        const response = await fetch(`${API_BASE_URL}/auth/signup`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ username, password })
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || 'Signup failed');
        }

        // Store token and username
        localStorage.setItem('authToken', data.token);
        localStorage.setItem('username', data.username);

        showSuccess('Account created! Redirecting...');
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 1000);

    } catch (error) {
        console.error('Signup error:', error);
        showError(error.message || 'Signup failed. Please try again.');
        button.disabled = false;
        button.textContent = 'Create Account';
    }
}

// Check if already logged in
if (localStorage.getItem('authToken')) {
    window.location.href = 'index.html';
}

