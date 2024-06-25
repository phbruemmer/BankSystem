import json
import os

DATA_DIR = './accounts'

if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)


def load_account(account_id):
    account_file = os.path.join(DATA_DIR, f"{account_id}.json")
    if os.path.exists(account_file):
        with open(account_file, 'r') as f:
            return json.load(f)
    else:
        return None


def save_account(account_data):
    account_file = os.path.join(DATA_DIR, f"{account_data['account_id']}.json")
    with open(account_file, 'w') as f:
        json.dump(account_data, f)


def create_account(account_id, pin):
    if load_account(account_id):
        print("Account already exists")
    else:
        account_data = {
            "account_id": account_id,
            "pin": pin,
            "balance": 10000,
            "history": []
        }
        save_account(account_data)
        print("Account created successfully")


if __name__ == '__main__':
    account_id = input("Enter account ID: ")
    pin = input("Enter PIN: ")
    create_account(account_id, pin)
