-- ═══════════════════════════════════════════════════
-- SEED DATA v9 - ALIMENTOS VEGANOS CON RECETAS
-- Datos iniciales con 105 recetas detalladas
-- ═══════════════════════════════════════════════════

-- QUICK FOODS (12 alimentos frecuentes - SIN RECETAS DETALLADAS)
INSERT INTO foods (id, name, emoji, calories, protein, carbs, fat, fiber, sugar, iron, calcium, b12, zinc, is_quick_food, ingredientes, preparacion) VALUES
(1000, 'Tofu firme', '🧊', 80, 8.5, 1.9, 4.8, 0.3, 0.6, 1.3, 200, 0, 0.8, 1, '["Tofu firme"]', 'Alimento básico vegano rico en proteína'),
(1001, 'Lentejas cocidas', '🫘', 116, 9, 20, 0.4, 8, 1.8, 3.3, 19, 0, 1.3, 1, '["Lentejas"]', 'Alimento nutritivo con proteína vegetal'),
(1002, 'Garbanzos', '🫙', 164, 8.9, 27, 2.6, 7.6, 4.8, 2.9, 49, 0, 1.5, 1, '["Garbanzos"]', 'Legumbre versátil y nutritiva'),
(1003, 'Quinoa cocida', '🌾', 120, 4.4, 21.3, 1.9, 2.8, 0.9, 1.5, 17, 0, 1.1, 1, '["Quinoa"]', 'Seudocereal completo en aminoácidos'),
(1004, 'Espinaca', '🥬', 23, 2.9, 3.6, 0.4, 2.2, 0.4, 2.7, 99, 0, 0.5, 1, '["Espinaca"]', 'Verdura de hoja verde rica en hierro'),
(1005, 'Aguacate', '🥑', 160, 2, 9, 14.7, 6.7, 0.7, 0.6, 12, 0, 0.6, 1, '["Aguacate"]', 'Fruta con grasas saludables'),
(1006, 'Plátano', '🍌', 89, 1.1, 23, 0.3, 2.6, 12, 0.3, 5, 0, 0.2, 1, '["Plátano"]', 'Fruta rica en potasio y energía'),
(1007, 'Leche de soja', '🥛', 54, 3.3, 6.3, 1.8, 0.6, 4.8, 0.4, 120, 1.2, 0.3, 1, '["Leche de soja"]', 'Bebida vegetal alternativa a la leche'),
(1008, 'Nueces', '🥜', 654, 15, 14, 65, 6.7, 2.6, 2.9, 98, 0, 3.1, 1, '["Nueces"]', 'Frutos secos ricos en Omega-3'),
(1009, 'Brócoli', '🥦', 34, 2.8, 7, 0.4, 2.6, 1.7, 0.7, 47, 0, 0.4, 1, '["Brócoli"]', 'Verdura crucífera nutritiva'),
(1010, 'Arroz integral', '🍚', 216, 5, 45, 1.8, 3.5, 0.7, 1.1, 20, 0, 1.2, 1, '["Arroz integral"]', 'Cereal completo'),
(1011, 'Tempeh', '🟫', 195, 20, 7.6, 11, 5, 0, 2.7, 184, 0, 1.7, 1, '["Tempeh"]', 'Alimento fermentado de soja con proteína');

-- RECETAS DETALLADAS (105 recetas con ingredientes y preparación)
INSERT INTO foods (id, name, emoji, calories, protein, carbs, fat, ingredientes, preparacion, is_quick_food) VALUES
(1, 'Bowl de avena con frutas del bosque', '🥣', 380, 12, 62, 8, 
'["50g avena","200ml leche de almendra","80g frutas del bosque (arándanos, fresas)","15g almendras laminadas","5ml miel","Canela al gusto"]',
'1. Vierte 200ml de leche de almendra en una olla pequeña y caliéntala a fuego medio hasta que comience a humear. 2. Agrega 50g de avena poco a poco, removiendo constantemente. 3. Reduce a fuego bajo y sigue removiendo cada 30 segundos durante 6-7 minutos. 4. Vierte en un bol. 5. Distribuye las frutas del bosque. 6. Espolvorea almendras laminadas. 7. Añade canela molida. 8. Drizzle con miel. 9. Sirve inmediatamente.', 0),

(2, 'Pancakes de banana y avena', '🥞', 320, 9, 58, 6,
'["100g harina de avena","1 banana maduro","120ml leche de soja","1 cucharadita levadura","Pizca de sal","Aceite de coco"]',
'1. Tritura banana madura en bol. 2. Agrega harina de avena, levadura y sal. 3. Mezcla hasta combinar. 4. Vierte leche de soja poco a poco. 5. Deja reposar 2-3 minutos. 6. Calienta aceite de coco en sartén. 7. Vierte porciones de masa. 8. Cocina 2-3 minutos primer lado. 9. Voltea y cocina 2 minutos más. 10. Sirve caliente.', 0),

(3, 'Tostada de aguacate y tomate', '🥑', 310, 8, 35, 16,
'["1 rebanada pan integral","½ aguacate maduro","1 tomate mediano","½ limón","Sal y pimienta","Levadura nutricional (opcional)"]',
'1. Tuesta pan a nivel 3-4 durante 3-4 minutos. 2. Corta aguacate en mitades. 3. Extrae pulpa con cuchara. 4. Machaca en bol. 5. Exprime limón fresco. 6. Mezcla aguacate con limón. 7. Corta tomate en dados. 8. Extiende aguacate en pan. 9. Distribuye tomate. 10. Sazona con sal y pimienta. 11. Sirve inmediatamente.', 0),

(4, 'Smoothie bowl de açaí', '🫐', 340, 7, 58, 10,
'["100g pulpa de açaí congelada","150ml leche de coco","1 banana congelada","30g granola","30g coco rallado","50g frutas mixtas"]',
'1. Retira açaí del congelador. 2. Pela banana y congélala 2 horas. 3. Vierte leche de coco en licuadora. 4. Agrega açaí y banana congelada. 5. Licúa 45-60 segundos hasta sorbete. 6. Vierte en bol. 7. Distribuye granola. 8. Espolvorea coco. 9. Agrega frutas. 10. Sirve inmediatamente.', 0),

(5, 'Granola casera con frutos secos', '🥜', 290, 8, 38, 13,
'["150g copos de avena","50g almendras picadas","40g nueces","30g semillas girasol","30ml aceite de coco","30ml sirope de arce","Canela"]',
'1. Precalienta horno a 170°C. 2. Mezcla avena, almendras, nueces, semillas. 3. Calienta aceite y sirope. 4. Vierte sobre ingredientes secos. 5. Espolvorea canela. 6. Esparce en bandeja. 7. Hornea 20-25 minutos revolviendo a mitad. 8. Enfría completamente.', 0),

