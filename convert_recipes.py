#!/usr/bin/env python3
"""
Convierte foodDatabase.js a INSERT statements SQL para SQLite
"""
import json
import re
import sys

# Leer el archivo foodDatabase.js
with open('js/foodDatabase.js', 'r', encoding='utf-8') as f:
    content = f.read()

# Extraer el array recipeCatalog
match = re.search(r'const recipeCatalog = \[(.*?)\];', content, re.DOTALL)
if not match:
    print("ERROR: No se pudo encontrar recipeCatalog")
    sys.exit(1)

catalog_str = '[' + match.group(1) + ']'

# Limpiar el contenido de template strings
catalog_str = re.sub(r'`([^`]*)`', lambda m: '"' + m.group(1).replace('"', '\\"').replace('\n', '\\n') + '"', catalog_str)

try:
    recipes = json.loads(catalog_str)
except json.JSONDecodeError as e:
    print(f"ERROR al parsear JSON: {e}")
    # Intento manual
    recipes = []

print("-- ═══════════════════════════════════════════════════")
print("-- RECETAS MEJORADAS (Generadas desde foodDatabase.js)")
print("-- ═══════════════════════════════════════════════════")
print()

# Generar INSERT statements
for recipe in recipes:
    recipe_id = recipe.get('id', 'NULL')
    name = recipe.get('title', '').replace("'", "''")
    emoji = recipe.get('emoji', '🍽️')
    kcal = recipe.get('kcal', 0)
    prot = recipe.get('prot', 0)
    carb = recipe.get('carb', 0)
    fat = recipe.get('fat', 0)
    
    # Ingredientes como JSON
    ingredientes = json.dumps(recipe.get('ingredientes', []), ensure_ascii=False)
    ingredientes = ingredientes.replace("'", "''")
    
    # Preparación
    preparacion = recipe.get('preparacion', '').replace("'", "''")
    
    print(f"INSERT OR REPLACE INTO foods (id, name, emoji, calories, protein, carbs, fat, ingredientes, preparacion, is_quick_food, created_at) VALUES")
    print(f"({recipe_id}, '{name}', '{emoji}', {kcal}, {prot}, {carb}, {fat}, '{ingredientes}', '{preparacion}', 0, (strftime('%s', 'now')));")
    print()

print("-- Total de recetas insertadas")
print(f"-- {len(recipes)} recetas mejoradas")
