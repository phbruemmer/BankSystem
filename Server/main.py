import socket
import json
import os
import threading
import time

HOSTNAME = socket.gethostname()
HOST = socket.gethostbyname(HOSTNAME)
HOST = '127.0.0.1'
PORT = 8000
BUFFER = 1024

print(HOST)
print(PORT)

DATA_DIR = './accounts'

if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

commands = ["payout", "get", "check", "transfer", "deposit", "get_balance", "get_history", "change_currency"]

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


def handle_history_sending(client_sock, history_list):
    client_sock.sendall(b'#history#')
    time.sleep(0.1)
    for item in history_list:
        print(item)
        client_sock.sendall(item.encode('utf-8'))
        time.sleep(0.01)
    client_sock.sendall(b'#history#')


def main():
    try:
        s.bind((HOST, PORT))
        print("Starting...")
        s.listen(100)
        accept()
    except Exception as err:
        print(err)
    finally:
        s.close()

def accept():
    while True:
        try:
            client_sock, client_addr = s.accept()
            print(f"Connection from {client_addr}")
            loop(client_sock)
        except Exception as err:
            print(f"Error accepting connections: {err}")

def loop(client_sock):
    try:
        while True:
            data = client_sock.recv(BUFFER)
            if not data:
                break
            data = data.decode().split('#')
            command = data[0]
            print(command)

            if command == commands[0]:  # payout money
                account_id, amount = data[1], int(data[2])
                account_data = load_account(account_id)
                if account_data and account_data['balance'] >= amount:
                    account_data['balance'] -= amount
                    account_data['history'].append(f"{amount} EUR abgehoben")
                    save_account(account_data)
                    msg = b"Geld Ausgabe erfolgreich!"
                else:
                    msg = b"Ungueltiger Account oder zu wenig Geld!"
                client_sock.sendall(msg)
            elif command == commands[1]:  # get account data
                account_id, pin = data[1], data[2]
                account_data = load_account(account_id)
                if account_data and account_data['pin'] == pin:
                    msg = json.dumps(account_data).encode()
                else:
                    msg = b"Ungueltiger Account"
                client_sock.sendall(msg)
            elif command == commands[2]:  # check account
                account_id, pin = data[1], data[2]
                print(pin)
                account_data = load_account(account_id)
                if account_data and account_data['pin'] == pin:
                    msg = b"account_check=true"
                else:
                    msg = b"account_check=false"
                client_sock.sendall(msg)

            elif command == commands[3]:  # transfer money
                from_account, to_account, amount = data[1], data[2], int(data[3])
                from_data = load_account(from_account)
                to_data = load_account(to_account)
                if from_data and to_data and from_data['balance'] >= amount:
                    from_data['balance'] -= amount
                    to_data['balance'] += amount
                    from_data['history'].append(f"{amount} EUR übertragen auf {to_account}")
                    to_data['history'].append(f"{amount} EUR erhalten von {from_account}")
                    save_account(from_data)
                    save_account(to_data)
                    msg = b"Ueberweisung erfolgreich!"
                else:
                    msg = b"Ueberweisung fehlgeschlagen!"
                client_sock.sendall(msg)
            elif command == commands[4]:  # deposit money
                account_id, amount = data[1], int(data[2])
                account_data = load_account(account_id)
                if account_data:
                    account_data['balance'] += amount
                    account_data['history'].append(f"{amount} EUR eingezahlt")
                    save_account(account_data)
                    msg = b"Geld Einzahlung Erfolgreich"
                else:
                    msg = b"Ungueltiger Account"
                client_sock.sendall(msg)
            elif command == commands[5]:
                account_id = data[1]
                account_data = load_account(account_id)
                if account_data:
                    msg = (str(round(account_data['balance'], 2)) + " EUR").encode('utf-8')
                else:
                    msg = b"Ungueltiger Account"
                client_sock.sendall(msg)
            elif command == commands[6]:
                account_id = data[1]
                account_data = load_account(account_id)
                if account_data:
                    history_list = account_data['history']
                    print(history_list)
                    # Create a new thread to handle sending the history
                    history_thread = threading.Thread(target=handle_history_sending, args=(client_sock, history_list))
                    history_thread.start()
                else:
                    msg = b'Ungueltiger Account'
                    client_sock.sendall(msg)
            elif command == commands[7]:
                account_id, amount = data[1], int(data[2])
                account_data = load_account(account_id)
                if account_data and amount <= account_data['balance']:
                    account_data['balance'] -= amount * 0.93
                    account_data['history'].append(f"{amount * 0.93} EUR zu Dollar gewechselt.")
                    save_account(account_data)
                    msg = f"{amount * 0.93} EUR zu Dollar gewechselt.".encode('utf-8')
                else:
                    msg = b"Ungueltiger Account oder zu wenig Geld auf dem Konto!"
                client_sock.sendall(msg)
            else:
                msg = b"Ungueltiger Command"
                client_sock.sendall(msg)
    except Exception as err:
            print(f"Error in loop: {err}")
    finally:
        client_sock.close()


if __name__ == '__main__':
    main()