(6, 'Batido verde energizante', '🍌', 220, 5, 42, 4,
'["2 puñados de espinaca fresca","1 banana","200ml leche de almendra","50g piña","5g spirulina (opcional)","Cubitos de hielo"]',
'1. Agrega espinaca en licuadora. 2. Pica banana en trozos. 3. Añade piña cortada. 4. Vierte leche de almendra. 5. Agrega spirulina si deseas. 6. Añade hielo. 7. Licúa 60-90 segundos. 8. Sirve inmediatamente.', 0),

(7, 'Tortitas de espinaca y maíz', '🫓', 260, 7, 40, 8,
'["100g espinaca fresca picada","80g maíz","100g harina de maíz","120ml leche vegetal","1 cebolla pequeña","Sal y pimienta","Aceite vegetal"]',
'1. Saltea cebolla y espinaca en sartén. 2. Mezcla harina, leche, sal, pimienta. 3. Incorpora espinaca y maíz. 4. Calienta aceite en sartén. 5. Vierte porciones de masa. 6. Cocina 3-4 minutos cada lado. 7. Sirve caliente.', 0),

(8, 'Chia pudding de fresa', '🍓', 250, 6, 30, 12,
'["40g semillas de chia","200ml leche de almendra","100g fresas","10ml miel","Vainilla","Fresas para decorar"]',
'1. Mezcla semillas de chia con leche de almendra. 2. Agrega miel y vainilla. 3. Remueve bien. 4. Deja reposar 4 horas o toda noche en refrigerador. 5. Pica fresas. 6. Remueve pudding para uniformidad. 7. Vierte en vaso. 8. Cubre con fresas. 9. Sirve frío.', 0),

(9, 'Muffins de arándano veganos', '🥐', 195, 4, 32, 6,
'["200g harina integral","50g azúcar de coco","2 cucharaditas levadura","200ml leche de soja","40ml aceite vegetal","150g arándanos","Pizca de sal"]',
'1. Precalienta horno 180°C. 2. Mezcla harina, azúcar, levadura, sal. 3. Bate leche con aceite. 4. Une ingredientes secos y húmedos. 5. Agrega arándanos cuidadosamente. 6. Reparte en moldes. 7. Hornea 20-22 minutos. 8. Enfría 5 minutos.', 0),

(10, 'Porridge de zanahoria y canela', '🥕', 310, 9, 52, 7,
'["50g avena integral","200ml leche de soja sin azúcar","80g zanahoria fresca","5ml miel pura","2g canela molida","30g nueces picadas","Sal"]',
'1. Pela zanahoria y ralla finamente. 2. Vierte leche en olla y calienta hasta vapor. 3. Agrega avena integral. 4. Reduce fuego bajo. 5. Cocina 5-7 minutos removiendo. 6. A los 3-4 minutos agrega zanahoria rallada. 7. Continúa cocinando otros 2-3 minutos. 8. Vierte en bol. 9. Espolvorea canela. 10. Drizzle miel. 11. Distribuye nueces. 12. Sirve caliente.', 0),

(11, 'Parfait de frutas y yogur de coco', '🍇', 280, 5, 42, 10,
'["200g yogur de coco","80g granola","100g frutas mixtas","30ml sirope de arce","15g coco rallado"]',
'1. Prepara vaso o bol. 2. Vierte capa de yogur. 3. Añade granola. 4. Agrega frutas picadas. 5. Repite capas. 6. Termina con yogur. 7. Rocía sirope. 8. Espolvorea coco. 9. Sirve inmediatamente.', 0),

(12, 'Arepas veganas rellenas', '🌽', 350, 12, 55, 10,
'["200g harina de maíz","500ml agua","1 aguacate","1 tomate","50g lechuga","Sal y aceite"]',
'1. Mezcla harina con agua tibia y sal. 2. Deja reposar 5 minutos. 3. Forma bolas y aplasta. 4. Cocina en sartén 5 minutos cada lado. 5. Abre por la mitad. 6. Machaca aguacate. 7. Arma relleno con aguacate, tomate, lechuga. 8. Rellena arepas.', 0),

(13, 'Tofu revuelto con verduras', '🫘', 280, 18, 12, 16,
'["200g tofu firme","100g cebolla","150g champiñones","100g espinaca","50ml leche vegetal","Cúrcuma, sal","Aceite de oliva"]',
'1. Desmorona tofu con dedos. 2. Pica cebolla, champiñones, espinaca. 3. Calienta aceite en sartén. 4. Saltea cebolla y champiñones. 5. Agrega tofu desmenuzado. 6. Añade espinaca. 7. Espolvorea cúrcuma. 8. Vierte leche vegetal. 9. Saltea 5-7 minutos. 10. Sirve caliente.', 0),

(14, 'Smoothie tropical de mango', '🥭', 240, 3, 48, 5,
'["200g mango congelado","150ml leche de coco","50g piña","1 banana","5ml néctar de agave","Cubitos de hielo"]',
'1. Corta mango congelado en trozos. 2. Pica piña y banana. 3. Coloca todo en licuadora. 4. Vierte leche de coco. 5. Agrega néctar de agave. 6. Añade hielo. 7. Licúa hasta consistencia suave. 8. Sirve inmediatamente.', 0),

(15, 'Avena horneada con manzana', '🫕', 330, 8, 56, 9,
'["150g copos de avena","200ml leche de almendra","1 manzana grande","30ml sirope de arce","30g nueces","2g canela"]',
'1. Precalienta horno 175°C. 2. Mezcla avena, leche, sirope. 3. Pela manzana, corta en dados. 4. Incorpora manzana y canela. 5. Vierte en bandeja. 6. Espolvorea nueces. 7. Hornea 25-30 minutos. 8. Sirve caliente.', 0),

(16, 'French toast vegano', '🍞', 340, 9, 48, 12,
'["4 rebanadas pan","200ml leche de soja","1 banana","5ml vainilla","2g canela","Aceite de coco"]',
'1. Licúa leche, banana, vainilla, canela. 2. Vierte en plato hondo. 3. Calienta aceite en sartén. 4. Sumerge pan 2 segundos por lado. 5. Cocina 2-3 minutos cada lado. 6. Sirve con frutas y jarabe.', 0),

(17, 'Bowl verde de quinoa', '🥒', 420, 16, 52, 16,
'["100g quinoa cocida","100g espinaca","1 aguacate","100g pepino","50g germinados","Limón","Aceite de oliva"]',
'1. Cocina quinoa. 2. Coloca en bol. 3. Agrega espinaca picada. 4. Corta aguacate en láminas. 5. Pica pepino. 6. Distribuye sobre quinoa. 7. Espolvorea germinados. 8. Aliña con limón y aceite. 9. Mezcla suavemente.', 0),

(18, 'Bowl de açaí tropical', '🥝', 300, 6, 50, 10,
'["100g pulpa açaí","150ml leche de coco","1 banana congelada","50g kiwi","30g coco","30g granola"]',
'1. Mezcla pulpa açaí con leche de coco. 2. Licúa con banana congelada hasta sorbete. 3. Vierte en bol. 4. Pela kiwi en rodajas finas. 5. Distribuye en superficie. 6. Agrega granola. 7. Espolvorea coco. 8. Decora con banana. 9. Sirve inmediatamente.', 0),

