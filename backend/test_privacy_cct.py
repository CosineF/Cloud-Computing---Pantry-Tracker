import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path
from types import SimpleNamespace

import importlib

BACKEND_ROOT = Path(__file__).resolve().parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

# Ensure the Lambda module picks up a test secret
os.environ["JWT_SECRET"] = "test-secret-key"
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
lambda_function = importlib.import_module("lambda_function")
lambda_function.jwt_secret = os.environ["JWT_SECRET"]


class FakeInventoryTable:
    """Lightweight in-memory stand-in for the inventory DynamoDB table."""

    def __init__(self):
        self.items_by_household = {}
        self.last_put_item = None
        self.queries = []
        self.deleted = []

    def query(self, **kwargs):
        self.queries.append(kwargs)
        hid = kwargs["ExpressionAttributeValues"][":hid"]
        return {"Items": list(self.items_by_household.get(hid, []))}

    def put_item(self, Item):
        self.last_put_item = Item
        self.items_by_household.setdefault(Item["householdId"], []).append(Item)
        return {}

    def delete_item(self, **kwargs):
        self.deleted.append(kwargs)
        key = kwargs.get("Key", {})
        hid = key.get("householdId")
        item_id = key.get("itemId")
        removed = None
        if hid in self.items_by_household:
            items = self.items_by_household[hid]
            for idx, item in enumerate(items):
                if item.get("itemId") == item_id:
                    removed = items.pop(idx)
                    break
        return {"Attributes": removed} if removed else {}


class FakeUsersTable:
    """Simple user table substitute for signup/login flows."""

    def __init__(self):
        self.storage = {}
        self.get_requests = []
        self.put_requests = []

    def get_item(self, Key):
        self.get_requests.append(Key)
        username = Key["username"]
        if username in self.storage:
            return {"Item": self.storage[username]}
        return {}

    def put_item(self, Item):
        self.put_requests.append(Item)
        self.storage[Item["username"]] = Item
        return {}


def build_event(method, path, body=None, headers=None):
    event = {"httpMethod": method, "path": path, "headers": headers or {}}
    if body is not None:
        event["body"] = json.dumps(body)
    return event


def issue_token(username, expires_delta=timedelta(days=7)):
    now = datetime.utcnow()
    payload = {
        "username": username,
        "exp": now + expires_delta,
        "iat": now,
    }
    return lambda_function.jwt.encode(
        payload, lambda_function.jwt_secret, algorithm="HS256"
    )


def test_inventory_actions_bound_to_token_identity():
    """Clause: A user cannot write inventory entries for another household."""
    inv_table = FakeInventoryTable()
    lambda_function.table = inv_table
    lambda_function.users_table = FakeUsersTable()
    token = issue_token("alice")

    event = build_event(
        "POST",
        "/inventory",
        body={"householdId": "bob", "name": "Milk", "quantity": 1},
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )

    response = lambda_function.lambda_handler(event, SimpleNamespace())
    body = json.loads(response["body"])

    assert response["statusCode"] == 200
    assert body["item"]["name"] == "Milk"
    assert inv_table.last_put_item["householdId"] == "alice"
    assert inv_table.last_put_item["itemId"].startswith("alice#")


def test_expired_token_denied_before_database_access():
    """Clause: Expired credentials cannot be used to view or mutate inventory."""
    inv_table = FakeInventoryTable()
    lambda_function.table = inv_table
    lambda_function.users_table = FakeUsersTable()

    expired_token = issue_token("mallory", expires_delta=timedelta(seconds=-10))
    event = build_event(
        "GET",
        "/inventory",
        headers={"Authorization": f"Bearer {expired_token}"},
    )

    response = lambda_function.lambda_handler(event, SimpleNamespace())

    assert response["statusCode"] == 401
    assert inv_table.queries == []
    assert inv_table.last_put_item is None
    assert inv_table.deleted == []


def test_signup_hashes_and_never_echoes_password():
    """Clause: Password material is stored hashed and never returned in responses."""
    inv_table = FakeInventoryTable()
    users_table = FakeUsersTable()
    lambda_function.table = inv_table
    lambda_function.users_table = users_table

    event = build_event(
        "POST",
        "/auth/signup",
        body={"username": "bob", "password": "PlainPass123"},
        headers={"Content-Type": "application/json"},
    )

    response = lambda_function.lambda_handler(event, SimpleNamespace())
    body = json.loads(response["body"])
    stored = users_table.storage["bob"]

    assert response["statusCode"] == 201
    assert stored["password"] == lambda_function.hash_password("PlainPass123")
    assert stored["password"] != "PlainPass123"
    assert "password" not in body
