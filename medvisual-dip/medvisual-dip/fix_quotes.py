"""app.js icindeki curly/smart quote karakterleri duz tirnaklarla degistirir."""
with open('static/app.js', 'rb') as f:
    content = f.read()

text = content.decode('utf-8')

replacements = [
    ('“', '"'),  # sol cift curly quote
    ('”', '"'),  # sag cift curly quote
    ('‘', "'"),  # sol tek curly quote
    ('’', "'"),  # sag tek curly quote
]

total = 0
for curly, straight in replacements:
    n = text.count(curly)
    if n:
        print(f'  {repr(curly)} -> {repr(straight)}: {n} adet')
        total += n
    text = text.replace(curly, straight)

print(f'Toplam {total} curly quote duzeltildi.')

with open('static/app.js', 'w', encoding='utf-8') as f:
    f.write(text)

print('Kaydedildi: static/app.js')