(19, 'Ramen de miso con tofu crujiente', '🍜', 520, 28, 65, 14,
'["150g fideos ramen","200ml caldo vegetal","30ml pasta miso","150g tofu firme","100g bok choy","30g alga nori","Cebollitas verdes","Aceite de sésamo"]',
'TOFU: 1. Envuelve tofu en papel absorbente. 2. Presiona 10 minutos. 3. Corta en cubos 1.5cm. 4. Calienta aceite a fuego medio-alto. 5. Cocina tofu 3-4 min primer lado sin mover. 6. Voltea y cocina 3 min más. CALDO: 7. Hierve agua, cocina fideos 3-4 min, cuela. MISO: 8. Calienta caldo (NO hierva). 9. Disuelve miso en agua reservada. 10. Vierte en caldo, apaga fuego (preserva probióticos). VEGETALES: 11. Saltea bok choy 2-3 minutos. ARMADO: 12. Coloca fideos en bol. 13. Vierte caldo. 14. Distribuye bok choy. 15. Agrega tofu frito. 16. Coloca alga nori. 17. Espolvorea cebollitas. 18. Rocía aceite sésamo. 19. Sirve caliente.', 0),

(20, 'Tacos de jackfruit al pastor', '🌮', 380, 8, 62, 10,
'["200g jackfruit enlatado","1 cebolla mediana","2 tomates medianos","50g cilantro fresco","6 tortillas maíz","½ limón","Especias: comino, achiote, sal"]',
'JACKFRUIT: 1. Cuela jackfruit enlatado. 2. Deshebra con dos tenedores (como carne). 3. Seca bien. MARINADA: 4. Mezcla comino, achiote, sal, pimienta. 5. Impregna jackfruit. COCCION: 6. Calienta aceite a fuego medio-alto. 7. Cocina jackfruit 8-10 minutos hasta dorado. VEGETALES: 8. Pela cebolla en rodajas. 9. Corta tomate en dados. 10. Pica cilantro. ARMADO: 11. Calienta tortillas. 12. Coloca jackfruit marinado. 13. Agrega cebolla y tomate. 14. Espolvorea cilantro. 15. Exprime limón. 16. Sirve inmediatamente.', 0),

(21, 'Buddha bowl mediterráneo', '🥗', 560, 24, 72, 18,
'["150g garbanzos cocidos","100g quinoa","100g lechuga","50g tomate cherry","50g pepino","40g aceitunas","50g hummus","30ml aceite de oliva"]',
'1. Cocina quinoa. 2. Asa garbanzos 20 minutos a 200°C. 3. Pica vegetales. 4. Distribuye quinoa en bol. 5. Agrega lechuga, tomate, pepino. 6. Coloca garbanzos. 7. Añade aceitunas. 8. Sirve con hummus. 9. Aliña con aceite.', 0),

(22, 'Dahl de lentejas rojas', '🍛', 380, 20, 58, 6,
'["200g lentejas rojas","1 cebolla mediana","2 dientes ajo","1 tomate mediano","200ml leche de coco","10g jengibre fresco","5g cúrcuma molida","3g comino molido","700ml agua o caldo"]',
'1. Enjuaga lentejas, remoja 15 minutos. 2. Pica cebolla, ajo, jengibre. 3. Calienta aceite a fuego medio. 4. Saltea cebolla 3-4 minutos. 5. Agrega ajo 1 minuto. 6. Añade jengibre. 7. Espolvorea cúrcuma y comino. 8. Remueve 30 segundos (tuéstalas). 9. Vierte lentejas. 10. Cubre con agua o caldo. 11. Agrega tomate dados. 12. Lleva a hervor, reduce fuego. 13. Cocina 20-25 minutos hasta lentejas blandas. 14. Vierte leche de coco. 15. Cocina 5 minutos más. 16. Sazona. 17. Sirve caliente.', 0),

(23, 'Wrap de hummus y vegetales', '🥙', 380, 14, 48, 14,
'["2 tortillas integrales","100g hummus","100g verduras (lechuga, tomate, pepino)","50g germinados","30g zanahorias ralladas","Tahini"]',
'1. Calienta tortillas. 2. Extiende hummus generosamente. 3. Agrega lechuga, tomate, pepino picados. 4. Añade germinados y zanahorias. 5. Rocía tahini. 6. Enrolla apretadamente. 7. Corta por la mitad. 8. Sirve.', 0),

(24, 'Sopa de calabaza y jengibre', '🍲', 220, 4, 38, 7,
'["400g calabaza","1 cebolla","3g jengibre","500ml caldo vegetal","100ml leche de coco","Sal y pimienta"]',
'1. Pica calabaza, cebolla, jengibre. 2. Saltea cebolla y jengibre. 3. Agrega calabaza. 4. Vierte caldo. 5. Cocina 20 minutos. 6. Licúa hasta crema. 7. Agrega leche de coco. 8. Sazona. 9. Sirve caliente.', 0),

(25, 'Arroz frito vegano con tofu', '🍚', 420, 16, 62, 12,
'["200g arroz cocido (día anterior)","150g tofu firme","100g verduras mixtas","30ml salsa soja","50g cebollitas","Aceite vegetal","Ajo"]',
'1. Corta tofu en cubos y fríe. 2. Calienta aceite, agrega ajo. 3. Añade verduras, saltea 3 minutos. 4. Agrega arroz desmenuzado. 5. Vierte salsa soja. 6. Incorpora tofu. 7. Mezcla bien. 8. Cocina 5 minutos. 9. Decora con cebollitas. 10. Sirve caliente.', 0),

(26, 'Pimientos rellenos de quinoa', '🫑', 340, 14, 52, 8,
'["3 pimientos","150g quinoa cocida","80g garbanzos","50g tomate","30g cebolla","Hierbas: perejil, orégano"]',
'1. Corta pimientos por la mitad, retira semillas. 2. Sofríe cebolla, tomate. 3. Mezcla con quinoa y garbanzos. 4. Agrega hierbas. 5. Rellena pimientos. 6. Coloca en bandeja. 7. Rocía aceite. 8. Hornea 25 minutos a 200°C. 9. Sirve.', 0),

(27, 'Pizza vegana con vegetales', '🍕', 380, 12, 52, 14,
'["1 base pizza integral","100ml salsa de tomate","100g queso vegano","200g vegetales variados","30ml aceite de oliva"]',
'1. Precalienta 220°C. 2. Extiende salsa. 3. Distribuye queso vegano. 4. Agrega vegetales cortados. 5. Rocía aceite. 6. Hornea 12-15 minutos. 7. Sirve caliente.', 0),

