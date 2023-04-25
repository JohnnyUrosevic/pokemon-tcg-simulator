from pokemontcgsdk import Card, Set
from textwrap import indent
import re

TAB = '    '

def parseText(text):
    code = ""
    while text:
        code_part, text = parse(text)
        code += code_part

    return code

def parse(text):
    text = text.strip()
    if (m := re.match('Flip a coin. If heads, (.*?)(?:\.|;)( if tails, (.*)\.)?', text)):
        code = "if Battle.coinFlip():\n"
        code += indent(parseText(m.group(1)), TAB)

        if m.group(2):
            code += "else:\n"
            code += indent(parseText(m.group(3)), TAB)

        return code, text[m.end():]

    sentences = text.split('. ')
    return f"#{sentences[0]}\n", "".join(sentences[1:])

def main():
    count = 0
    cards = Card.where(q='set.id:base1')
    for card in cards:
        if card.supertype == 'Pokémon':
            with open(f"output/{card.id}.gd", "w", encoding="utf-8") as f:
                f.write("extends Node\n\n")
                attacks_code = "var attacks = {\n"
                for attack in card.attacks:
                    current_attack = f'"{attack.name}": func():\n'
                    current_attack += indent(parseText(attack.text), TAB)
                    if attack.damage.isdigit():
                        current_attack += f"    damage(currentOpponent.getActivePokemon(), {attack.damage})\n"
                    attacks_code += indent(current_attack, TAB)
                attacks_code += "}\n"
                f.write(attacks_code)
        count += 1
        if count == 11:
            break

if __name__ == "__main__":
    main()