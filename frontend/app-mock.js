// Mock version for testing without backend
// This simulates API responses so you can test the UI immediately

// Mock data storage (in-memory, resets on page refresh)
const mockStorage = {};

// Get inventory for a household
async function loadInventory() {
    const householdId = document.getElementById('householdId').value.trim();
    
    if (!householdId) {
        showError('Please enter a household ID');
        return;
    }

    const inventoryList = document.getElementById('inventoryList');
    inventoryList.innerHTML = '<p class="loading">Loading inventory...</p>';

    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 300));

    try {
        // Get items from mock storage
        const items = mockStorage[householdId] || [];
        
        displayInventory(items);
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
    const householdId = document.getElementById('householdId').value.trim();
    const itemName = document.getElementById('itemName').value.trim();
    const itemQuantity = parseInt(document.getElementById('itemQuantity').value) || 1;

    if (!householdId) {
        showError('Please enter a household ID');
        return;
    }

    if (!itemName) {
        showError('Please enter an item name');
        return;
    }

    if (itemQuantity < 1) {
        showError('Quantity must be at least 1');
        return;
    }

    try {
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 200));

        // Initialize household storage if needed
        if (!mockStorage[householdId]) {
            mockStorage[householdId] = [];
        }

        // Generate item ID
        const itemId = `${householdId}#${Date.now()}`;
        
        // Add item to mock storage
        const item = {
            id: itemId,
            name: itemName,
            quantity: itemQuantity
        };
        
        mockStorage[householdId].push(item);
        
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
    const householdId = document.getElementById('householdId').value.trim();
    
    if (!householdId) {
        showError('Please enter a household ID');
        return;
    }

    if (!confirm(`Are you sure you want to remove ${itemName}?`)) {
        return;
    }

    try {
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 200));

        // Remove item from mock storage
        if (mockStorage[householdId]) {
            mockStorage[householdId] = mockStorage[householdId].filter(item => item.id !== itemId);
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
    document.querySelector('.container').insertBefore(errorDiv, document.querySelector('.container').firstChild);
    
    setTimeout(() => errorDiv.remove(), 5000);
}

function showSuccess(message) {
    const successDiv = document.createElement('div');
    successDiv.className = 'success';
    successDiv.textContent = message;
    document.querySelector('.container').insertBefore(successDiv, document.querySelector('.container').firstChild);
    
    setTimeout(() => successDiv.remove(), 3000);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Load inventory on page load if household ID is set
document.addEventListener('DOMContentLoaded', () => {
    const householdId = document.getElementById('householdId').value;
    if (householdId) {
        loadInventory();
    }
});

