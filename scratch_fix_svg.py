import re
import glob

def inline_svg_styles(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    style_match = re.search(r'<style[^>]*>(.*?)</style>', content, re.DOTALL)
    if not style_match:
        return
    
    css_text = style_match.group(1)
    
    # parse classes
    classes = {}
    for rule in re.finditer(r'\.([a-zA-Z0-9_-]+)\s*\{([^}]+)\}', css_text):
        class_name = rule.group(1)
        styles = rule.group(2).strip()
        classes[class_name] = styles

    # remove style tag
    content = content[:style_match.start()] + content[style_match.end():]

    # replace class= attributes with inline styles or properties
    def replacer(m):
        cls_name = m.group(1)
        if cls_name in classes:
            return 'style=\"' + classes[cls_name] + '\"'
        return m.group(0)

    content = re.sub(r'class=[\"\']([a-zA-Z0-9_-]+)[\"\']', replacer, content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Processed {filepath}')

for svg in glob.glob('assets/icons/*.svg'):
    inline_svg_styles(svg)
