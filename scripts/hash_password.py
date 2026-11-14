#!/usr/bin/env python3
"""Generate a RabbitMQ rabbit_password_hashing_sha256 password hash.

Usage:
    python3 hash_password.py <password>
"""
import os
import sys
import hashlib
import base64


def hash_password(password: str) -> str:
    salt = os.urandom(4)
    digest = hashlib.sha256(salt + password.encode()).digest()
    return base64.b64encode(salt + digest).decode()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: hash_password.py <password>", file=sys.stderr)
        sys.exit(1)
    print(hash_password(sys.argv[1]))
