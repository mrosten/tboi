import os
import json
import re

def parse_glossary(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Filter empty lines
    clean_lines = [line.strip() for line in lines if line.strip()]
    
    entries = []
    current_chunk = []
    
    for line in clean_lines:
        current_chunk.append(line)
        if line.endswith('.'):
            # End of an entry
            entries.append(current_chunk)
            current_chunk = []
            
    # Handle last chunk if no period
    if current_chunk:
        entries.append(current_chunk)

    terms = []
    html_entries = []
    
    for chunk in entries:
        if not chunk: continue
        
        # Heuristic: First line is Term. Rest is Def.
        # Improvement: If first line is very short and second starts with Capital, maybe join?
        # But 'Adam' (newline) 'Kadmon' -> 'Adam' is term?
        # Let's try to join lines 0 and 1 if line 0 is not a sentence?
        
        # Simple approach first
        term = chunk[0]
        definition_lines = chunk[1:]
        
        # Check for split term (e.g. Adam \n Kadmon)
        # If the second line does NOT start with a sentence-like word (The, A, It, name)?
        # Hard to tell.
        # Let's look at "Adam" \n "Kadmon" \n "The region..."
        # If chunk element 1 is "Kadmon", and element 2 is "The region..."
        # "Kadmon" is Title Case. "The" is Title Case.
        
        # Let's stick to First Line = Term for safety, unless manual overrides needed.
        # Actually, let's fix "Adam" manually if we see it.
        if term == "Adam" and len(definition_lines) > 0 and definition_lines[0] == "Kadmon":
            term = "Adam Kadmon"
            definition_lines = definition_lines[1:]
        elif term == "Baal Ha" and len(definition_lines) > 0 and definition_lines[0] == "Tanya":
             term = "Baal Ha Tanya"
             definition_lines = definition_lines[1:]
        elif term == "Banach" and len(definition_lines) > 0 and definition_lines[0] == "space":
             term = "Banach space"
             definition_lines = definition_lines[1:]
        elif term == "Breaking" and len(definition_lines) > 0 and definition_lines[0].startswith("of the vessels"):
             term = "Breaking of the vessels"
             definition_lines = definition_lines[1:]
             
        definition = " ".join(definition_lines)
        
        # Clean ID for anchor
        term_id = re.sub(r'[^a-zA-Z0-9]', '-', term.lower())
        
        terms.append({"term": term, "id": term_id})
        
        html_entries.append(f'''
        <dt id="{term_id}">{term}</dt>
        <dd>{definition}</dd>
        ''')

    # Output HTML
    html_content = '<dl class="glossary-list">\n' + "\n".join(html_entries) + '\n</dl>'
    
    return html_content, terms

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = script_dir
    source_file = os.path.join(base_dir, "split_book", "7-glossary.txt")
    output_html = os.path.join(base_dir, "glossary_content.html")
    output_json = os.path.join(base_dir, "glossary_terms.json")
    
    if os.path.exists(source_file):
        html, terms = parse_glossary(source_file)
        
        with open(output_html, 'w', encoding='utf-8') as f:
            f.write(html)
            
        with open(output_json, 'w', encoding='utf-8') as f:
            json.dump(terms, f, indent=2)
            
        print(f"Generated {output_html} and {output_json}")
    else:
        print(f"Source not found: {source_file}")
