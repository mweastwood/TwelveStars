import urllib.request
import os
import time

VOLUMES = {
    "vol1": "AI156",
    "vol2": "AI157",
    "vol3": "AI158",
    "vol4": "AI159"
}

def download_file(url, filepath):
    print(f"Downloading {url} to {filepath}...")
    try:
        req = urllib.request.Request(
            url, 
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'}
        )
        with urllib.request.urlopen(req) as response, open(filepath, 'wb') as out_file:
            buffer_size = 1024 * 1024 # 1MB buffer
            while True:
                chunk = response.read(buffer_size)
                if not chunk:
                    break
                out_file.write(chunk)
        print(f"Successfully downloaded to {filepath}")
        return True
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        return False

def main():
    # Use relative path for replication inside assets folder
    pdf_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "pdf"))
    os.makedirs(pdf_dir, exist_ok=True)
    
    for vol_name, item_id in VOLUMES.items():
        # Download PDF scan
        pdf_url = f"https://archive.org/download/{item_id}/{item_id}.pdf"
        pdf_path = os.path.join(pdf_dir, f"{vol_name}_scan.pdf")
        if not os.path.exists(pdf_path):
            download_file(pdf_url, pdf_path)
            time.sleep(1)
        else:
            print(f"{vol_name}_scan.pdf already exists under {pdf_dir}, skipping download.")

if __name__ == "__main__":
    main()
