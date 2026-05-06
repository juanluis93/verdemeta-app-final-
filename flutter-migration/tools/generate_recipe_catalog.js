const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(
  path.join(__dirname, '..', '..', 'js', 'foodDatabase.js'),
  'utf8',
);
const match = source.match(/const recipeCatalog = \[(.*?)\];\s*const (?:recipeCategories|catLabels)/s);
if (!match) {
  throw new Error('recipeCatalog not found');
}

const catalog = eval('[' + match[1] + ']');
const categoryLabels = {
  desayuno: 'Desayuno',
  almuerzo: 'Almuerzo',
  cena: 'Cena',
  snack: 'Snack',
  postre: 'Postre',
  bebida: 'Bebida',
};

const normalize = (value) =>
  value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/ñ/g, 'n')
    .replace(/\s+/g, ' ')
    .trim();

const extractSteps = (text) => {
  const markers = [...text.matchAll(/(?:^|\s)(\d+)\.\s/g)];
  if (markers.length === 0) {
    return [text.trim()];
  }

  return markers
    .map((marker, index) => {
      const start = marker.index + marker[0].length;
      const end = index + 1 < markers.length ? markers[index + 1].index : text.length;
      return text.slice(start, end).trim();
    })
    .filter(Boolean);
};

const out = {};
for (const recipe of catalog) {
  out[normalize(recipe.title)] = {
    title: recipe.title.trim().replace(/\s+/g, ' '),
    category: recipe.cat,
    subtitle: `${categoryLabels[recipe.cat] || 'Receta'} vegana detallada`,
    ingredients: recipe.ingredientes,
    steps: extractSteps(recipe.preparacion),
  };
}

const target = path.join(__dirname, '..', 'assets', 'data', 'recipe_catalog.json');
fs.writeFileSync(target, JSON.stringify(out, null, 2), 'utf8');
console.log(`Wrote ${Object.keys(out).length} recipes to ${target}`);
