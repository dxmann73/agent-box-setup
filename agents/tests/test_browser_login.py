import http.server
import importlib.util
from pathlib import Path
import threading
import unittest

spec = importlib.util.spec_from_file_location('login_callback', Path(__file__).parents[1] / 'complete-loopback-login.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class BrowserLoginTests(unittest.TestCase):
    def test_reject_non_loopback_or_wrong_port(self):
        for url in ['http://example.com:1455/callback', 'http://127.0.0.1:8000/callback',
                    'https://localhost:1455/callback', 'http://localhost:1455/callback#code=x',
                    'http://user@localhost:1455/callback', 'http://127.0.0.2:1455/callback',
                    'http://localhost.evil:1455/callback', 'http://localhost:1455/callback\n',
                    'http://localhost:1455/callback?code=a b', 'http://localhost:1455/callback?code=ä']:
            with self.subTest(url=url), self.assertRaises(ValueError):
                helper.validate_callback(url, 1455)

    def test_loopback_variants(self):
        for host in ['localhost', '127.0.0.1', '[::1]']:
            self.assertEqual(helper.validate_callback(f'http://{host}:1455/callback?code=synthetic', 1455).port, 1455)

    def test_local_delivery_preserves_query_and_does_not_follow_redirect(self):
        requests = []

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                requests.append(self.path)
                self.send_response(302)
                self.send_header('Location', '/must-not-follow')
                self.end_headers()

            def log_message(self, *args):
                pass

        server = http.server.HTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            port = server.server_port
            status = helper.deliver_callback(f'http://localhost:{port}/callback?code=synthetic&state=a%2Bb', port)
            self.assertEqual(status, 302)
            self.assertEqual(requests, ['/callback?code=synthetic&state=a%2Bb'])
        finally:
            server.shutdown()
            server.server_close()
            thread.join()


if __name__ == '__main__':
    unittest.main()