(28, 'Curry de garbanzos y espinaca', '🥘', 360, 16, 48, 12,
'["250g garbanzos","200g espinaca fresca","200ml leche de coco","1 cebolla","3g curry","2g cúrcuma","Ajo"]',
'1. Saltea cebolla y ajo. 2. Agrega curry y cúrcuma. 3. Incorpora garbanzos. 4. Vierte leche de coco. 5. Cocina 10 minutos. 6. Agrega espinaca. 7. Cocina 5 minutos. 8. Sirve con arroz.', 0),

(29, 'Burrito bowl de frijoles', '🌯', 480, 18, 68, 14,
'["150g arroz","200g frijoles negros","100g maíz","50g salsa","100g lechuga","50g tomate","30g cebolla","Limón"]',
'1. Cocina arroz. 2. Calienta frijoles con comino. 3. Distribuye arroz. 4. Agrega frijoles, maíz. 5. Añade lechuga, tomate. 6. Rodea con salsa. 7. Decora con cebolla y cilantro. 8. Exprime limón. 9. Sirve inmediatamente.', 0),

(30, 'Salteado de brócoli y sésamo', '🥦', 220, 10, 22, 10,
'["300g brócoli","30g semillas sésamo","30ml salsa soja","3g ajo","5ml aceite sésamo","Jengibre"]',
'1. Corta brócoli en floretes. 2. Calienta aceite en wok. 3. Agrega ajo y jengibre. 4. Añade brócoli, saltea 5 minutos. 5. Vierte salsa soja. 6. Cocina 3 minutos. 7. Espolvorea semillas. 8. Rocía aceite sésamo. 9. Sirve caliente.', 0),

(31, 'Pasta primavera vegana', '🍝', 420, 12, 62, 14,
'["200g pasta integral","200g vegetales variados","100ml nata vegetal","50g champiñones","30g cebolla","Ajo, perejil"]',
'1. Cocina pasta según instrucciones. 2. Saltea cebolla, ajo, champiñones. 3. Agrega vegetales. 4. Vierte nata vegetal. 5. Sazona. 6. Cuela pasta y mezcla. 7. Cocina 2 minutos. 8. Decora con perejil. 9. Sirve inmediatamente.', 0),

(32, 'Ensalada César vegana', '🥬', 320, 10, 28, 18,
'["200g lechuga romana","100g crutones","50g queso vegano","Salsa César vegana (100ml)"]',
'1. Prepara salsa: tahini, ajo, limón, mostaza, agua. 2. Pica lechuga. 3. Distribuye en bol. 4. Agrega crutones. 5. Rocía salsa. 6. Espolvorea queso. 7. Mezcla. 8. Sirve inmediatamente.', 0),

(33, 'Berenjenas a la parmesana vegana', '🍆', 380, 12, 42, 18,
'["300g berenjena","300ml salsa tomate","150g queso vegano","100ml leche vegetal","50g harina","Aceite","Orégano"]',
'1. Corta berenjena en rodajas. 2. Pásalas por harina y fríe. 3. Precalienta 200°C. 4. Capas: salsa, berenjena, queso. 5. Repite. 6. Termina con queso. 7. Hornea 25 minutos. 8. Sirve con ensalada.', 0),

(34, 'Sopa de zanahoria y coco', '🥕', 200, 4, 30, 8,
'["400g zanahoria","200ml leche de coco","500ml caldo vegetal","1 cebolla","Jengibre","Sal"]',
'1. Pica cebolla y zanahoria. 2. Saltea cebolla. 3. Agrega zanahoria y jengibre. 4. Vierte caldo. 5. Cocina 20 minutos. 6. Licúa suavemente. 7. Agrega leche de coco. 8. Calienta 5 minutos. 9. Sirve.', 0),

(35, 'Tamales veganos de rajas', '🫔', 320, 8, 48, 12,
'["200g masa de maíz","100g rajas poblanas","50g frijoles","Hojas de maíz","Caldo vegetal"]',
'1. Remoja hojas de maíz. 2. Prepara masa. 3. Corta rajas. 4. Coloca hoja, extiende masa. 5. Agrega rajas. 6. Envuelve. 7. Cocina vapor 45 minutos. 8. Sirve.', 0),

(36, 'Quiche vegano de espinaca', '🥧', 280, 14, 28, 12,
'["1 base pie integral","200g espinaca","200ml leche de soja","100g tofu sedoso","50g nueces","Sal, pimienta"]',
'1. Precalienta 190°C. 2. Coloca base en molde. 3. Saltea espinaca. 4. Licúa tofu con leche. 5. Mezcla con espinaca. 6. Vierte sobre base. 7. Esparce nueces. 8. Hornea 30 minutos. 9. Sirve templado.', 0),

(37, 'Pasta al pesto de espinaca', '🍝', 520, 16, 70, 20,
'["250g pasta integral","200g espinaca fresca","50g piñones tostados","30g ajo","100ml aceite de oliva virgen","50g levadura nutricional","Sal y pimienta"]',
'PASTA: 1. Hierve agua con sal. 2. Cocina pasta al dente 10-12 minutos. 3. Reserva agua cocción. PESTO: 4. Lava espinaca. 5. Coloca en licuadora. 6. Agrega piñones, ajo, aceite, levadura nutricional. 7. Licúa 30-45 segundos hasta textura gruesa. 8. Sazona. FINAL: 9. Cuela pasta. 10. Mezcla con pesto. 11. Si espeso, agrega agua cocción. 12. Sirve inmediatamente.', 0),

(38, 'Curry verde thai con tofu', '🫕', 445, 19, 38, 22,
'["200g tofu firme","200ml leche de coco","50ml pasta curry verde","100g bok choy","100g champiñones","Cilantro","Limón"]',
'1. Corta tofu, saltea hasta dorar. 2. Calienta pasta curry. 3. Vierte leche de coco. 4. Añade bok choy, champiñones. 5. Cocina 10 minutos. 6. Incorpora tofu. 7. Cocina 5 minutos. 8. Decora con cilantro. 9. Exprime limón.', 0),

(39, 'Estofado de lentejas y vegetales', '🍲', 360, 18, 56, 6,
'["200g lentejas","200g zanahoria","150g papa","100g cebolla","700ml caldo vegetal","Hierbas de provenza"]',
'1. Enjuaga lentejas. 2. Pica cebolla, zanahoria, papa. 3. Saltea cebolla. 4. Agrega zanahoria, papa. 5. Vierte caldo y lentejas. 6. Añade hierbas. 7. Cocina 35-40 minutos. 8. Sazona. 9. Sirve en platos hondos.', 0),

(40, 'Chili sin carne', '🌶️', 320, 16, 52, 6,
'["400g frijoles","200g tomate enlatado","1 cebolla","150g pimiento","30g salsa picante","Comino, chili en polvo"]',
'1. Saltea cebolla. 2. Agrega pimiento. 3. Vierte tomate. 4. Incorpora frijoles. 5. Sazona con comino, chili. 6. Agrega salsa picante. 7. Cocina 25-30 minutos. 8. Sirve con cilantro.', 0),

