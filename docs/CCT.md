# Clause → Control → Test (CCT)

Privacy-focused clauses for the Cloud Pantry Tracker. Each clause lists the control in code and the automated test that enforces it.

| Clause (Promise) | Control (Implementation) | Test (Red Bar) |
| --- | --- | --- |
| Inventory actions stay within the caller’s household. Users cannot write into or read another household by spoofing IDs. | The Lambda derives `householdId` from the authenticated JWT username and ignores any `householdId` supplied in the request body. | `test_inventory_actions_bound_to_token_identity` in `backend/test_privacy_cct.py` sends a token for user A with a body claiming household B and verifies DynamoDB writes under user A’s household. |
| Expired or forged credentials cannot be used to fetch or mutate inventory data. | `verify_token` rejects expired JWTs before routing to inventory handlers, so no database operations run without a valid token. | `test_expired_token_denied_before_database_access` in `backend/test_privacy_cct.py` uses an expired token and asserts a 401 plus zero DynamoDB queries/writes/deletes. |
| Credentials never leave the auth boundary in plaintext. | Signup hashes the password before storage and omits any password material from responses. | `test_signup_hashes_and_never_echoes_password` in `backend/test_privacy_cct.py` signs a user up and confirms the stored value is hashed and no password field is present in the response body. |

## Running the clause-control tests

```bash
cd backend
pip install -r requirements.txt
python -m pytest test_privacy_cct.py
```
