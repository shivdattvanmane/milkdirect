import os
import subprocess
import sys

def generate_pdf():
    html_file = os.path.abspath("milkdirect_project_overview.html")
    pdf_file = os.path.abspath("MilkDirect_Project_Documentation.pdf")
    
    edge_paths = [
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    ]
    
    browser_exe = None
    for p in edge_paths:
        if os.path.exists(p):
            browser_exe = p
            break
            
    if not browser_exe:
        print("Error: No Chromium-based browser found.")
        sys.exit(1)
        
    print(f"Using browser: {browser_exe}")
    print(f"Converting {html_file} -> {pdf_file}...")
    
    file_url = "file:///" + html_file.replace("\\", "/")
    
    cmd = [
        browser_exe,
        "--headless",
        "--disable-gpu",
        "--run-all-compositor-stages-before-draw",
        "--no-pdf-header-footer",
        f"--print-to-pdf={pdf_file}",
        file_url
    ]
    
    res = subprocess.run(cmd, capture_output=True, text=True)
    if os.path.exists(pdf_file) and os.path.getsize(pdf_file) > 0:
        size_kb = os.path.getsize(pdf_file) / 1024
        print(f"SUCCESS: PDF generated successfully! Size: {size_kb:.1f} KB")
        print(f"Path: {pdf_file}")
    else:
        print(f"FAILED to generate PDF. Exit code: {res.returncode}")
        print("Stderr:", res.stderr)
        print("Stdout:", res.stdout)
        sys.exit(1)

if __name__ == "__main__":
    generate_pdf()
