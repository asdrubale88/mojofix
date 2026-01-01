import os
import re

REPO_PATH = "/home/matteo/modular-mojo-stdlib/mojo/stdlib"
XML_FILE = "/home/matteo/mojofix/mojo_knowledge_base.xml"

IGNORE_DIRS = {
    "scripts", "lit", "__pycache__", "build", ".git", ".github", "benchmarks", "test"
}
INCLUDE_EXTS = {".mojo", ".d.mojo"}

def get_repo_files():
    files_set = set()
    for root, dirs, files in os.walk(REPO_PATH):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        for file in files:
            if not any(file.endswith(ext) for ext in INCLUDE_EXTS):
                continue
            
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, REPO_PATH)
            
            # Re-apply ignore check on path components just to be identical to generation logic
            if any(part in IGNORE_DIRS for part in rel_path.split(os.sep)):
                continue
                
            files_set.add(rel_path)
    return files_set

def get_xml_files():
    files_set = set()
    try:
        with open(XML_FILE, 'r') as f:
            content = f.read()
            # Simple regex to extract paths from <file path="...">
            matches = re.finditer(r'<file path="([^"]+)"', content)
            for match in matches:
                files_set.add(match.group(1))
    except FileNotFoundError:
        print(f"XML file not found: {XML_FILE}")
    return files_set

def verify():
    repo_files = get_repo_files()
    xml_files = get_xml_files()
    
    print(f"Repo relevant files: {len(repo_files)}")
    print(f"XML indexed files:   {len(xml_files)}")
    
    missing_in_xml = repo_files - xml_files
    extra_in_xml = xml_files - repo_files
    
    if missing_in_xml:
        print("\nMISSING in XML:")
        for f in list(missing_in_xml)[:10]:
            print(f" - {f}")
        if len(missing_in_xml) > 10:
            print(f"... and {len(missing_in_xml) - 10} more")
            
    if extra_in_xml:
        print("\nEXTRA in XML (should not happen):")
        for f in list(extra_in_xml)[:10]:
            print(f" - {f}")
            
    if not missing_in_xml and not extra_in_xml:
        print("\nSUCCESS: File lists match perfectly.")
        
    # Check for empty files or bad content
    with open(XML_FILE, 'r') as f:
        head = f.read(500)
        f.seek(0, 2)
        size = f.tell()
        tail_pos = max(0, size - 500)
        f.seek(tail_pos)
        tail = f.read()
        
    print(f"\nXML Header Sample:\n{head}...")
    print(f"\nXML Footer Sample:\n...{tail}")

if __name__ == "__main__":
    verify()