(41, 'Gyozas veganas de verduras', '🥟', 280, 8, 42, 8,
'["20 envoltorios wonton","150g repollo","100g zanahoria","50g champiñones","30ml salsa soja","Aceite vegetal","Ajo"]',
'1. Pica repollo, zanahoria, champiñones. 2. Saltea con ajo. 3. Coloca relleno en envoltorio. 4. Humedece bordes. 5. Dobla y sella. 6. Fríe 2-3 minutos por lado. 7. Sirve con salsa soja.', 0),

(42, 'Tikka masala de coliflor', '🍛', 320, 10, 38, 14,
'["300g coliflor","200ml leche de coco","100ml salsa tomate","30g pasta tikka","1 cebolla","Cilantro"]',
'1. Corta coliflor en floretes. 2. Asa 20 minutos a 200°C. 3. Saltea cebolla. 4. Agrega pasta tikka. 5. Vierte salsa, leche. 6. Mezcla bien. 7. Incorpora coliflor. 8. Cocina 10 minutos. 9. Decora con cilantro. 10. Sirve con arroz.', 0),

(43, 'Tagine marroquí de garbanzos', '🥘', 390, 14, 58, 12,
'["300g garbanzos","150g dátiles","100g cebolla","50g almendras","5g canela","Agua de azahar"]',
'1. Saltea cebolla. 2. Agrega garbanzos. 3. Añade dátiles picados. 4. Vierte agua. 5. Sazona con canela. 6. Cocina 20 minutos. 7. Agrega almendras. 8. Rocía agua de azahar. 9. Sirve con cuscús.', 0),

(44, 'Hamburguesas de frijol negro', '🫘', 340, 16, 48, 10,
'["250g frijoles negros cocidos","50g pan integral rallado","30g cebolla","30ml salsa de soja","2g comino molido","2g pimienta negra","Aceite vegetal"]',
'MASA: 1. Cuela frijoles bien. 2. Tritura con tenedor hasta puré. 3. Mezcla con pan rallado, cebolla, comino, pimienta. 4. Vierte salsa soja. 5. Mezcla enérgicamente. FORMACIÓN: 6. Forma 4 discos redondos. 7. Presiona firmemente. CONGELACIÓN: 8. Congela 30 minutos. COCCIÓN: 9. Calienta aceite a fuego medio-alto. 10. Cocina sin mover 4-5 minutos primer lado. 11. Voltea, cocina 4-5 minutos más. 12. ARMADO: Coloca en pan con lechuga, tomate, mayonesa. 13. Sirve caliente.', 0),

(45, 'Pad thai vegano', '🍜', 480, 18, 62, 16,
'["200g fideos arroz","200g vegetales mixtos","100g tofu","50g cacahuetes","30ml salsa soja","Limón","Cilantro"]',
'1. Cocina fideos. 2. Fríe tofu en cubos. 3. Saltea vegetales. 4. Mezcla fideos y vegetales. 5. Agrega salsa soja. 6. Esparce cacahuetes triturados. 7. Exprime limón. 8. Decora con cilantro. 9. Sirve inmediatamente.', 0),

(46, 'Bowl de batata asada y tahini', '🥗', 420, 14, 58, 16,
'["300g batata","150g garbanzos","100g lechuga","50g tahini","Limón","Cebollitas verdes"]',
'1. Corta batata en tiras. 2. Asa con aceite a 200°C 25 minutos. 3. Asa garbanzos también. 4. Distribuye lechuga. 5. Agrega batata y garbanzos. 6. Prepara aliño: tahini + limón + agua. 7. Rocía aliño. 8. Decora con cebollitas. 9. Sirve.', 0),

(47, 'Pizza de masa de coliflor', '🍕', 320, 12, 36, 14,
'["400g coliflor","50g harina","80g levadura","100ml salsa tomate","100g queso vegano","Vegetales variados"]',
'1. Licúa coliflor cruda. 2. Exprime bien agua. 3. Mezcla con harina y levadura. 4. Forma base. 5. Hornea 25 minutos a 200°C. 6. Extiende salsa. 7. Agrega queso y vegetales. 8. Hornea 10 minutos. 9. Sirve.', 0),

(48, 'Polenta cremosa con setas', '🌽', 380, 10, 52, 14,
'["100g polenta","400ml caldo vegetal","200g champiñones","100ml leche vegetal","30g levadura nutricional","Ajo"]',
'1. Hierve caldo. 2. Agrega polenta lentamente. 3. Cocina 30 minutos. 4. Saltea champiñones con ajo. 5. Agrega leche vegetal. 6. Incorpora levadura. 7. Mezcla con champiñones. 8. Sirve en platos hondos.', 0),

(49, 'Shepherd\'s pie vegano', '🥕', 380, 16, 56, 10,
'["500g papa","150g lentejas","100g zanahoria","100g cebolla","200ml caldo vegetal","50ml leche vegetal"]',
'1. Cocina papa, machaca. 2. Saltea cebolla, zanahoria. 3. Agrega lentejas cocidas. 4. Vierte caldo. 5. Cocina 15 minutos. 6. Coloca en bandeja. 7. Cubre con puré. 8. Hornea 20 minutos a 200°C. 9. Sirve.', 0),

(50, 'Naan con curry de verduras', '🫓', 440, 12, 62, 16,
'["300g harina integral","200ml agua tibia","7g levadura","300g vegetales","50ml salsa curry","Aceite"]',
'1. Mezcla harina, agua, levadura. 2. Deja reposar 1 hora. 3. Divide en bolitas, estira. 4. Cocina en sartén. 5. Saltea vegetales. 6. Agrega salsa curry. 7. Cocina 15 minutos. 8. Sirve naan con curry.', 0),

(51, 'Lasaña vegana de berenjena', '🍆', 380, 18, 42, 16,
'["400g berenjena","300ml salsa tomate","200g tofu ricotta","100g espinaca","Orégano"]',
'1. Corta berenjena en rodajas. 2. Prepara ricotta: tofu + levadura + agua. 3. Precalienta 190°C. 4. Capas alternadas. 5. Termina con salsa. 6. Hornea 30 minutos. 7. Deja reposar 10 minutos. 8. Sirve.', 0),

(52, 'Fideos con salsa de cacahuete', '🥜', 460, 16, 58, 18,
'["200g fideos arroz","100g cacahuete","30ml salsa soja","1 zanahoria","100g brócoli","Limón"]',
'1. Cocina fideos. 2. Prepara salsa: cacahuete + agua + soja + limón. 3. Saltea zanahoria, brócoli. 4. Mezcla fideos, vegetales. 5. Vierte salsa. 6. Mezcla bien. 7. Decora con cilantro. 8. Sirve.', 0),

