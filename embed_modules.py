#!/usr/bin/env python3
"""
Script to copy module content into TimeMAtricks X.lua code table.
The bracket escaping is pre-configured in the main file template as [==[ ]==].
This script simply copies module content as-is into the code blocks.
"""

import os
from pathlib import Path

# Configuration
MODULES_DIR = Path("/Users/juriseiffert/Documents/GrandMA3Plugins/TimeMAtricks with modules/modules")
MAIN_FILE = Path("/Users/juriseiffert/Documents/GrandMA3Plugins/TimeMAtricks with modules/TimeMAtricks X.lua")

# Module definitions - order matters!
MODULES = [
    ("GMA", "gma.lua"),
    ("C", "constants.lua"),
    ("UI", "ui.lua"),
    ("XML", "ui_xml.lua"),
    ("S", "signals.lua"),
    ("O", "operators.lua"),
]

def read_module(filepath):
    """Read a module file and return its content."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def replace_module_content(main_content, module_name, module_content):
    """Replace the content of a specific module in the code table."""
    # Find the module entry: "ModuleName = {" ... "code = [==[ ... ]==]" ... "}"
    start_marker = f'  {module_name} = {{'
    start_idx = main_content.find(start_marker)
    
    if start_idx == -1:
        print(f"ERROR: Could not find module {module_name} in main file")
        return None
    
    # Find the code block start
    code_start_marker = 'code = [==['
    code_start_idx = main_content.find(code_start_marker, start_idx)
    
    if code_start_idx == -1:
        print(f"ERROR: Could not find code block for module {module_name}")
        return None
    
    # Find the content start (after "code = [==[")
    content_start_idx = code_start_idx + len(code_start_marker)
    
    # Find the closing bracket
    closing_bracket = ']==]'
    closing_idx = main_content.find(closing_bracket, content_start_idx)
    
    if closing_idx == -1:
        print(f"ERROR: Could not find closing bracket for module {module_name}")
        return None
    
    # Replace the content between the opening and closing markers
    new_content = (
        main_content[:content_start_idx] +
        module_content +
        main_content[closing_idx:]
    )
    
    return new_content

def main():
    """Main function to embed all modules."""
    print("Copying module content into TimeMAtricks X.lua...")
    
    # Check modules directory exists
    if not MODULES_DIR.exists():
        print(f"ERROR: Modules directory not found: {MODULES_DIR}")
        return False
    
    # Read main file
    with open(MAIN_FILE, 'r', encoding='utf-8') as f:
        main_content = f.read()
    
    # Process each module
    for module_name, module_file in MODULES:
        module_path = MODULES_DIR / module_file
        
        if not module_path.exists():
            print(f"✗ Module file not found: {module_path}")
            return False
        
        # Read module content
        module_content = read_module(module_path)
        print(f"✓ Read {module_name:3} module ({len(module_content):6} bytes)")
        
        # Replace in main content
        main_content = replace_module_content(main_content, module_name, module_content)
        if main_content is None:
            return False
        
        print(f"  → Embedded into main file")
    
    # Write back main file
    with open(MAIN_FILE, 'w', encoding='utf-8') as f:
        f.write(main_content)
    
    print(f"\n✓ All modules copied successfully!")
    print(f"✓ File saved: {MAIN_FILE}")
    return True

if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)
