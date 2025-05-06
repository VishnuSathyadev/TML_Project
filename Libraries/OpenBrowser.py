import subprocess

def open_site_url(debug_port):
    try:

        subprocess.Popen(["C:\Program Files\Google\Chrome\Application\chrome.exe","--remote-debugging-port=9222"])
    except Exception as e:
        print(f"An error occurred while opening wbsite: {e}")