(53, 'Fajitas veganas de portobello', '🫑', 340, 10, 42, 14,
'["300g champiñones portobello","1 cebolla","2 pimientos","6 tortillas","Especias fajita","Guacamole"]',
'1. Corta portobellos en tiras. 2. Corta cebolla, pimientos. 3. Saltea con especias. 4. Cocina 8 minutos. 5. Calienta tortillas. 6. Rellena con vegetales. 7. Agrega guacamole. 8. Sirve.', 0),

(54, 'Risotto de champiñones', '🥣', 420, 10, 62, 14,
'["200g arroz arborio","300g champiñones","800ml caldo vegetal","100ml vino blanco","1 cebolla","Levadura nutricional"]',
'1. Saltea cebolla. 2. Agrega champiñones. 3. Incorpora arroz. 4. Vierte vino. 5. Agrega caldo lentamente. 6. Cocina 18 minutos removiendo. 7. Agrega levadura. 8. Sirve cremoso.', 0),

(55, 'Falafel horneado con tzatziki', '🧆', 285, 14, 38, 8,
'["200g garbanzos cocidos","50g cebolla mediana","30g perejil fresco","15g harina de garbanzo","5g comino molido","2g sal","Aceite vegetal en spray"]',
'FALAFEL: 1. Cuela garbanzos bien. 2. Procesa con cebolla, perejil. 3. Agrega comino, sal. 4. Procesa 45-60 segundos. 5. Agrega harina. 6. Refrigera 30 minutos. 7. Precalienta 200°C. 8. Forma bolitas. 9. Rocía aceite. 10. Hornea 25-28 minutos. TZATZIKI: 11. Ralla pepino, drena agua. 12. Mezcla con yogur, ajo, limón, sal. 13. Sirve frío.', 0),

(56, 'Barritas energéticas de dátiles', '🥜', 180, 5, 28, 7,
'["150g dátiles","100g almendras","50g coco","30ml aceite coco"]',
'1. Licúa dátiles. 2. Pica almendras. 3. Mezcla todos ingredientes. 4. Presiona en molde. 5. Refrigera 2 horas. 6. Corta en barras.', 0),

(57, 'Hummus clásico con crudités', '🥕', 180, 8, 22, 7,
'["200g garbanzos","50ml tahini","30ml limón","2g ajo","Crudités variadas"]',
'1. Licúa garbanzos, tahini, limón, ajo. 2. Agrega agua para consistencia. 3. Pica vegetales crudos. 4. Sirve hummus central. 5. Rodea con crudités.', 0),

(58, 'Palomitas con levadura nutricional', '🍿', 150, 5, 22, 5,
'["50g maíz","30ml aceite coco","30g levadura nutricional","Sal"]',
'1. Calienta aceite en olla con tapa. 2. Agrega maíz. 3. Cuando deja de sonar, retira. 4. Vierte en bol. 5. Espolvorea levadura y sal. 6. Mezcla. 7. Sirve.', 0),

(59, 'Rollitos de pepino con hummus', '🥒', 120, 5, 14, 5,
'["2 pepinos","100ml hummus","30g zanahoria","Eneldo"]',
'1. Corta pepino en tiras. 2. Extiende hummus. 3. Agrega zanahoria. 4. Enrolla. 5. Sujeta con palillos. 6. Refrigera. 7. Decora con eneldo.', 0),

(60, 'Edamame con sal de mar', '🫘', 190, 17, 8, 8,
'["200g edamame","Agua","Sal de mar"]',
'1. Hierve agua. 2. Agrega edamame. 3. Cocina 5-7 minutos. 4. Cuela. 5. Espolvorea sal. 6. Sirve caliente.', 0),

(61, 'Chips de batata al horno', '🍠', 160, 2, 30, 4,
'["300g batata","30ml aceite","Sal, pimienta"]',
'1. Corta batata en rodajas. 2. Coloca en bandeja. 3. Rocía aceite. 4. Sazona. 5. Hornea 200°C 25-30 minutos. 6. Sirve crujiente.', 0),

(62, 'Guacamole con totopos', '🥑', 220, 3, 18, 16,
'["2 aguacates","1 limón","1 cebolla","1 tomate","Cilantro","Totopos"]',
'1. Corta aguacates. 2. Extrae pulpa. 3. Machaca con tenedor. 4. Mezcla con limón, cebolla, tomate. 5. Agrega cilantro. 6. Sirve con totopos.', 0),

(63, 'Mix de frutos secos especiados', '🌰', 200, 6, 10, 16,
'["50g almendras","50g nueces","30g anacardos","20g especias","Sal"]',
'1. Mezcla frutos secos. 2. Calienta en sartén 3 minutos. 3. Espolvorea sal y especias. 4. Revuelve. 5. Enfría. 6. Sirve.', 0),

(64, 'Bruschetta de tomate', '🍅', 160, 4, 24, 5,
'["4 tostadas","3 tomates","30ml aceite de oliva","Ajo","Albahaca"]',
'1. Tuesta pan. 2. Frota con ajo. 3. Pica tomate. 4. Mezcla con aceite, sal, pimienta. 5. Coloca sobre tostadas. 6. Decora con albahaca.', 0),

(65, 'Pretzels suaves veganos', '🥨', 220, 6, 42, 3,
'["300g harina","150ml agua","7g levadura","Bicarbonato","Sal gruesa"]',
'1. Prepara masa. 2. Deja reposar 1 hora. 3. Divide, forma pretzel. 4. Sumerge en agua + bicarbonato. 5. Coloca en bandeja. 6. Espolvorea sal. 7. Hornea 15 minutos a 200°C.', 0),

(66, 'Chips de kale crujientes', '🥬', 110, 4, 10, 6,
'["150g kale","30ml aceite","Sal"]',
'1. Retira tallo. 2. Seca bien. 3. Rocía aceite. 4. Sazona. 5. Hornea 190°C 12-15 minutos. 6. Sirve.', 0),

(67, 'Crackers de semillas', '🫓', 140, 5, 12, 8,
'["100g semillas","50ml aceite","100ml agua","Sal"]',
'1. Mezcla ingredientes. 2. Extiende en bandeja. 3. Hornea 30 minutos a 180°C. 4. Corta. 5. Sirve.', 0),

(68, 'Banana con mantequilla de maní', '🍌', 260, 8, 32, 12,
'["2 bananas","30g mantequilla de maní"]',
'1. Pela bananas. 2. Corta en rodajas. 3. Extiende mantequilla. 4. Combina o sirve. 5. Consume inmediatamente.', 0),

(69, 'Dip de queso vegano con nachos', '🧀', 240, 6, 24, 14,
'["150g queso vegano","50ml leche vegetal","30g jalapeño","Tortillas"]',
'1. Calienta queso con leche. 2. Agrega jalapeño. 3. Mezcla. 4. Calienta tortillas. 5. Corta. 6. Fríe. 7. Sirve.', 0),

