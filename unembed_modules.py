#!/usr/bin/env python3
"""
Script to remove embedded module content from TimeMAtricks X.lua.
Clears the content between [==[ ]==] brackets, leaving the template intact.
"""

from pathlib import Path

# Configuration
MAIN_FILE = Path("/Users/juriseiffert/Documents/GrandMA3Plugins/TimeMAtricks with modules/TimeMAtricks X.lua")

# Module definitions
MODULES = [
    "GMA",
    "C",
    "UI",
    "XML",
    "S",
    "O",
]

def clear_module_content(content, module_name):
    """Clear the content of a module, leaving just empty brackets."""
    # Find the module entry
    start_marker = f'  {module_name} = {{'
    start_idx = content.find(start_marker)
    
    if start_idx == -1:
        print(f"  ✗ Module {module_name} not found")
        return content
    
    # Find the code block start
    code_start_marker = 'code = [==['
    code_start_idx = content.find(code_start_marker, start_idx)
    
    if code_start_idx == -1:
        print(f"  ✗ Code block for {module_name} not found")
        return content
    
    # Find content start (after "code = [==[")
    content_start_idx = code_start_idx + len(code_start_marker)
    
    # Find the closing bracket
    closing_bracket = ']==]'
    closing_idx = content.find(closing_bracket, content_start_idx)
    
    if closing_idx == -1:
        print(f"  ✗ Closing bracket for {module_name} not found")
        return content
    
    # Replace content with just a newline for readability
    new_content = (
        content[:content_start_idx] +
        "\n" +
        content[closing_idx:]
    )
    
    print(f"  ✓ Cleared {module_name} module content")
    return new_content

def main():
    """Main function to clear all embedded modules."""
    print("Removing embedded module content from TimeMAtricks X.lua...\n")
    
    # Read main file
    if not MAIN_FILE.exists():
        print(f"ERROR: Main file not found: {MAIN_FILE}")
        return False
    
    with open(MAIN_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Clear each module
    print("Clearing modules:")
    for module_name in MODULES:
        content = clear_module_content(content, module_name)
    
    # Write back main file
    with open(MAIN_FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"\n✓ All modules cleared successfully!")
    print(f"✓ File saved: {MAIN_FILE}")
    print("You can now work with separate module files again.")
    print("Use 'python3 embed_modules.py' to re-embed them when ready.")
    return True

if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)
