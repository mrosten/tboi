import os
import re

def parse_bibliography(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by dot separator
    entries = content.split('●')
    
    cleaned_entries = []
    for entry in entries:
        # Clean whitespace
        text = entry.strip()
        # Remove empty lines
        lines = [line.strip() for line in text.split('\n') if line.strip()]
        text = ' '.join(lines)
        
        if len(text) > 5: # Ignore tiny noise
            # highlight brackets [Publisher]
            text = re.sub(r'\[(.*?)\]', r'<span class="bib-meta">[\1]</span>', text)
            # highlight parenthesis (Publisher)
            text = re.sub(r'\((.*?)\)', r'<span class="bib-meta">(\1)</span>', text)
            
            cleaned_entries.append(text)

    # Sort alphabetically
    cleaned_entries.sort()

    html = '<ul class="bibliography-list">\n'
    for entry in cleaned_entries:
        html += f'    <li class="bib-item">{entry}</li>\n'
    html += '</ul>'
    
    return html

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = script_dir
    source_file = os.path.join(base_dir, "split_book", "8-bibliography.txt")
    output_file = os.path.join(base_dir, "bibliography_content.html")
    
    if os.path.exists(source_file):
        html_content = parse_bibliography(source_file)
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"Generated {output_file}")
    else:
        print(f"Source not found: {source_file}")
