import 'package:flutter/material.dart';

abstract class FoodNameTranslationService {
  String translate(String name, Locale locale);
}

class FoodNameTranslator {
  static String translate(String name, Locale locale) {
    if (locale.languageCode == 'es') return name;
    final key = _normalize(name);
    return _esToEn[key] ?? name;
  }

  static String _normalize(String value) {
    final lower = value.trim().toLowerCase();
    return lower
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ç', 'c')
        .replaceAll("'", '')
        .replaceAll('’', '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static const Map<String, String> _esToEn = {
    'aceite de aguacate': 'Avocado oil',
    'aceite de coco': 'Coconut oil',
    'aceite de girasol': 'Sunflower oil',
    'aceite de oliva': 'Olive oil',
    'acelga': 'Swiss chard',
    'aderezo de tahini': 'Tahini dressing',
    'agua de coco': 'Coconut water',
    'agua de jamaica': 'Hibiscus drink',
    'agua de pepino y limon': 'Cucumber lemon water',
    'agua fresca de sandia': 'Watermelon agua fresca',
    'aguacate': 'Avocado',
    'almendras': 'Almonds',
    'anacardos': 'Cashews',
    'apio': 'Celery',
    'arandanos': 'Blueberries',
    'arepas veganas rellenas': 'Stuffed vegan arepas',
    'arroz blanco': 'White rice',
    'arroz frito vegano con tofu': 'Vegan fried rice with tofu',
    'arroz integral': 'Brown rice',
    'arvejas': 'Peas',
    'atun vegano': 'Vegan tuna',
    'avellanas': 'Hazelnuts',
    'avena': 'Oats',
    'avena horneada con manzana': 'Baked oats with apple',
    'banana con mantequilla de mani': 'Banana with peanut butter',
    'barra de granola vegana': 'Vegan granola bar',
    'barritas energeticas de datiles': 'Date energy bars',
    'batido verde energizante': 'Energizing green smoothie',
    'berenjena': 'Eggplant',
    'berenjenas a la parmesana vegana': 'Vegan eggplant parmesan',
    'bolitas de coco y limon': 'Coconut lemon bites',
    'bowl de acai tropical': 'Tropical acai bowl',
    'bowl de avena con frutas del bosque': 'Oat bowl with mixed berries',
    'bowl de batata asada y tahini': 'Roasted sweet potato and tahini bowl',
    'bowl verde de quinoa': 'Green quinoa bowl',
    'brocoli': 'Broccoli',
    'brownie vegano': 'Vegan brownie',
    'brownies veganos de chocolate': 'Vegan chocolate brownies',
    'bruschetta de tomate': 'Tomato bruschetta',
    'buddha bowl mediterraneo': 'Mediterranean Buddha bowl',
    'burrito bowl de frijoles': 'Bean burrito bowl',
    'cafe helado con leche de coco': 'Iced coffee with coconut milk',
    'cafe negro': 'Black coffee',
    'camote': 'Sweet potato',
    'cebada': 'Barley',
    'cereal de avena': 'Oat cereal',
    'chai latte vegano': 'Vegan chai latte',
    'champinones': 'Mushrooms',
    'cheesecake vegano de arandanos': 'Vegan blueberry cheesecake',
    'chia pudding de fresa': 'Strawberry chia pudding',
    'chili sin carne': 'Meatless chili',
    'chips de batata al horno': 'Baked sweet potato chips',
    'chips de kale crujientes': 'Crispy kale chips',
    'chips de verduras': 'Vegetable chips',
    'chocolate caliente vegano': 'Vegan hot chocolate',
    'chocolate negro vegano': 'Vegan dark chocolate',
    'col rizada': 'Kale',
    'coliflor': 'Cauliflower',
    'compota de frutas con granola': 'Fruit compote with granola',
    'cornflakes veganos': 'Vegan cornflakes',
    'crackers de semillas': 'Seed crackers',
    'crema de mani': 'Peanut butter',
    'crumble de frutas del bosque': 'Mixed berry crumble',
    'cupcakes de vainilla veganos': 'Vegan vanilla cupcakes',
    'curry de garbanzos y espinaca': 'Chickpea and spinach curry',
    'curry verde thai con tofu': 'Thai green curry with tofu',
    'dahl de lentejas rojas': 'Red lentil dal',
    'dha/epa de algas': 'Algae DHA/EPA',
    'dip de queso vegano con nachos': 'Vegan cheese dip with nachos',
    'donas veganas glaseadas': 'Glazed vegan donuts',
    'edamame': 'Edamame',
    'edamame con sal de mar': 'Edamame with sea salt',
    'ensalada cesar vegana': 'Vegan Caesar salad',
    'espinaca': 'Spinach',
    'estofado de lentejas y vegetales': 'Lentil and vegetable stew',
    'fajitas veganas de portobello': 'Vegan portobello fajitas',
    'falafel horneado con tzatziki': 'Baked falafel with tzatziki',
    'fideos con salsa de cacahuete': 'Noodles with peanut sauce',
    'filete de pescado vegano': 'Vegan fish fillet',
    'french toast vegano': 'Vegan French toast',
    'fresa': 'Strawberry',
    'fresas con chocolate fundido': 'Strawberries with melted chocolate',
    'frijoles blancos': 'White beans',
    'frijoles negros': 'Black beans',
    'frijoles pintos': 'Pinto beans',
    'frijoles rojos': 'Red beans',
    'galletas de avena y chocolate': 'Oat and chocolate cookies',
    'galletas veganas': 'Vegan cookies',
    'garbanzos': 'Chickpeas',
    'golden latte de curcuma': 'Turmeric golden latte',
    'granola casera con frutos secos': 'Homemade granola with nuts',
    'guacamole con totopos': 'Guacamole with tortilla chips',
    'guayaba': 'Guava',
    'gyozas veganas de verduras': 'Vegan vegetable gyoza',
    'hamburguesa de proteina de guisante': 'Pea protein burger',
    'hamburguesa de soja': 'Soy burger',
    'hamburguesas de frijol negro': 'Black bean burgers',
    'helado de almendras': 'Almond ice cream',
    'helado de coco': 'Coconut ice cream',
    'helado de mango y coco': 'Mango coconut ice cream',
    'hummus clasico con crudites': 'Classic hummus with crudites',
    'infusion de menta y hierba luisa': 'Mint and lemon verbena infusion',
    'jugo de frutas': 'Fruit juice',
    'jugo de zanahoria y naranja': 'Carrot and orange juice',
    'jugo verde detox': 'Green detox juice',
    'kiwi': 'Kiwi',
    'kombucha': 'Kombucha',
    'lasana vegana de berenjena': 'Vegan eggplant lasagna',
    'leche de almendras': 'Almond milk',
    'leche de arroz': 'Rice milk',
    'leche de avena': 'Oat milk',
    'leche de coco': 'Coconut milk',
    'leche de soja': 'Soy milk',
    'lechuga': 'Lettuce',
    'lentejas cocidas': 'Cooked lentils',
    'levadura nutricional': 'Nutritional yeast',
    'limon': 'Lemon',
    'limonada de fresa': 'Strawberry lemonade',
    'maiz': 'Corn',
    'mango': 'Mango',
    'mantequilla de almendras': 'Almond butter',
    'mantequilla vegana': 'Vegan butter',
    'manzana': 'Apple',
    'matcha latte con leche de avena': 'Matcha latte with oat milk',
    'mayonesa vegana': 'Vegan mayonnaise',
    'mijo': 'Millet',
    'miso': 'Miso',
    'mix de frutos secos especiados': 'Spiced mixed nuts',
    'mousse de chocolate y aguacate': 'Chocolate avocado mousse',
    'muffins de arandano veganos': 'Vegan blueberry muffins',
    'naan con curry de verduras': 'Naan with vegetable curry',
    'naranja': 'Orange',
    'natto': 'Natto',
    'nice cream de banana': 'Banana nice cream',
    'nueces': 'Walnuts',
    'pad thai vegano': 'Vegan pad thai',
    'palomitas con levadura nutricional': 'Popcorn with nutritional yeast',
    'palomitas de maiz': 'Popcorn',
    'pan integral': 'Whole wheat bread',
    'pan vegano': 'Vegan bread',
    'pancakes de banana y avena': 'Banana oat pancakes',
    'panna cotta de coco y mango': 'Coconut mango panna cotta',
    'papa': 'Potato',
    'papaya': 'Papaya',
    'parfait de frutas y yogur de coco': 'Fruit and coconut yogurt parfait',
    'pasta al pesto de espinaca': 'Spinach pesto pasta',
    'pasta integral': 'Whole wheat pasta',
    'pasta primavera vegana': 'Vegan pasta primavera',
    'pastel de zanahoria vegano': 'Vegan carrot cake',
    'pepino': 'Cucumber',
    'pepitas de calabaza': 'Pumpkin seeds',
    'pera': 'Pear',
    'pesto vegano': 'Vegan pesto',
    'pimientos': 'Peppers',
    'pimientos rellenos de quinoa': 'Quinoa stuffed peppers',
    'pina': 'Pineapple',
    'pistachos': 'Pistachios',
    'pizza de masa de coliflor': 'Cauliflower crust pizza',
    'pizza vegana con vegetales': 'Vegan veggie pizza',
    'platano': 'Banana',
    'polenta cremosa con setas': 'Creamy polenta with mushrooms',
    'porridge de zanahoria y canela': 'Carrot cinnamon porridge',
    'pretzels suaves veganos': 'Soft vegan pretzels',
    'proteina de arroz': 'Rice protein',
    'proteina de guisante': 'Pea protein',
    'proteina de soja': 'Soy protein',
    'proteina vegana en polvo': 'Vegan protein powder',
    'queso de anacardo': 'Cashew cheese',
    'queso vegano cheddar': 'Vegan cheddar cheese',
    'quiche vegano de espinaca': 'Vegan spinach quiche',
    'quinoa cocida': 'Cooked quinoa',
    'ramen de miso con tofu crujiente': 'Miso ramen with crispy tofu',
    'remolacha': 'Beetroot',
    'repollo': 'Cabbage',
    'risotto de champinones': 'Mushroom risotto',
    'rollitos de arroz con mango': 'Mango rice rolls',
    'rollitos de pepino con hummus': 'Cucumber rolls with hummus',
    'salchicha vegana': 'Vegan sausage',
    'salsa bbq vegana': 'Vegan BBQ sauce',
    'salsa de soja': 'Soy sauce',
    'salsa de tomate': 'Tomato sauce',
    'salteado de brocoli y sesamo': 'Broccoli sesame stir-fry',
    'sandia': 'Watermelon',
    'semillas de chia': 'Chia seeds',
    'semillas de girasol': 'Sunflower seeds',
    'semillas de lino': 'Flax seeds',
    'semillas de sesamo': 'Sesame seeds',
    'smoothie bowl de acai': 'Acai smoothie bowl',
    'smoothie de arandanos y avena': 'Blueberry oat smoothie',
    'smoothie de coco y pina': 'Coconut pineapple smoothie',
    'smoothie de durazno y vainilla': 'Peach vanilla smoothie',
    'smoothie tropical de mango': 'Tropical mango smoothie',
    'soja': 'Soybeans',
    'sopa de calabaza y jengibre': 'Pumpkin ginger soup',
    'sopa de zanahoria y coco': 'Carrot coconut soup',
    'tacos de jackfruit al pastor': 'Jackfruit al pastor tacos',
    'tagine marroqui de garbanzos': 'Moroccan chickpea tagine',
    'tahini': 'Tahini',
    'tamales veganos de rajas': 'Vegan poblano tamales',
    'tapenade de aceitunas': 'Olive tapenade',
    'tarta de limon vegana': 'Vegan lemon tart',
    'tarta de manzana vegana': 'Vegan apple pie',
    'te': 'Tea',
    'te de jengibre y limon': 'Ginger lemon tea',
    'tempeh': 'Tempeh',
    'tikka masala de coliflor': 'Cauliflower tikka masala',
    'tofu firme': 'Firm tofu',
    'tofu revuelto con verduras': 'Tofu scramble with vegetables',
    'tomate': 'Tomato',
    'tortitas de espinaca y maiz': 'Spinach and corn patties',
    'tostada de aguacate y tomate': 'Avocado tomato toast',
    'trufas de chocolate y mani': 'Chocolate peanut truffles',
    'uvas': 'Grapes',
    'vitamina b12 vegana': 'Vegan vitamin B12',
    'wrap de hummus y vegetales': 'Hummus and veggie wrap',
    'yogur de almendras': 'Almond yogurt',
    'yogur de coco': 'Coconut yogurt',
    'yogur de soja': 'Soy yogurt',
    'zanahoria': 'Carrot',
    'zucchini': 'Zucchini',
    'zumo de naranja y remolacha': 'Orange beet juice',
    'shepherds pie vegano': 'Vegan shepherd\'s pie',
  };
}

class DefaultFoodNameTranslationService implements FoodNameTranslationService {
  const DefaultFoodNameTranslationService();

  @override
  String translate(String name, Locale locale) {
    return FoodNameTranslator.translate(name, locale);
  }
}
