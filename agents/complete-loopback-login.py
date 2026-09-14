#!/usr/bin/env python3
"""Deliver a browser's failed HTTP loopback callback on the machine running the CLI.

The user supplies the callback privately. No proxy, redirects, response bodies or URL logging.
"""
import argparse
import getpass
import http.client
import sys
from urllib.parse import urlsplit


def validate_callback(url, expected_port):
    if not 1 <= expected_port <= 65535:
        raise ValueError("Expected port must be between 1 and 65535")
    if not url or any(character.isspace() or not 32 <= ord(character) < 127 for character in url):
        raise ValueError("Expected a single ASCII HTTP callback URL without whitespace; preserve percent encoding")
    parsed = urlsplit(url)
    if (parsed.scheme != "http" or parsed.hostname not in {"localhost", "127.0.0.1", "::1"}
            or parsed.username is not None or parsed.password is not None
            or parsed.fragment or parsed.port != expected_port):
        raise ValueError("Callback must be HTTP loopback on the expected CLI port, without userinfo or fragment")
    return parsed


def deliver_callback(url, expected_port):
    parsed = validate_callback(url, expected_port)
    # Resolve localhost ourselves so custom resolver configuration cannot send a callback elsewhere.
    hosts = ["127.0.0.1", "::1"] if parsed.hostname == "localhost" else [parsed.hostname]
    for index, host in enumerate(hosts):
        connection = http.client.HTTPConnection(host, expected_port, timeout=10)
        try:
            path = (parsed.path or "/") + ("?" + parsed.query if parsed.query else "")
            connection.request("GET", path, headers={"Host": parsed.netloc})
            response = connection.getresponse()
            # Never follow redirects or print potentially credential-bearing response content.
            return response.status
        except ConnectionRefusedError:
            if index == len(hosts) - 1:
                raise
        finally:
            connection.close()
    raise RuntimeError("No loopback listener available")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", required=True, type=int, help="Port from the active CLI login flow")
    args = parser.parse_args()
    if not sys.stdin.isatty():
        parser.error("Run interactively in the CLI machine's terminal; do not send credentials through an agent")
    try:
        callback = getpass.getpass("Paste the failed loopback callback URL (hidden): ")
        status = deliver_callback(callback, args.port)
    except (ValueError, OSError, http.client.HTTPException):
        print("Callback not delivered. Check the URL, expected port and active CLI login.", file=sys.stderr)
        return 1
    if not 200 <= status < 400:
        print(f"Login listener returned HTTP {status}; check the CLI.", file=sys.stderr)
        return 1
    print("Callback delivered. Confirm that the CLI now reports successful authentication.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
