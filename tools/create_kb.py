import os
import xml.sax.saxutils

# CONFIGURATION
# Using the path to the standard library in the user's workspace
REPO_PATH = "/home/matteo/modular-mojo-stdlib/mojo/stdlib"
OUTPUT_FILE = "mojo_knowledge_base.xml"

# Folders to explicitly ignore (noise reduction)
IGNORE_DIRS = {
    "scripts", "lit", "__pycache__", "build", ".git", ".github", "benchmarks", "test"
}

# Extensions to include
INCLUDE_EXTS = {".mojo", ".d.mojo"}

def is_ignored(path):
    parts = path.split(os.sep)
    return any(p in IGNORE_DIRS for p in parts)

def create_knowledge_base():
    # Use absolute path for output to ensure it ends up in the project root or intended location
    # Here we write to current working directory, which should be the repo root when running
    output_path = os.path.abspath(OUTPUT_FILE)
    
    print(f"Scanning {REPO_PATH}...")
    print(f"Writing to {output_path}...")
    
    try:
        with open(output_path, "w", encoding="utf-8") as out:
            out.write("<mojo_stdlib_context>\n")
            out.write("  <description>Official Mojo Standard Library Source Code (Nightly)</description>\n\n")

            file_count = 0
            
            for root, dirs, files in os.walk(REPO_PATH):
                # Modify dirs in-place to skip ignored folders
                dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
                
                for file in files:
                    if not any(file.endswith(ext) for ext in INCLUDE_EXTS):
                        continue
                    
                    full_path = os.path.join(root, file)
                    # Create a clean relative path (e.g., "collections/list.mojo")
                    rel_path = os.path.relpath(full_path, REPO_PATH)
                    
                    # Double check ignore dirs in relative path components to be safe
                    if any(part in IGNORE_DIRS for part in rel_path.split(os.sep)):
                        continue
                        
                    # Check if this is a test file to categorize it (redundant if ignore "test" above, but good for safety)
                    is_test = "test" in rel_path.split(os.sep)
                    category = "usage_example" if is_test else "source_code"

                    try:
                        with open(full_path, "r", encoding="utf-8") as f:
                            content = f.read()
                            
                        # Escape content for XML safety
                        safe_content = xml.sax.saxutils.escape(content)
                        
                        out.write(f'  <file path="{rel_path}" category="{category}">\n')
                        out.write(f'{safe_content}\n')
                        out.write("  </file>\n")
                        file_count += 1
                        
                    except Exception as e:
                        print(f"Skipping {rel_path}: {e}")

            out.write("</mojo_stdlib_context>\n")
            print(f"Success! Packed {file_count} files into {output_path}")
            
    except IOError as e:
        print(f"Error writing output file: {e}")

if __name__ == "__main__":
    if not os.path.exists(REPO_PATH):
        print(f"Error: Could not find path '{REPO_PATH}'.")
    else:
        create_knowledge_base()
