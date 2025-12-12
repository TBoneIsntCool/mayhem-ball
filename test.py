import socket, json

ip = "192.168.1.5"
port = 4003

payload = {
    "msg": {
        "cmd": "turn",
        "data": {
            "value": 1
        }
    }
}

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.sendto(json.dumps(payload).encode(), (ip, port))
s.close()