(70, 'Rollitos de arroz con mango', '🥭', 160, 3, 28, 4,
'["8 envoltorios arroz","1 mango","50g lechuga","30g cacahuete"]',
'1. Humedece envoltorios. 2. Coloca lechuga, mango. 3. Enrolla. 4. Sirve con salsa cacahuete.', 0),

(71, 'Tapenade de aceitunas', '🫒', 150, 2, 8, 12,
'["150g aceitunas","30ml aceite de oliva","1 limón","Ajo"]',
'1. Licúa aceitunas. 2. Agrega aceite, ajo. 3. Exprime limón. 4. Mezcla. 5. Sirve con pan.', 0),

(72, 'Mousse de chocolate y aguacate', '🍫', 290, 4, 28, 19,
'["1 aguacate mediano maduro","100g chocolate negro (70% cacao)","50ml leche de coco","10ml miel o sirope de arce","2ml extracto de vainilla pura","Cacao en polvo sin azúcar"]',
'1. Derrite chocolate a 50% potencia microondas 1 minuto. 2. Corta aguacate, extrae pulpa. 3. Procesa con chocolate, leche de coco, miel, vainilla. 4. Licúa 30-45 segundos. 5. Cuela opcionalmente. 6. Vierte en copas. 7. Refrigera 30 minutos congelador. 8. Espolvorea cacao. 9. Sirve frío.', 0),

(73, 'Galletas de avena y chocolate', '🍪', 160, 3, 22, 7,
'["150g avena","100g harina","50g chocolate","50ml aceite","30ml sirope"]',
'1. Precalienta 180°C. 2. Mezcla avena, harina, chocolate picado. 3. Agrega aceite, sirope. 4. Forma bolas. 5. Aplasta. 6. Hornea 12 minutos.', 0),

(74, 'Nice cream de banana', '🍌', 180, 2, 42, 1,
'["2 bananas congeladas","30ml leche almendra","5ml vainilla"]',
'1. Corta bananas congeladas. 2. Licúa con leche, vainilla. 3. Sirve inmediatamente.', 0),

(75, 'Tarta de manzana vegana', '🥧', 280, 3, 42, 12,
'["1 masa pie","4 manzanas","50g azúcar coco","2g canela","30ml aceite"]',
'1. Precalienta 190°C. 2. Coloca masa. 3. Pela manzanas. 4. Mezcla con azúcar, canela. 5. Coloca. 6. Hornea 35 minutos.', 0),

(76, 'Panna cotta de coco y mango', '🍮', 240, 2, 28, 14,
'["300ml leche coco","50g azúcar","15g agar agar","100g mango"]',
'1. Calienta leche con azúcar. 2. Agrega agar agar. 3. Vierte en moldes. 4. Refrigera 2 horas. 5. Desmolda. 6. Sirve con puré mango.', 0),

(77, 'Cupcakes de vainilla veganos', '🧁', 220, 3, 32, 9,
'["150g harina","100ml leche soja","50ml aceite","50g azúcar","5g levadura","Vainilla"]',
'1. Precalienta 180°C. 2. Mezcla ingredientes. 3. Reparte en moldes. 4. Hornea 18 minutos. 5. Enfría. 6. Decora.', 0),

(78, 'Cheesecake vegano de arándanos', '🫐', 320, 6, 28, 22,
'["200g galletas","150g tofu sedoso","100g queso coco","50g arándanos","30ml aceite"]',
'1. Precalienta 175°C. 2. Mezcla galletas, aceite. 3. Presiona como base. 4. Licúa tofu, queso. 5. Vierte. 6. Hornea 30 minutos. 7. Refrigera 4 horas. 8. Decora.', 0),

(79, 'Brownies veganos de chocolate', '🍫', 250, 4, 32, 13,
'["200g harina","100g chocolate","100ml aceite","50ml leche soja","100g azúcar","5g levadura"]',
'1. Precalienta 180°C. 2. Derrite chocolate. 3. Mezcla con aceite, leche, azúcar. 4. Agrega harina, levadura. 5. Vierte. 6. Hornea 20 minutos. 7. Corta.', 0),

(80, 'Fresas con chocolate fundido', '🍓', 180, 2, 24, 10,
'["200g fresas","100g chocolate negro","30ml aceite coco"]',
'1. Derrite chocolate con aceite. 2. Pela fresas manteniendo verde. 3. Sumerge en chocolate. 4. Coloca en pergamino. 5. Refrigera 30 minutos. 6. Sirve.', 0),

(81, 'Bolitas de coco y limón', '🥥', 120, 2, 14, 7,
'["150g coco rallado","50ml leche coco","30ml limón","30g chocolate negro"]',
'1. Mezcla coco, leche, limón. 2. Forma bolitas. 3. Refrigera 1 hora. 4. Derrite chocolate. 5. Sumerge. 6. Refrigera.', 0),

(82, 'Pastel de zanahoria vegano', '🎂', 310, 5, 42, 14,
'["200g zanahoria rallada","200g harina","100ml aceite","100g azúcar","100ml leche soja","7g levadura"]',
'1. Precalienta 180°C. 2. Mezcla ingredientes. 3. Vierte en molde. 4. Hornea 35 minutos. 5. Enfría. 6. Decora.', 0),

(83, 'Helado de mango y coco', '🍨', 210, 2, 34, 8,
'["200g mango","150ml leche coco","30ml sirope","Vainilla"]',
'1. Licúa mango, leche, sirope, vainilla. 2. Vierte en congelador. 3. Remueve cada 30 minutos 2-3 horas. 4. O usa heladera.', 0),

(84, 'Donas veganas glaseadas', '🍩', 240, 4, 36, 9,
'["200g harina","100ml leche soja","50ml aceite","50g azúcar","Glaseado vegano"]',
'1. Precalienta 180°C. 2. Mezcla ingredientes. 3. Vierte en moldes. 4. Hornea 12 minutos. 5. Enfría. 6. Glasa.', 0),

(85, 'Crumble de frutas del bosque', '🫐', 260, 4, 40, 10,
'["300g frutas mixtas","100g avena","50g harina","50ml aceite","30g azúcar"]',
'1. Precalienta 190°C. 2. Coloca frutas. 3. Mezcla avena, harina, aceite, azúcar. 4. Esparce. 5. Hornea 25 minutos.', 0),

(86, 'Tarta de limón vegana', '🍋', 270, 3, 36, 13,
'["1 masa pie","150ml jugo limón","100g azúcar","50ml aceite","50g harina maíz"]',
'1. Precalienta 180°C. 2. Coloca masa. 3. Mezcla limón, azúcar, aceite, harina. 4. Vierte. 5. Hornea 30 minutos.', 0),

(87, 'Compota de frutas con granola', '🍑', 220, 4, 38, 6,
'["300g frutas variadas","30ml agua","15g sirope","50g granola"]',
'1. Pica frutas. 2. Cocina en sartén con agua. 3. Agrega sirope. 4. Cocina 15 minutos. 5. Sirve. 6. Corona con granola.', 0),

