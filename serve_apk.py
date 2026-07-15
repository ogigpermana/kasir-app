import http.server
import socketserver
import os

PORT = 8080
DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'app', 'outputs', 'flutter-apk')

os.chdir(DIR)

Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Serving APK at http://0.0.0.0:{PORT}")
    print(f"List files:")
    for f in os.listdir('.'):
        if f.endswith('.apk'):
            print(f"  http://0.0.0.0:{PORT}/{f}")
    httpd.serve_forever()
