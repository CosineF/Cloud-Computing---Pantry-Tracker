// Configuration is loaded from config.js
const API_BASE_URL = (typeof CONFIG !== 'undefined' && CONFIG.API_BASE_URL) ? CONFIG.API_BASE_URL : '';

// Check if configuration is loaded
if (!API_BASE_URL) {
    console.error('Configuration missing! Please create frontend/config.js from config.example.js');
    document.addEventListener('DOMContentLoaded', () => {
        const container = document.querySelector('.container');
        if (container) {
            const errorDiv = document.createElement('div');
            errorDiv.className = 'error';
            errorDiv.innerHTML = '<strong>Configuration Error:</strong> Please create <code>frontend/config.js</code> from <code>config.example.js</code> and fill in your API URL.';
            container.insertBefore(errorDiv, container.firstChild);
        }
    });
}

// Get auth token from localStorage
function getAuthToken() {
    return localStorage.getItem('authToken');
}

function getUsername() {
    return localStorage.getItem('username');
}

// Check authentication on page load
document.addEventListener('DOMContentLoaded', () => {
    const token = getAuthToken();
    const username = getUsername();
    
    if (!token || !username) {
        window.location.href = 'login.html';
        return;
    }
    
    // Display username and logout button
    const header = document.querySelector('header');
    if (header) {
        const userInfo = document.createElement('div');
        userInfo.style.cssText = 'text-align: right; margin-top: 10px;';
        userInfo.innerHTML = `
            <span style="color: #666;">Logged in as: <strong>${escapeHtml(username)}</strong></span>
            <button onclick="logout()" style="margin-left: 15px; padding: 6px 12px; background: #dc3545; color: white; border: none; border-radius: 4px; cursor: pointer;">Logout</button>
        `;
        header.appendChild(userInfo);
    }
    
    // Remove household ID input (using username instead)
    const householdSelector = document.querySelector('.household-selector');
    if (householdSelector) {
        householdSelector.style.display = 'none';
    }
    
    // Load inventory automatically
    loadInventory();
});

function logout() {
    localStorage.removeItem('authToken');
    localStorage.removeItem('username');
    window.location.href = 'login.html';
}

// Get inventory for the logged-in user
async function loadInventory() {
    const inventoryList = document.getElementById('inventoryList');
    inventoryList.innerHTML = '<p class="loading">Loading inventory...</p>';

    const token = getAuthToken();
    if (!token) {
        window.location.href = 'login.html';
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/inventory`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            }
        });

        if (!response.ok) {
            if (response.status === 401) {
                // Token expired or invalid
                logout();
                return;
            }
            throw new Error(`Failed to load inventory: ${response.statusText}`);
        }

        const data = await response.json();
        displayInventory(data.items || []);
    } catch (error) {
        console.error('Error loading inventory:', error);
        inventoryList.innerHTML = `<p class="error">Error loading inventory: ${error.message}</p>`;
    }
}

// Display inventory items
function displayInventory(items) {
    const inventoryList = document.getElementById('inventoryList');
    
    if (items.length === 0) {
        inventoryList.innerHTML = '<p class="empty-state">No items yet. Add your first item above!</p>';
        return;
    }

    inventoryList.innerHTML = items.map(item => `
        <div class="inventory-item">
            <div class="item-info">
                <span class="item-name">${escapeHtml(item.name)}</span>
                <span class="item-quantity">Qty: ${item.quantity}</span>
            </div>
            <div class="item-actions">
                <button class="btn-remove" onclick="removeItem('${escapeHtml(item.id)}', '${escapeHtml(item.name)}')">
                    Remove
                </button>
            </div>
        </div>
    `).join('');
}

// Add a new item
async function addItem() {
    const itemName = document.getElementById('itemName').value.trim();
    const itemQuantity = parseInt(document.getElementById('itemQuantity').value) || 1;

    if (!itemName) {
        showError('Please enter an item name');
        return;
    }

    if (itemQuantity < 1) {
        showError('Quantity must be at least 1');
        return;
    }

    const token = getAuthToken();
    if (!token) {
        window.location.href = 'login.html';
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/inventory`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                name: itemName,
                quantity: itemQuantity
            })
        });

        if (!response.ok) {
            if (response.status === 401) {
                logout();
                return;
            }
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to add item: ${response.statusText}`);
        }

        const data = await response.json();
        showSuccess(`Added ${itemName} (${itemQuantity}) successfully!`);
        
        // Clear form
        document.getElementById('itemName').value = '';
        document.getElementById('itemQuantity').value = '1';
        
        // Reload inventory
        await loadInventory();
    } catch (error) {
        console.error('Error adding item:', error);
        showError(`Error adding item: ${error.message}`);
    }
}

// Remove an item
async function removeItem(itemId, itemName) {
    if (!confirm(`Are you sure you want to remove ${itemName}?`)) {
        return;
    }

    const token = getAuthToken();
    if (!token) {
        window.location.href = 'login.html';
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/inventory`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                itemId: itemId
            })
        });

        if (!response.ok) {
            if (response.status === 401) {
                logout();
                return;
            }
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to remove item: ${response.statusText}`);
        }

        showSuccess(`Removed ${itemName} successfully!`);
        
        // Reload inventory
        await loadInventory();
    } catch (error) {
        console.error('Error removing item:', error);
        showError(`Error removing item: ${error.message}`);
    }
}

// Utility functions
function showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error';
    errorDiv.textContent = message;
    const container = document.querySelector('.container');
    if (container) {
        container.insertBefore(errorDiv, container.firstChild);
        setTimeout(() => errorDiv.remove(), 5000);
    }
}

function showSuccess(message) {
    const successDiv = document.createElement('div');
    successDiv.className = 'success';
    successDiv.textContent = message;
    const container = document.querySelector('.container');
    if (container) {
        container.insertBefore(successDiv, container.firstChild);
        setTimeout(() => successDiv.remove(), 3000);
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