(88, 'Trufas de chocolate y maní', '🥜', 140, 3, 14, 9,
'["100g chocolate","50g mantequilla maní","30g coco rallado","Cacao en polvo"]',
'1. Derrite chocolate. 2. Mezcla con mantequilla de maní. 3. Forma bolitas. 4. Refrigera. 5. Rebozo en cacao. 6. Refrigera nuevamente.', 0),

(89, 'Golden latte de cúrcuma', '🥤', 120, 3, 10, 7,
'["200ml leche de almendra sin azúcar","5g cúrcuma fresca molida o polvo","2g jengibre fresco molido o polvo","1g pimienta negra","5ml miel pura","Pizca de canela (opcional)"]',
'1. Vierte leche de almendra en taza. 2. Calienta a fuego medio-bajo hasta vapor. 3. Mezcla cúrcuma, jengibre, pimienta con agua tibia. 4. Vierte lentamente en leche mientras bates. 5. Bate 1-2 minutos para crear espuma. 6. Vierte en taza. 7. Drizzle miel. 8. Añade canela si deseas. 9. Revuelve. 10. Sirve inmediatamente.', 0),

(90, 'Matcha latte con leche de avena', '🍵', 130, 3, 14, 5,
'["200ml leche avena","5g matcha en polvo","50ml agua caliente","5ml sirope"]',
'1. Vierte agua caliente. 2. Agrega matcha. 3. Bate hasta espuma. 4. Calienta leche de avena. 5. Vierte en taza. 6. Sirve.', 0),

(91, 'Smoothie de coco y piña', '🥥', 200, 2, 32, 8,
'["150ml leche coco","150g piña","1 banana","Cubitos hielo"]',
'1. Pica piña y banana. 2. Licúa con leche. 3. Agrega hielo. 4. Licúa nuevamente. 5. Sirve inmediatamente.', 0),

(92, 'Limonada de fresa', '🍓', 90, 1, 22, 0,
'["200g fresas frescas maduras","150ml agua filtrada","30ml jugo de limón fresco","15ml sirope de arce puro","Hielo","Menta fresca (opcional)"]',
'1. Lava fresas. 2. Licúa 45-60 segundos. 3. Cuela. 4. Vierte en jarra. 5. Exprime limón. 6. Agrega agua. 7. Vierte sirope de arce. 8. Mezcla bien. 9. Llena vasos con hielo. 10. Vierte limonada. 11. Decora con menta o fresa. 12. Sirve inmediatamente.', 0),

(93, 'Jugo de zanahoria y naranja', '🥕', 120, 2, 28, 0,
'["200g zanahoria","200g naranja","50ml agua"]',
'1. Exprime naranjas. 2. Extrae jugo zanahoria. 3. Mezcla. 4. Agrega agua. 5. Sirve fresco.', 0),

(94, 'Chai latte vegano', '🫖', 110, 2, 16, 4,
'["200ml leche soja","1 bolsa té chai","5ml miel","1 rama canela"]',
'1. Calienta leche. 2. Agrega bolsa chai. 3. Deja reposar 5 minutos. 4. Retira bolsa. 5. Agrega miel. 6. Sirve con canela.', 0),

(95, 'Chocolate caliente vegano', '🍫', 200, 4, 28, 8,
'["200ml leche soja","30g cacao en polvo","30g azúcar","5ml vainilla"]',
'1. Calienta leche. 2. Mezcla cacao, azúcar. 3. Agrega a leche. 4. Bate bien. 5. Agrega vainilla. 6. Sirve.', 0),

(96, 'Agua fresca de sandía', '🍉', 60, 1, 14, 0,
'["300g sandía","200ml agua","15ml limón","Hielo"]',
'1. Pica sandía. 2. Licúa con agua. 3. Cuela. 4. Agrega limón. 5. Sirve con hielo.', 0),

(97, 'Jugo verde detox', '🥬', 80, 2, 18, 0,
'["100g espinaca","1 manzana","100g pepino","50ml limón","100ml agua"]',
'1. Licúa espinaca, manzana, pepino. 2. Agrega limón, agua. 3. Cuela si deseas. 4. Sirve inmediatamente.', 0),

(98, 'Té de jengibre y limón', '🫚', 40, 0, 10, 0,
'["200ml agua","10g jengibre fresco","30ml limón","5ml miel"]',
'1. Calienta agua. 2. Agrega jengibre. 3. Deja reposar 5 minutos. 4. Cuela. 5. Agrega limón, miel. 6. Sirve.', 0),

(99, 'Smoothie de durazno y vainilla', '🍑', 160, 3, 30, 3,
'["200g durazno","150ml leche almendra","5ml vainilla","Hielo"]',
'1. Pela durazno. 2. Licúa con leche, vainilla. 3. Agrega hielo. 4. Licúa nuevamente. 5. Sirve.', 0),

(100, 'Agua de jamaica', '🍇', 70, 0, 18, 0,
'["20g flor de jamaica","500ml agua","30ml limón","15ml sirope"]',
'1. Hierve agua. 2. Agrega flores. 3. Deja reposar 10 minutos. 4. Cuela. 5. Agrega limón, sirope. 6. Sirve frío.', 0),

(101, 'Agua de pepino y limón', '🥒', 15, 0, 4, 0,
'["200g pepino","1 limón","1L agua","Hielo","Menta"]',
'1. Corta pepino en rodajas. 2. Corta limón en rodajas. 3. Coloca en jarra con agua. 4. Agrega menta. 5. Refrigera 1 hora. 6. Sirve.', 0),

(102, 'Smoothie de arándanos y avena', '🫐', 240, 8, 40, 5,
'["150g arándanos","200ml leche soja","30g avena","5ml vainilla"]',
'1. Licúa arándanos, avena, leche. 2. Agrega vainilla. 3. Licúa bien. 4. Sirve inmediatamente.', 0),

(103, 'Café helado con leche de coco', '☕', 100, 1, 12, 5,
'["150ml café","100ml leche coco","Hielo","5ml sirope"]',
'1. Prepara café. 2. Enfría. 3. Vierte en vaso con hielo. 4. Agrega leche de coco. 5. Agrega sirope. 6. Mezcla. 7. Sirve.', 0),

(104, 'Zumo de naranja y remolacha', '🍊', 110, 2, 26, 0,
'["200g naranja","100g remolacha","50ml agua"]',
'1. Exprime naranjas. 2. Licúa o exprime remolacha. 3. Mezcla. 4. Agrega agua. 5. Sirve.', 0),

(105, 'Infusión de menta y hierba luisa', '🌿', 5, 0, 1, 0,
'["200ml agua","5g menta fresca","5g hierba luisa","Limón"]',
'1. Calienta agua. 2. Agrega menta y hierba luisa. 3. Deja reposar 5 minutos. 4. Cuela. 5. Agrega limón si deseas. 6. Sirve.', 0);
