// ═══════════════════════════════════════════════════
//  FOOD DATABASES (RECETAS)
//  Catálogo de recetas para registro de comidas
//  ⭐ Versión mejorada con instrucciones detalladas
// ═══════════════════════════════════════════════════

const recipeCatalog = [
  { 
    id:1, cat:"desayuno", emoji:"🥣", title:"Bowl de avena con frutas del bosque", kcal:380, prot:12, carb:62, fat:8,
    ingredientes: ["50g avena", "200ml leche de almendra", "80g frutas del bosque (arándanos, fresas)", "15g almendras laminadas", "5ml miel", "Canela al gusto"],
    preparacion: `1. Vierte 200ml de leche de almendra en una olla pequeña y caliéntala a fuego medio hasta que comience a humear (no dejes que hierva bruscamente). 2. Agrega los 50g de avena poco a poco, removiendo constantemente con una cuchara de madera para evitar grumos. 3. Reduce el fuego a bajo y sigue removiendo cada 30 segundos durante 6-7 minutos, hasta que la avena espese y alcance una consistencia cremosa (cuando pases la cuchara, debe dejar un rastro). 4. Vierte la avena caliente en un bol. 5. Distribuye las frutas del bosque (frías o congeladas funcionan) sobre la avena. 6. Espolvorea las almendras laminadas de manera uniforme. 7. Añade una pizca de canela molida (aproximadamente 0.5g). 8. Drizzle (vierte) la miel en líneas diagonales sobre el bowl. 9. Sirve inmediatamente mientras está caliente. Disfruta en los primeros 5 minutos.`
  },
  { 
    id:2, cat:"desayuno", emoji:"🥞", title:"Pancakes de banana y avena", kcal:320, prot:9, carb:58, fat:6,
    ingredientes: ["100g harina de avena", "1 banana maduro", "120ml leche de soja", "1 cucharadita levadura", "Pizca de sal", "Aceite de coco"],
    preparacion: `1. Tritura 1 banana madura (debe estar suave) con un tenedor en un bol hasta obtener un puré sin grumos. 2. Agrega 100g de harina de avena molida fino, 1 cucharadita rasa de levadura (polvo para hornear), y una pizca de sal. 3. Mezcla bien con un tenedor hasta combinar los ingredientes secos. 4. Vierte 120ml de leche de soja poco a poco, removiendo constantemente, hasta obtener una masa con consistencia de papilla gruesa (similar a yogur espeso). Si queda muy líquida, añade más harina; si muy seca, añade más leche. 5. Deja reposar 2-3 minutos para que la avena absorba la humedad. 6. Calienta 1 cucharada de aceite de coco en una sartén antiadherente a fuego medio-alto. 7. Cuando el aceite esté caliente pero no humee, vierte porciones de masa (aprox. del tamaño de una mano) dejando espacio entre ellas. 8. Cocina exactamente 2-3 minutos en el primer lado sin mover, hasta que los bordes se vean secos y aparezcan agujeros en la superficie. 9. Con una espátula, voltea con cuidado y cocina 2 minutos más en el otro lado hasta que esté dorado. 10. Retira a un plato. 11. Sirve caliente con sirope de arce, frutas frescas o mermelada vegana.`
  },
  { 
    id:3, cat:"desayuno", emoji:"🥑", title:"Tostada de aguacate y tomate", kcal:310, prot:8, carb:35, fat:16,
    ingredientes: ["1 rebanada pan integral", "½ aguacate maduro", "1 tomate mediano", "½ limón", "Sal y pimienta", "Levadura nutricional (opcional)"],
    preparacion: `1. Coloca una rebanada de pan integral en la tostadora a nivel 3-4 (temperatura media-alta). Tostad durante 3-4 minutos hasta que esté crujiente pero no quemado. 2. Mientras se tuesta, toma un aguacate maduro (debe ceder ligeramente a la presión). 3. Corta el aguacate por la mitad en sentido longitudinal, alrededor del hueso. 4. Gira suavemente ambas mitades para separar, retira el hueso con una cuchara. 5. Con la cuchara, extrae toda la pulpa del aguacate hacia un bol pequeño. 6. Machaca el aguacate con un tenedor de manera que quede cremoso pero con algunos pequeños trozos. 7. Exprime ½ limón fresco sobre el aguacate. 8. Mezcla suavemente el limón con el aguacate (el ácido evita que se oxide). 9. Corta el tomate en 4 partes. Retira las semillas. Corta en dados pequeños (aprox. 0.5cm). 10. Cuando el pan salga tostado, colócalo en un plato. 11. Extiende uniformemente el aguacate machacado sobre toda la superficie del pan. 12. Distribuye los dados de tomate sobre el aguacate. 13. Espolvorea sal fina y pimienta negra recién molida al gusto. 14. Si deseas mayor proteína, espolvorea 1 cucharada de levadura nutricional. 15. Sirve inmediatamente para que el pan se mantenga crujiente.`
  },
  { 
    id:4, cat:"desayuno", emoji:"🫐", title:"Smoothie bowl de açaí", kcal:340, prot:7, carb:58, fat:10,
    ingredientes: ["100g pulpa de açaí congelada", "150ml leche de coco", "1 banana congelada", "30g granola", "30g coco rallado", "50g frutas mixtas"],
    preparacion: `1. Retira 100g de pulpa de açaí del congelador (si está en forma de bloques, corta en trozos). 2. Pela 1 banana, córtala en rodajas y congélala durante al menos 2 horas en una bolsa zip. 3. Vierte 150ml de leche de coco sin azúcar en una licuadora. 4. Agrega el açaí cortado en trozos. 5. Agrega la banana congelada. 6. Licúa a velocidad alta durante 45-60 segundos hasta obtener una consistencia de sorbete/helado (debe ser espeso, no líquido). Si queda muy espeso, agrega 30ml más de leche. 7. Vierte inmediatamente en un bol (la consistencia debe permitir que se quede firme). 8. Con el dorso de una cuchara, alisa la superficie. 9. Distribuye 30g de granola sin azúcar en porciones sobre la superficie. 10. Espolvorea 30g de coco rallado sin azúcar. 11. Agrega 50g de frutas mixtas (arándanos, fresas cortadas en rodajas, kiwi). 12. Decora con almendras laminadas si lo deseas. 13. Sirve inmediatamente con una cuchara sopera para comer. Debe consumirse en los 10 primeros minutos antes de que se descongele.`
  },
  { 
    id:5, cat:"desayuno", emoji:"🥜", title:"Granola casera con frutos secos", kcal:290, prot:8, carb:38, fat:13,
    ingredientes: ["150g copos de avena", "50g almendras picadas", "40g nueces", "30g semillas girasol", "30ml aceite de coco", "30ml sirope de arce", "Canela"],
    preparacion: `1. Precalienta horno a 170°C. 2. Mezcla avena, almendras, nueces y semillas en un bol. 3. Calienta aceite de coco y sirope de arce. 4. Vierte sobre los ingredientes secos. 5. Espolvorea canela. 6. Esparcido en bandeja. 7. Hornea 20-25 minutos revolviendo a mitad del tiempo. 8. Enfría completamente antes de guardar.`
  },
  { 
    id:6, cat:"desayuno", emoji:"🍌", title:"Batido verde energizante", kcal:220, prot:5, carb:42, fat:4,
    ingredientes: ["2 puñados de espinaca fresca", "1 banana", "200ml leche de almendra", "50g piña", "5g spirulina (opcional)", "Cubitos de hielo"],
    preparacion: `1. Agrega espinaca en el vaso de la licuadora. 2. Pica la banana en trozos. 3. Añade piña cortada. 4. Vierte la leche de almendra. 5. Agrega spirulina si lo deseas. 6. Añade cubitos de hielo. 7. Licúa durante 60-90 segundos. 8. Sirve inmediatamente. 💚`
  },
  { 
    id:7, cat:"desayuno", emoji:"🫓", title:"Tortitas de espinaca y maíz", kcal:260, prot:7, carb:40, fat:8,
    ingredientes: ["100g espinaca fresca picada", "80g maíz", "100g harina de maíz", "120ml leche vegetal", "1 cebolla pequeña", "Sal y pimienta", "Aceite vegetal"],
    preparacion: `1. Saltea la cebolla picada y la espinaca en una sartén. 2. Mezcla harina de maíz, leche vegetal, sal y pimienta. 3. Incorpora la espinaca y cebolla. 4. Agrega el maíz. 5. Calienta aceite en una sartén. 6. Vierte porciones de masa. 7. Cocina 3-4 minutos por cada lado. 8. Sirve caliente con salsa.`
  },
  { 
    id:8, cat:"desayuno", emoji:"🍓", title:"Chia pudding de fresa", kcal:250, prot:6, carb:30, fat:12,
    ingredientes: ["40g semillas de chia", "200ml leche de almendra", "100g fresas", "10ml miel", "Vainilla", "Fresas para decorar"],
    preparacion: `1. Mezcla semillas de chia con leche de almendra. 2. Agrega miel y vainilla. 3. Remueve bien. 4. Deja reposar en refrigerador 4 horas o toda la noche. 5. Pica las fresas. 6. Remueve el pudding para obtener consistencia uniforme. 7. Vierte en un vaso. 8. Cubre con fresas frescas. 9. Sirve frío.`
  },
  { 
    id:9, cat:"desayuno", emoji:"🥐", title:"Muffins de arándano veganos", kcal:195, prot:4, carb:32, fat:6,
    ingredientes: ["200g harina integral", "50g azúcar de coco", "2 cucharaditas levadura", "200ml leche de soja", "40ml aceite vegetal", "150g arándanos", "Pizca de sal"],
    preparacion: `1. Precalienta horno a 180°C. 2. Mezcla harina, azúcar, levadura y sal. 3. Bate leche de soja con aceite. 4. Une ingredientes secos y húmedos. 5. Agrega arándanos cuidadosamente. 6. Reparte la masa en moldes. 7. Hornea 20-22 minutos. 8. Deja enfriar 5 minutos.`
  },
  { 
    id:10, cat:"desayuno", emoji:"🥕", title:"Porridge de zanahoria y canela", kcal:310, prot:9, carb:52, fat:7,
    ingredientes: ["50g avena integral", "200ml leche de soja sin azúcar", "80g zanahoria fresca", "5ml miel pura", "2g canela molida", "30g nueces picadas", "Sal"],
    preparacion: `1. Pela 1 zanahoria mediana bajo agua corriente. Ralla finamente con un rayador box o un procesador (deberías obtener aproximadamente 80g de zanahoria rallada). 2. Vierte 200ml de leche de soja sin azúcar en una olla pequeña o mediana. 3. Calienta la leche a fuego medio-alto hasta que casi hierva (debe ver vapor pero no burbujas). 4. Agrega 50g de avena integral (no "quick oats", usa avena de corte grueso para mejor textura). 5. Remueve bien con una cuchara de madera. 6. Reduce el fuego a bajo-medio. 7. Cocina durante 5-7 minutos removiendo ocasionalmente cada 1-2 minutos. El porridge debe comenzar a espesar. 8. Cuando haya trascurrido 3-4 minutos de cocción, agrega la zanahoria rallada. Mezcla bien. 9. Continúa cocinando y removiendo durante otros 2-3 minutos. 10. El porridge está listo cuando alcanza una consistencia cremosa con los copos de avena completamente ablandados pero no demasiado fluido. Debe poder mantenerse en la cuchara sin caer inmediatamente. 11. Retira del fuego. 12. Vierte en un bol o plato hondo. 13. Espolvorea 2g (1 cucharadita) de canela molida uniformemente sobre la superficie. 14. Drizzle (vierte) 5ml de miel pura en líneas decorativas sobre el porridge. 15. Distribuye 30g de nueces picadas (pueden ser almendras, nueces o ambas) sobre el porridge. 16. Agrega una pequeña pizca de sal (resalta los sabores). 17. Sirve caliente inmediatamente mientras la textura es más cremosa. Disfruta con una cuchara.`
  },
  { 
    id:11, cat:"desayuno", emoji:"🍇", title:"Parfait de frutas y yogur de coco", kcal:280, prot:5, carb:42, fat:10,
    ingredientes: ["200g yogur de coco", "80g granola", "100g frutas mixtas", "30ml sirope de arce", "15g coco rallado"],
    preparacion: `1. Prepara un vaso o bol. 2. Vierte una capa de yogur de coco. 3. Añade granola. 4. Agrega frutas picadas. 5. Repite capas: yogur, granola, frutas. 6. Termina con yogur. 7. Rocía con sirope de arce. 8. Espolvorea coco rallado. 9. Sirve inmediatamente.`
  },
  { 
    id:12, cat:"desayuno", emoji:"🌽", title:"Arepas veganas rellenas", kcal:350, prot:12, carb:55, fat:10,
    ingredientes: ["200g harina de maíz", "500ml agua", "1 aguacate", "1 tomate", "50g lechuga", "Sal y aceite"],
    preparacion: `1. Mezcla harina de maíz con agua tibia y sal. 2. Deja reposar 5 minutos. 3. Forma bolas y aplasta. 4. Cocina en sartén caliente 5 minutos cada lado. 5. Abre por la mitad sin cortar completamente. 6. Machaca el aguacate. 7. Arma relleno con aguacate, tomate y lechuga. 8. Rellena las arepas.`
  },
  { 
    id:13, cat:"desayuno", emoji:"🫘", title:"Tofu revuelto con verduras", kcal:280, prot:18, carb:12, fat:16,
    ingredientes: ["200g tofu firme", "100g cebolla", "150g champiñones", "100g espinaca", "50ml leche vegetal", "Cúrcuma, sal", "Aceite de oliva"],
    preparacion: `1. Desmorona el tofu con los dedos. 2. Pica cebolla, champiñones en rodajas, espinaca. 3. Calienta aceite en sartén. 4. Saltea cebolla y champiñones. 5. Agrega tofu desmenuzado. 6. Añade espinaca. 7. Espolvorea cúrcuma. 8. Vierte leche vegetal. 9. Saltea 5-7 minutos. 10. Sirve caliente.`
  },
  { 
    id:14, cat:"desayuno", emoji:"🥭", title:"Smoothie tropical de mango", kcal:240, prot:3, carb:48, fat:5,
    ingredientes: ["200g mango congelado", "150ml leche de coco", "50g piña", "1 banana", "5ml néctar de agave", "Cubitos de hielo"],
    preparacion: `1. Cortador mango congelado en trozos. 2. Pica piña y banana. 3. Coloca todo en la licuadora. 4. Vierte leche de coco. 5. Agrega néctar de agave. 6. Añade cubitos de hielo. 7. Licúa hasta lograr consistencia suave. 8. Sirve inmediatamente. 🥭`
  },
  { 
    id:15, cat:"desayuno", emoji:"🫕", title:"Avena horneada con manzana", kcal:330, prot:8, carb:56, fat:9,
    ingredientes: ["150g copos de avena", "200ml leche de almendra", "1 manzana grande", "30ml sirope de arce", "30g nueces", "2g canela"],
    preparacion: `1. Precalienta horno a 175°C. 2. Mezcla avena, leche de almendra y sirope. 3. Pela y corta manzana en dados. 4. Incorpora manzana y canela. 5. Vierte en bandeja. 6. Espolvorea nueces. 7. Hornea 25-30 minutos. 8. Sirve aún caliente.`
  },
  { 
    id:16, cat:"desayuno", emoji:"🍞", title:"French toast vegano", kcal:340, prot:9, carb:48, fat:12,
    ingredientes: ["4 rebanadas pan", "200ml leche de soja", "1 banana", "5ml vainilla", "2g canela", "Aceite de coco"],
    preparacion: `1. Licúa leche de soja, banana, vainilla y canela. 2. Vierte en un plato hondo. 3. Calienta aceite en sartén. 4. Sumerge el pan en la mezcla 2 segundos por lado. 5. Cocina en sartén 2-3 minutos cada lado. 6. Sirve caliente con frutas y jarabe.`
  },
  { 
    id:17, cat:"desayuno", emoji:"🥒", title:"Bowl verde de quinoa", kcal:420, prot:16, carb:52, fat:16,
    ingredientes: ["100g quinoa cocida", "100g espinaca", "1 aguacate", "100g pepino", "50g germinados", "Limón", "Aceite de oliva"],
    preparacion: `1. Cocina quinoa según indicaciones. 2. Coloca en un bol. 3. Agrega espinaca fresca picada. 4. Corta aguacate en láminas. 5. Pica pepino. 6. Distribuye sobre la base de quinoa. 7. Espolvorea germinados. 8. Aliña con limón y aceite de oliva. 9. Mezcla suavemente.`
  },
  { 
    id:18, cat:"desayuno", emoji:"🥝", title:"Bowl de açaí tropical", kcal:300, prot:6, carb:50, fat:10,
    ingredientes: ["100g pulpa açaí", "150ml leche de coco", "1 banana congelada", "50g kiwi", "30g coco", "30g granola"],
    preparacion: `1. Mezcla pulpa de açaí con leche de coco. 2. Licúa con banana congelada hasta sorbete. 3. Vierte en un bol. 4. Pela y corta kiwi en rodajas finas. 5. Distribuye en la superficie. 6. Agrega granola. 7. Espolvorea coco. 8. Decora con banana en rodajas. 9. Sirve inmediatamente.`
  },
  { 
    id:19, cat:"almuerzo", emoji:"🍜", title:"Ramen de miso con tofu crujiente", kcal:520, prot:28, carb:65, fat:14,
    ingredientes: ["150g fideos ramen", "200ml caldo vegetal", "30ml pasta miso", "150g tofu firme", "100g bok choy", "30g alga nori", "Cebollitas verdes", "Aceite de sésamo"],
    preparacion: `TOFU: 1. Saca 150g de tofu firme del paquete y envuélvelo en papel absorbente de cocina. Coloca sobre un plato. 2. Coloca otro plato sobre el papel y presiona con cuidado durante 10 minutos para remover el exceso de agua. 3. Retira el papel. Corta el tofu en cubos de aproximadamente 1.5cm. 4. Calienta 15ml de aceite vegetal en una sartén a fuego medio-alto hasta que esté brillante pero no humee. 5. Coloca los cubos de tofu en la sartén. NO LOS MUEVAS durante 3-4 minutos para que se forme una costra dorada. 6. Voltea cada cubo cuidadosamente con una espátula. 7. Cocina otros 3 minutos en el otro lado. Retira a un plato con papel absorbente. CALDO: 8. Vierte 1 litro de agua en una olla grande. Lleva a hervor. 9. Cocina los 150g de fideos ramen exactamente según el tiempo en el paquete (generalmente 3-4 minutos). 10. Cuela los fideos reservando 200ml del agua de cocción. PREPARACION CALDO MISO: 11. En otra olla pequeña, calienta 200ml de caldo vegetal a fuego medio (NO dejes que hierva). 12. En un bol pequeño, disuelve 30ml (2 cucharadas) de pasta miso con 60ml del agua reservada de los fideos, revolviendo bien hasta obtener una pasta suave. 13. Vierte esta mezcla de miso en el caldo caliente, removiendo constantemente. 14. Apaga el fuego inmediatamente (el hervir destruye los probióticos del miso). VEGETALES: 15. Mientras el caldo se prepara, corta 100g de bok choy diagonalmente en trozos de 2-3cm. 16. En una pequeña sartén, saltea el bok choy con 5ml de aceite de sésamo durante 2-3 minutos a fuego medio-alto hasta que esté tierno pero aún crujiente. ARMADO: 17. Coloca los fideos escurridos en un bol de ramen o tazón grande. 18. Vierte el caldo de miso sobre los fideos. 19. Distribuye el bok choy salteado en la superficie. 20. Agrega el tofu frito crujiente. 21. Coloca 1-2 láminas de alga nori en la orilla del bol. 22. Espolvorea cebollitas verdes picadas (aprox. 10g). 23. Rocía 5ml de aceite de sésamo tostado en forma de espiral. 24. Sirve inmediatamente caliente.`
  },
  { 
    id:20, cat:"almuerzo", emoji:"🌮", title:"Tacos de jackfruit al pastor", kcal:380, prot:8, carb:62, fat:10,
    ingredientes: ["200g jackfruit enlatado", "1 cebolla mediana", "2 tomates medianos", "50g cilantro fresco", "6 tortillas maíz", "½ limón", "Especias: comino, achiote, sal"],
    preparacion: `PREPARACION DE JACKFRUIT: 1. Abre 200g de jackfruit enlatado en agua (no en almíbar). Cuela bien. 2. Con dos tenedores, deshebra el jackfruit separando las fibras (debe parecer desmenuzado como carne). 3. Enjuaga nuevamente bajo agua fría. Seca bien con papel absorbente (el exceso de agua evitará que se dore bien). MARINADA: 4. En un bol, mezcla: 5g de comino molido, 3g de achiote molido (o paprika si no tienes), 3g de sal fina, 2g de pimienta negra. 5. Agrega el jackfruit desmenuzado y revuelve bien para que todos los hilos queden impregnados de especias. COCCION: 6. Calienta 15ml de aceite vegetal en una sartén grande a fuego medio-alto. 7. Vierte todo el jackfruit con sus especias. 8. Cocina removiendo ocasionalmente durante 8-10 minutos hasta que esté bien caliente y los bordes comiencen a caramelizarse ligeramente (debe verse dorado, no gris). 9. Prueba y ajusta sal si es necesario. VEGETALES: 10. Mientras el jackfruit se cocina, pela 1 cebolla mediana y córtala en rodajas finas. 11. Corta 2 tomates en dados pequeños (retira las semillas si prefieres). 12. Pica 50g de cilantro fresco (solo las hojas). ARMADO: 13. Calienta las 6 tortillas de maíz en una sartén a fuego medio durante 30 segundos por cada lado, hasta que estén flexibles pero no rotas. O caliéntalas directamente sobre la llama de la estufa durante 15 segundos por lado. 14. Coloca cada tortilla caliente en un plato. 15. Cubre con aproximadamente 30g del jackfruit marinado en el centro. 16. Agrega cebolla fresca en rodajas. 17. Distribuye dados de tomate. 18. Espolvorea cilantro fresco. 19. Exprime un poco de limón (aprox. ½ limón dividido entre los 6 tacos). 20. Sirve inmediatamente mientras los tacos estén calientes.`
  },
  { 
    id:21, cat:"almuerzo", emoji:"🥗", title:"Buddha bowl mediterráneo", kcal:560, prot:24, carb:72, fat:18,
    ingredientes: ["150g garbanzos cocidos", "100g quinoa", "100g lechuga", "50g tomate cherry", "50g pepino", "40g aceitunas", "50g hummus", "30ml aceite de oliva"],
    preparacion: `1. Cocina quinoa. 2. Asa los garbanzos 20 minutos a 200°C con especias. 3. Pica todos los vegetales. 4. Distribuye quinoa en un bol. 5. Agrega lechuga, tomate, pepino alrededor. 6. Coloca garbanzos asados. 7. Añade aceitunas. 8. Sirve con hummus en el centro. 9. Aliña con aceite de oliva y limón.`
  },
  { 
    id:22, cat:"almuerzo", emoji:"🍛", title:"Dahl de lentejas rojas", kcal:380, prot:20, carb:58, fat:6,
    ingredientes: ["200g lentejas rojas descascaradas", "1 cebolla mediana", "2 dientes ajo", "1 tomate mediano", "200ml leche de coco", "10g jengibre fresco", "5g cúrcuma molida", "3g comino molido", "700ml agua o caldo vegetal"],
    preparacion: `1. Enjuaga 200g de lentejas rojas descascaradas bajo agua fría en un colador. Coloca en un bol y cubre con agua durante 15 minutos (esto ayuda a que cuezan más uniformemente). 2. Pela 1 cebolla mediana y córtala en dados pequeños (aprox. 0.5cm). 3. Pela 2 dientes de ajo y pícalos finamente. 4. Ralla finamente 10g de jengibre fresco (o pica si no tienes rayador). 5. Calienta 15ml de aceite vegetal en una olla grande a fuego medio. 6. Agrega la cebolla picada. Saltea durante 3-4 minutos removiendo ocasionalmente hasta que esté translúcida y suave. 7. Agrega el ajo picado. Cocina 1 minuto más removiendo constantemente (cuidado de que no se queme). 8. Añade el jengibre rallado. Remueve bien. 9. Espolvorea 5g de cúrcuma molida sobre la mezcla. 10. Agrega 3g de comino molido. 11. Remueve bien durante 30 segundos para que las especias se tuestaen ligeramente en el aceite (esto libera sus sabores). 12. Cuela las lentejas y verifica que no tengan agua. Vierte las lentejas en la olla. 13. Remueve bien para cubrir las lentejas con la mezcla de especias. 14. Vierte 700ml de agua o caldo vegetal. 15. Corta 1 tomate mediano en dados pequeños y agrégalo a la olla. 16. Lleva a ebullición a fuego alto, removiendo ocasionalmente. 17. Cuando empiece a hervir, reduce el fuego a bajo-medio y deja que hierva suavemente. 18. Cocina destapado durante 20-25 minutos removiendo ocasionalmente, hasta que las lentejas estén completamente blandas y desintegradas (cuando presiones con una cuchara, desaparecen fácilmente). 19. Vierte 200ml de leche de coco. 20. Revuelve bien durante 2-3 minutos. La consistencia debe ser similar a una sopa espesa o un estofado. Si está muy espesa, agrega 100ml más de agua. 21. Cocina 5 minutos más a fuego bajo. 22. Prueba y ajusta sal y pimienta según tu gusto. 23. Sirve caliente en platos hondos acompañado de arroz integral, roti o naan. Decora con cilantro fresco si lo deseas.`
  },
  { 
    id:23, cat:"almuerzo", emoji:"🥙", title:"Wrap de hummus y vegetales", kcal:380, prot:14, carb:48, fat:14,
    ingredientes: ["2 tortillas integrales", "100g hummus", "100g verduras (lechuga, tomate, pepino)", "50g germinados", "30g zanahorias ralladas", "Tahini"],
    preparacion: `1. Calienta tortillas. 2. Extiende hummus generosamente. 3. Agrega lechuga, tomate, pepino picados. 4. Añade germinados y zanahorias. 5. Rocía tahini. 6. Enrolla apretadamente. 7. Corta por la mitad. 8. Sirve con salsa de chile o mostaza.`
  },
  { 
    id:24, cat:"almuerzo", emoji:"🍲", title:"Sopa de calabaza y jengibre", kcal:220, prot:4, carb:38, fat:7,
    ingredientes: ["400g calabaza", "1 cebolla", "3g jengibre", "500ml caldo vegetal", "100ml leche de coco", "Sal y pimienta"],
    preparacion: `1. Pica calabaza, cebolla y jengibre. 2. Saltea cebolla y jengibre. 3. Agrega calabaza. 4. Vierte caldo vegetal. 5. Cocina 20 minutos. 6. Licúa hasta obtener crema. 7. Agrega leche de coco. 8. Sazona. 9. Sirve caliente con pan tostado.`
  },
  { 
    id:25, cat:"almuerzo", emoji:"🍚", title:"Arroz frito vegano con tofu", kcal:420, prot:16, carb:62, fat:12,
    ingredientes: ["200g arroz cocido (día anterior)", "150g tofu firme", "100g verduras mixtas", "30ml salsa soja", "50g cebollitas", "Aceite vegetal", "Ajo"],
    preparacion: `1. Corta tofu en cubos y fríe hasta dorar. 2. Calienta aceite, agrega ajo picado. 3. Añade verduras cortadas, saltea 3 minutos. 4. Agrega arroz desmenuzado. 5. Vierte salsa soja. 6. Incorpora tofu frito. 7. Mezcla bien. 8. Cocina 5 minutos. 9. Decora con cebollitas. 10. Sirve caliente.`
  },
  { 
    id:26, cat:"almuerzo", emoji:"🫑", title:"Pimientos rellenos de quinoa", kcal:340, prot:14, carb:52, fat:8,
    ingredientes: ["3 pimientos", "150g quinoa cocida", "80g garbanzos", "50g tomate", "30g cebolla", "Hierbas: perejil, orégano"],
    preparacion: `1. Corta pimientos por la mitad, retira semillas. 2. Sofríe cebolla, tomate. 3. Mezcla con quinoa y garbanzos. 4. Agrega perejil y orégano. 5. Rellena los pimientos. 6. Coloca en bandeja. 7. Rocía con aceite. 8. Hornea 25 minutos a 200°C. 9. Sirve con salsa.`
  },
  { 
    id:27, cat:"almuerzo", emoji:"🍕", title:"Pizza vegana con vegetales", kcal:380, prot:12, carb:52, fat:14,
    ingredientes: ["1 base pizza integral", "100ml salsa de tomate", "100g queso vegano", "200g vegetales variados", "30ml aceite de oliva"],
    preparacion: `1. Precalienta horno a 220°C. 2. Extiende salsa de tomate sobre base. 3. Distribuye queso vegano rallado. 4. Agrega vegetales cortados (champiñones, tomate, cebolla, pimiento). 5. Rocía aceite de oliva. 6. Hornea 12-15 minutos. 7. Sirve caliente.`
  },
  { 
    id:28, cat:"almuerzo", emoji:"🥘", title:"Curry de garbanzos y espinaca", kcal:360, prot:16, carb:48, fat:12,
    ingredientes: ["250g garbanzos", "200g espinaca fresca", "200ml leche de coco", "1 cebolla", "3g curry", "2g cúrcuma", "Ajo"],
    preparacion: `1. Saltea cebolla y ajo. 2. Agrega polvo de curry y cúrcuma. 3. Incorpora garbanzos. 4. Vierte leche de coco. 5. Cocina 10 minutos. 6. Agrega espinaca. 7. Cocina 5 minutos más. 8. Sirve con arroz basmati o naan.`
  },
  { 
    id:29, cat:"almuerzo", emoji:"🌯", title:"Burrito bowl de frijoles", kcal:480, prot:18, carb:68, fat:14,
    ingredientes: ["150g arroz", "200g frijoles negros", "100g maíz", "50g salsa", "100g lechuga", "50g tomate", "30g cebolla", "Limón"],
    preparacion: `1. Cocina arroz. 2. Calienta frijoles con comino y ajo. 3. Distribuye arroz en un bol. 4. Agrega frijoles, maíz. 5. Añade lechuga y tomate picados. 6. Rodea con salsa. 7. Decora con cebolla y cilantro. 8. Exprime limón. 9. Sirve inmediatamente.`
  },
  { 
    id:30, cat:"almuerzo", emoji:"🥦", title:"Salteado de brócoli y sésamo", kcal:220, prot:10, carb:22, fat:10,
    ingredientes: ["300g brócoli", "30g semillas sésamo", "30ml salsa soja", "3g ajo", "5ml aceite sésamo", "Jengibre"],
    preparacion: `1. Corta brócoli en floretes. 2. Calienta aceite en wok. 3. Agrega ajo y jengibre picados. 4. Añade brócoli, saltea 5 minutos. 5. Vierte salsa soja. 6. Cocina 3 minutos más. 7. Espolvorea semillas de sésamo. 8. Rocía aceite de sésamo. 9. Sirve caliente.`
  },
  { 
    id:31, cat:"almuerzo", emoji:"🍝", title:"Pasta primavera vegana", kcal:420, prot:12, carb:62, fat:14,
    ingredientes: ["200g pasta integral", "200g vegetales variados", "100ml nata vegetal", "50g champiñones", "30g cebolla", "Ajo, perejil"],
    preparacion: `1. Cocina pasta según instrucciones. 2. Saltea cebolla, ajo y champiñones. 3. Agrega vegetales cortados. 4. Vierte nata vegetal. 5. Sazona. 6. Cuela pasta y mezcla. 7. Cocina 2 minutos. 8. Decora con perejil fresco. 9. Sirve inmediatamente.`
  },
  { 
    id:32, cat:"almuerzo", emoji:"🥬", title:"Ensalada César vegana", kcal:320, prot:10, carb:28, fat:18,
    ingredientes: ["200g lechuga romana", "100g crutones", "50g queso vegano", "Salsa César vegana (100ml)"],
    preparacion: `1. Prepara salsa: mezcla tahini, ajo, limón, mostaza, agua. 2. Pica lechuga romana. 3. Distribuye en un bol grande. 4. Agrega crutones. 5. Rocía salsa César. 6. Espolvorea queso vegano rallado. 7. Mezcla suavemente. 8. Sirve inmediatamente.`
  },
  { 
    id:33, cat:"almuerzo", emoji:"🍆", title:"Berenjenas a la parmesana vegana", kcal:380, prot:12, carb:42, fat:18,
    ingredientes: ["300g berenjena", "300ml salsa tomate", "150g queso vegano", "100ml leche vegetal", "50g harina", "Aceite", "Orégano"],
    preparacion: `1. Corta berenjena en rodajas. 2. Pásalas por harina y fríe. 3. Precalienta horno a 200°C. 4. Coloca capas: salsa, berenjena, queso. 5. Repite. 6. Termina con queso. 7. Hornea 25 minutos. 8. Sirve con ensalada fresca.`
  },
  { 
    id:34, cat:"almuerzo", emoji:"🥕", title:"Sopa de zanahoria y coco", kcal:200, prot:4, carb:30, fat:8,
    ingredientes: ["400g zanahoria", "200ml leche de coco", "500ml caldo vegetal", "1 cebolla", "Jengibre", "Sal"],
    preparacion: `1. Pica cebolla y zanahoria. 2. Saltea cebolla. 3. Agrega zanahoria y jengibre. 4. Vierte caldo. 5. Cocina 20 minutos. 6. Licúa suavemente. 7. Agrega leche de coco. 8. Calienta 5 minutos. 9. Sirve con cilantro.`
  },
  { 
    id:35, cat:"almuerzo", emoji:"🫔", title:"Tamales veganos de rajas", kcal:320, prot:8, carb:48, fat:12,
    ingredientes: ["200g masa de maíz", "100g rajas poblanas", "50g frijoles", "Hojas de maíz", "Caldo vegetal"],
    preparacion: `1. Remoja hojas de maíz. 2. Prepara masa: mezcla harina de maíz con caldo. 3. Corta rajas poblanas. 4. Coloca hoja, extiende masa. 5. Agrega rajas y frijoles. 6. Envuelve. 7. Cocina al vapor 45 minutos. 8. Sirve caliente.`
  },
  { 
    id:36, cat:"almuerzo", emoji:"🥧", title:"Quiche vegano de espinaca", kcal:280, prot:14, carb:28, fat:12,
    ingredientes: ["1 base pie integral", "200g espinaca", "200ml leche de soja", "100g tofu sedoso", "50g nueces", "Sal, pimienta"],
    preparacion: `1. Precalienta horno a 190°C. 2. Coloca base pie en molde. 3. Saltea espinaca ligeramente. 4. Licúa tofu con leche de soja. 5. Mezcla con espinaca. 6. Vierte sobre base. 7. Esparcir nueces picadas. 8. Hornea 30 minutos. 9. Sirve templado.`
  },
  { 
    id:37, cat:"cena", emoji:"🍝", title:"Pasta al pesto de espinaca", kcal:520, prot:16, carb:70, fat:20,
    ingredientes: ["250g pasta integral", "200g espinaca fresca", "50g piñones tostados", "30g ajo", "100ml aceite de oliva virgen", "50g levadura nutricional", "Sal y pimienta"],
    preparacion: `PASTA: 1. Llena una olla grande con agua (aproximadamente 2 litros). Lleva a ebullición a fuego alto. 2. Agrega 10g de sal (aproximadamente 1 cucharada). El agua debe saber como agua de mar. 3. Agrega 250g de pasta integral. 4. Remueve bien con una cuchara de madera para evitar que se pegue. 5. Cocina exactamente según el tiempo indicado en el paquete (generalmente 10-12 minutos), removiendo ocasionalmente. Prueba 2 minutos antes del tiempo recomendado. La pasta debe estar al dente (con un poco de resistencia al morder, no muy blanda). 6. Reserva 250ml del agua de cocción de la pasta en una taza antes de colar. 7. Cuela la pasta en un colador. PESTO: 8. Mientras se cocina la pasta, lava 200g de espinaca fresca bajo agua corriente fría. Sécala bien. 9. Coloca la espinaca en una licuadora o procesador de alimentos. 10. Agrega 50g de piñones tostados. 11. Pela 4-5 dientes de ajo (equivalente a 30g) y añade a la licuadora. 12. Vierte 100ml de aceite de oliva virgen extra. 13. Agrega 50g de levadura nutricional. 14. Licúa a velocidad media-alta durante 30-45 segundos, raspando las paredes con una espátula, hasta obtener una pasta gruesa y texturizada (no debe ser un puré completamente suave). 15. Sazona con sal fina y pimienta negra recién molida al gusto. COMBINACION FINAL: 16. Retorna la pasta colada a la olla (sin agua). 17. Vierte todo el pesto sobre la pasta. 18. A fuego bajo, mezcla bien durante 1-2 minutos para que el pesto cubra toda la pasta. 19. Si está muy espeso, añade 60ml del agua de cocción reservada y mezcla. 20. Sirve inmediatamente en platos hondos calentados. 21. Completa con tomate cherry cortado por la mitad si lo deseas.`
  },
  { 
    id:38, cat:"cena", emoji:"🫕", title:"Curry verde thai con tofu", kcal:445, prot:19, carb:38, fat:22,
    ingredientes: ["200g tofu firme", "200ml leche de coco", "50ml pasta curry verde", "100g bok choy", "100g champiñones", "Cilantro", "Limón"],
    preparacion: `1. Corta tofu en cubos. 2. Calienta aceite, saltea tofu hasta dorar. 3. Retira tofu. 4. En la misma sartén, calienta pasta curry. 5. Vierte leche de coco. 6. Añade bok choy y champiñones. 7. Cocina 10 minutos. 8. Incorpora tofu. 9. Cocina 5 minutos. 10. Decora con cilantro y limón.`
  },
  { 
    id:39, cat:"cena", emoji:"🍲", title:"Estofado de lentejas y vegetales", kcal:360, prot:18, carb:56, fat:6,
    ingredientes: ["200g lentejas", "200g zanahoria", "150g papa", "100g cebolla", "700ml caldo vegetal", "Hierbas de provenza"],
    preparacion: `1. Enjuaga lentejas. 2. Pica cebolla, zanahoria, papa. 3. Saltea cebolla. 4. Agrega zanahoria y papa. 5. Vierte caldo y lentejas. 6. Añade hierbas. 7. Cocina 35-40 minutos. 8. Sazona. 9. Sirve en platos hondos calientes.`
  },
  { 
    id:40, cat:"cena", emoji:"🌶️", title:"Chili sin carne", kcal:320, prot:16, carb:52, fat:6,
    ingredientes: ["400g frijoles", "200g tomate enlatado", "1 cebolla", "150g pimiento", "30g salsa picante", "Comino, chili en polvo"],
    preparacion: `1. Saltea cebolla picada. 2. Agrega pimiento cortado. 3. Vierte tomate enlatado. 4. Incorpora frijoles cocidos. 5. Sazona con comino, chili, sal. 6. Agrega salsa picante. 7. Cocina 25-30 minutos. 8. Sirve con cilantro fresco.`
  },
  { 
    id:41, cat:"cena", emoji:"🥟", title:"Gyozas veganas de verduras", kcal:280, prot:8, carb:42, fat:8,
    ingredientes: ["20 envoltorios wonton", "150g repollo", "100g zanahoria", "50g champiñones", "30ml salsa soja", "Aceite vegetal", "Ajo"],
    preparacion: `1. Pica repollo, zanahoria, champiñones. 2. Saltea con ajo. 3. Coloca relleno en cada envoltorio. 4. Humedece bordes con agua. 5. Dobla y sella. 6. Fríe en aceite caliente 2-3 minutos por lado. 7. Sirve con salsa soja y mostaza de wasabi.`
  },
  { 
    id:42, cat:"cena", emoji:"🍛", title:"Tikka masala de coliflor", kcal:320, prot:10, carb:38, fat:14,
    ingredientes: ["300g coliflor", "200ml leche de coco", "100ml salsa tomate", "30g pasta tikka", "1 cebolla", "Cilantro"],
    preparacion: `1. Corta coliflor en floretes. 2. Asa coliflor 20 minutos a 200°C. 3. Saltea cebolla. 4. Agrega pasta tikka. 5. Vierte salsa tomate y leche de coco. 6. Mezcla bien. 7. Incorpora coliflor asada. 8. Cocina 10 minutos. 9. Decora con cilantro. 10. Sirve con arroz.`
  },
  { 
    id:43, cat:"cena", emoji:"🥘", title:"Tagine marroquí de garbanzos", kcal:390, prot:14, carb:58, fat:12,
    ingredientes: ["300g garbanzos", "150g dátiles", "100g cebolla", "50g almendras", "5g canela", "Agua de azahar"],
    preparacion: `1. Saltea cebolla. 2. Agrega garbanzos cocidos. 3. Añade dátiles sin hueso picados. 4. Vierte agua (200ml). 5. Sazona con canela. 6. Cocina 20 minutos. 7. Agrega almendras. 8. Rocía agua de azahar. 9. Sirve con cuscús.`
  },
  { 
    id:44, cat:"cena", emoji:"🫘", title:"Hamburguesas de frijol negro", kcal:340, prot:16, carb:48, fat:10,
    ingredientes: ["250g frijoles negros cocidos", "50g pan integral rallado", "30g cebolla deshidratada o fresca", "30ml salsa de soja", "2g comino molido", "2g pimienta negra", "Aceite vegetal"],
    preparacion: `PREPARACIÓN MASA: 1. Cuela 250g de frijoles negros cocidos bien (si son enlatados, enjuágalos bajo agua fría durante 1 minuto). 2. Transfiere los frijoles a un bol. 3. Con un tenedor o pasapu­rés, tritura los frijoles hasta obtener una consistencia de puré con pequeños trozos (aproximadamente 60% de los frijoles deben verse desmenuzados). 4. En otro bol, mezcla 50g de pan integral rallado fino (o pan molido), 30g de cebolla fresca picada muy finamente (o cebolla deshidratada si es más conveniente), 2g de comino molido, 2g de pimienta negra recién molida. 5. Vierte 30ml de salsa de soja en el bol de especias. Mezcla bien. 6. Vierte la mezcla de pan y especias sobre los frijoles triturados. 7. Mezcla enérgicamente con un tenedor durante 1-2 minutos hasta obtener una masa compacta que se mantenga unida (es normal que sea un poco humedad). FORMACIÓN Y CONGELACIÓN: 8. Forma 4 discos redondos con el tamaño de una hamburguesa estándar (aproximadamente 10cm de diámetro y 1.5cm de grosor). Presiona firmemente para que sean compactos. 9. Coloca las 4 hamburguesas en una bandeja o plato. 10. Congela durante al menos 30 minutos (o hasta 2 días si las cubres bien). Congelar es importante porque evita que se desmoronen al freír. COCCIÓN: 11. Retira las hamburguesas del congelador 5 minutos antes de cocinar. 12. Calienta 20ml de aceite vegetal en una sartén grande a fuego medio-alto. 13. Cuando el aceite esté caliente (debe brillar pero no humear), coloca cuidadosamente las 2 hamburguesas en la sartén. 14. Cocina sin mover durante 4-5 minutos en el primer lado hasta que se forme una costra dorada y crujiente. 15. Con una espátula, voltea cuidadosamente. 16. Cocina otros 4-5 minutos en el otro lado hasta que también esté dorado. 17. Retira a un plato con papel absorbente. ARMADO Y SERVIDO: 18. Calienta suavemente 4 panes de hamburguesa integral. 19. Coloca lechuga fresca en la base del pan. 20. Coloca la hamburguesa de frijol negro. 21. Agrega tomate en rodajas. 22. Añade una pequeña cantidad de mayonesa vegana si lo deseas. 23. Coloca la tapa del pan. 24. Sirve caliente acompañado de papas fritas al horno.`
  },
  { 
    id:45, cat:"cena", emoji:"🍜", title:"Pad thai vegano", kcal:480, prot:18, carb:62, fat:16,
    ingredientes: ["200g fideos arroz", "200g vegetales mixtos", "100g tofu", "50g cacahuetes", "30ml salsa soja", "Limón", "Cilantro"],
    preparacion: `1. Cocina fideos según instrucciones. 2. Fríe tofu en cubos. 3. Saltea vegetales. 4. Mezcla fideos y vegetales. 5. Agrega salsa soja. 6. Esparcir cacahuetes triturados. 7. Exprime limón. 8. Decora con cilantro. 9. Sirve inmediatamente.`
  },
  { 
    id:46, cat:"cena", emoji:"🥗", title:"Bowl de batata asada y tahini", kcal:420, prot:14, carb:58, fat:16,
    ingredientes: ["300g batata", "150g garbanzos", "100g lechuga", "50g tahini", "Limón", "Cebollitas verdes"],
    preparacion: `1. Corta batata en tiras. 2. Asa con aceite a 200°C durante 25 minutos. 3. Asa garbanzos también. 4. Distribuye lechuga en un bol. 5. Agrega batata y garbanzos asados. 6. Prepara aliño: tahini + limón + agua. 7. Rocía aliño. 8. Decora con cebollitas. 9. Sirve caliente.`
  },
  { 
    id:47, cat:"cena", emoji:"🍕", title:"Pizza de masa de coliflor", kcal:320, prot:12, carb:36, fat:14,
    ingredientes: ["400g coliflor", "50g harina", "80g levadura", "100ml salsa tomate", "100g queso vegano", "Vegetales variados"],
    preparacion: `1. Licúa coliflor cruda. 2. Exprime bien el agua. 3. Mezcla con harina y levadura. 4. Forma base en bandeja. 5. Hornea 25 minutos a 200°C. 6. Extiende salsa de tomate. 7. Agrega queso y vegetales. 8. Hornea 10 minutos más. 9. Sirve caliente.`
  },
  { 
    id:48, cat:"cena", emoji:"🌽", title:"Polenta cremosa con setas", kcal:380, prot:10, carb:52, fat:14,
    ingredientes: ["100g polenta", "400ml caldo vegetal", "200g champiñones", "100ml leche vegetal", "30g levadura nutricional", "Ajo"],
    preparacion: `1. Hierve caldo. 2. Agrega polenta lentamente, removiendo constantemente. 3. Cocina 30 minutos. 4. Saltea champiñones con ajo. 5. Agrega leche vegetal a la polenta. 6. Incorpora levadura nutricional. 7. Mezcla con champiñones. 8. Sirve caliente en platos hondos.`
  },
  { 
    id:49, cat:"cena", emoji:"🥕", title:"Shepherd's pie vegano", kcal:380, prot:16, carb:56, fat:10,
    ingredientes: ["500g papa", "150g lentejas", "100g zanahoria", "100g cebolla", "200ml caldo vegetal", "50ml leche vegetal"],
    preparacion: `1. Cocina papa, machaca con leche vegetal. 2. Saltea cebolla, zanahoria. 3. Agrega lentejas cocidas. 4. Vierte caldo. 5. Cocina 15 minutos. 6. Coloca en bandeja refractaria. 7. Cubre con puré de papa. 8. Hornea 20 minutos a 200°C. 9. Sirve caliente.`
  },
  { 
    id:50, cat:"cena", emoji:"🫓", title:"Naan con curry de verduras", kcal:440, prot:12, carb:62, fat:16,
    ingredientes: ["300g harina integral", "200ml agua tibia", "7g levadura", "300g vegetales", "50ml salsa curry", "Aceite"],
    preparacion: `1. Prepara naan: mezcla harina, agua, levadura, sal. 2. Deja reposar 1 hora. 3. Divide en bolitas, estira. 4. Cocina en sartén caliente. 5. Prepara curry saltando vegetales. 6. Agrega salsa curry. 7. Cocina 15 minutos. 8. Sirve naan con curry.`
  },
  { 
    id:51, cat:"cena", emoji:"🍆", title:"Lasaña vegana de berenjena", kcal:380, prot:18, carb:42, fat:16,
    ingredientes: ["400g berenjena", "300ml salsa tomate", "200g tofu ricotta", "100g espinaca", "Orégano"],
    preparacion: `1. Corta berenjena en rodajas. 2. Prepara ricotta: tofu + levadura + agua. 3. Precalienta horno a 190°C. 4. Capas: salsa, berenjena, ricotta, espinaca. 5. Repite. 6. Termina con salsa. 7. Hornea 30 minutos. 8. Deja reposar 10 minutos. 9. Sirve.`
  },
  { 
    id:52, cat:"cena", emoji:"🥜", title:"Fideos con salsa de cacahuete", kcal:460, prot:16, carb:58, fat:18,
    ingredientes: ["200g fideos arroz", "100g cacahuete", "30ml salsa soja", "1 zanahoria", "100g brócoli", "Limón"],
    preparacion: `1. Cocina fideos. 2. Prepara salsa: cacahuete + agua + salsa soja + limón. 3. Saltea zanahoria y brócoli. 4. Mezcla fideos con vegetales. 5. Vierte salsa de cacahuete. 6. Mezcla bien. 7. Decora con cilantro. 8. Sirve caliente.`
  },
  { 
    id:53, cat:"cena", emoji:"🫑", title:"Fajitas veganas de portobello", kcal:340, prot:10, carb:42, fat:14,
    ingredientes: ["300g champiñones portobello", "1 cebolla", "2 pimientos", "6 tortillas", "Especias fajita", "Guacamole"],
    preparacion: `1. Corta portobellos en tiras. 2. Corta cebolla y pimientos. 3. Saltea con especias fajita. 4. Cocina 8 minutos. 5. Calienta tortillas. 6. Rellena con vegetales. 7. Agrega guacamole. 8. Sirve con salsa.`
  },
  { 
    id:54, cat:"cena", emoji:"🥣", title:"Risotto de champiñones", kcal:420, prot:10, carb:62, fat:14,
    ingredientes: ["200g arroz arborio", "300g champiñones", "800ml caldo vegetal", "100ml vino blanco", "1 cebolla", "Levadura nutricional"],
    preparacion: `1. Saltea cebolla. 2. Agrega champiñones cortados. 3. Incorpora arroz. 4. Vierte vino blanco. 5. Agrega caldo lentamente, revolviendo. 6. Cocina 18 minutos. 7. Agrega levadura nutricional. 8. Sirve cremoso.`
  },
  { 
    id:55, cat:"snack", emoji:"🧆", title:"Falafel horneado con tzatziki", kcal:285, prot:14, carb:38, fat:8,
    ingredientes: ["200g garbanzos cocidos", "50g cebolla mediana", "30g perejil fresco", "15g harina de garbanzo", "5g comino molido", "2g sal", "Aceite vegetal en spray"],
    preparacion: `FALAFEL: 1. Cuela 200g de garbanzos cocidos bien (si usas enlatados, enjuágalos bajo agua fría durante 1 minuto). Seca los garbanzos con papel absorbente para remover exceso de humedad. 2. Pela 1 cebolla mediana y córtala en 4 trozos. Coloca en el procesador de alimentos. 3. Lava 30g de perejil fresco, retira los tallos gruesos y coloca solo las hojas en el procesador. 4. Agrega los garbanzos secos al procesador. 5. Añade 5g de comino molido, 2g de sal fina. 6. Procesa durante 45-60 segundos hasta obtener una mezcla grumosa que se asemeje a pan rallado grueso (NO debe ser un puré, debe conservar cierta textura). 7. Vierte la mezcla en un bol. 8. Agrega 15g de harina de garbanzo (actúa como aglutinante). Revuelve bien. 9. Refrigera la mezcla durante 30 minutos en el freezer. 10. Precalienta el horno a 200°C. Cubre una bandeja de horno con papel pergamino. 11. Humedecete ligeramente tus manos con agua. 12. Forma bolas del tamaño de una nuez (aprox. 25g cada una) presionando la mezcla firmemente. Deberías obtener aproximadamente 8-10 falafels. 13. Coloca los falafels en la bandeja, espaciados a 2-3cm uno del otro. 14. Rocía ligeramente cada falafel con aceite vegetal en spray (esto los ayuda a dorarse y crispy). 15. Hornea durante 25-28 minutos hasta que estén dorados. 16. Saca del horno y deja enfriar 5 minutos antes de servir (se endurecerán mientras se enfríen). TZATZIKI: 17. Mientras el falafel hornea, prepara el tzatziki: ralla finamente 100g de pepino fresco. 18. Coloca el pepino rallado en un colador frotándolo suavemente con una cuchara para remover el exceso de agua. 19. En un bol, mezcla 150ml de yogur vegano (de soja o coco), 2 dientes de ajo picados finamente, el pepino drenado, 5g de sal, y jugo de ½ limón fresco. 20. Mezcla bien. Refrigera hasta servir. SERVIDO: 21. Sirve los falafels aún calientes acompañados con el tzatziki frío.`
  },
  { 
    id:56, cat:"snack", emoji:"🥜", title:"Barritas energéticas de dátiles", kcal:180, prot:5, carb:28, fat:7,
    ingredientes: ["150g dátiles", "100g almendras", "50g coco", "30ml aceite coco"],
    preparacion: `1. Licúa dátiles sin hueso. 2. Pica almendras. 3. Mezcla dátiles, almendras, coco, aceite. 4. Presiona en molde. 5. Refrigera 2 horas. 6. Corta en barras.`
  },
  { 
    id:57, cat:"snack", emoji:"🥕", title:"Hummus clásico con crudités", kcal:180, prot:8, carb:22, fat:7,
    ingredientes: ["200g garbanzos", "50ml tahini", "30ml limón", "2g ajo", "Crudités variadas"],
    preparacion: `1. Licúa garbanzos, tahini, limón, ajo. 2. Agrega agua hasta consistencia. 3. Pica vegetales crudos. 4. Sirve hummus en bol central. 5. Rodea con crudités.`
  },
  { 
    id:58, cat:"snack", emoji:"🍿", title:"Palomitas con levadura nutricional", kcal:150, prot:5, carb:22, fat:5,
    ingredientes: ["50g maíz", "30ml aceite coco", "30g levadura nutricional", "Sal"],
    preparacion: `1. Calienta aceite en olla con tapa. 2. Agrega maíz. 3. Cuando deje de sonar, retira. 4. Vierte palomitas en bol. 5. Espolvorea levadura nutricional y sal. 6. Mezcla. 7. Sirve caliente.`
  },
  { 
    id:59, cat:"snack", emoji:"🥒", title:"Rollitos de pepino con hummus", kcal:120, prot:5, carb:14, fat:5,
    ingredientes: ["2 pepinos", "100ml hummus", "30g zanahoria", "Eneldo"],
    preparacion: `1. Corta pepino en tiras largas. 2. Extiende hummus en cada tira. 3. Agrega zanahoria rallada. 4. Enrolla apretadamente. 5. Sujeta con palillos. 6. Refrigera. 7. Decora con eneldo.`
  },
  { 
    id:60, cat:"snack", emoji:"🫘", title:"Edamame con sal de mar", kcal:190, prot:17, carb:8, fat:8,
    ingredientes: ["200g edamame", "Agua", "Sal de mar"],
    preparacion: `1. Hierve agua. 2. Agrega edamame. 3. Cocina 5-7 minutos. 4. Cuela. 5. Espolvorea sal de mar. 6. Sirve caliente.`
  },
  { 
    id:61, cat:"snack", emoji:"🍠", title:"Chips de batata al horno", kcal:160, prot:2, carb:30, fat:4,
    ingredientes: ["300g batata", "30ml aceite", "Sal, pimienta"],
    preparacion: `1. Corta batata en rodajas finas. 2. Coloca en bandeja. 3. Rocía aceite. 4. Sazona. 5. Hornea a 200°C por 25-30 minutos. 6. Sirve crujiente.`
  },
  { 
    id:62, cat:"snack", emoji:"🥑", title:"Guacamole con totopos", kcal:220, prot:3, carb:18, fat:16,
    ingredientes: ["2 aguacates", "1 limón", "1 cebolla", "1 tomate", "Cilantro", "Totopos"],
    preparacion: `1. Corta aguacates por la mitad. 2. Extrae la pulpa. 3. Machaca con tenedor. 4. Mezcla con limón, cebolla, tomate picados. 5. Agrega cilantro. 6. Sirve con totopos.`
  },
  { 
    id:63, cat:"snack", emoji:"🌰", title:"Mix de frutos secos especiados", kcal:200, prot:6, carb:10, fat:16,
    ingredientes: ["50g almendras", "50g nueces", "30g anacardos", "20g especia", "Sal"],
    preparacion: `1. Mezcla frutos secos. 2. Calienta en sartén 3 minutos. 3. Espolvorea sal y especias. 4. Revuelve. 5. Enfría. 6. Sirve.`
  },
  { 
    id:64, cat:"snack", emoji:"🍅", title:"Bruschetta de tomate", kcal:160, prot:4, carb:24, fat:5,
    ingredientes: ["4 tostadas", "3 tomates", "30ml aceite de oliva", "Ajo", "Albahaca"],
    preparacion: `1. Tostan pan. 2. Frota con ajo. 3. Pica tomate. 4. Mezcla con aceite, sal, pimienta. 5. Coloca sobre tostadas. 6. Decora con albahaca.`
  },
  { 
    id:65, cat:"snack", emoji:"🥨", title:"Pretzels suaves veganos", kcal:220, prot:6, carb:42, fat:3,
    ingredientes: ["300g harina", "150ml agua", "7g levadura", "Bicarbonato", "Sal gruesa"],
    preparacion: `1. Prepara masa: harina + agua + levadura. 2. Deja reposar 1 hora. 3. Divide, forma pretzel. 4. Sumerge en agua con bicarbonato. 5. Coloca en bandeja. 6. Espolvorea sal gruesa. 7. Hornea 15 minutos a 200°C.`
  },
  { 
    id:66, cat:"snack", emoji:"🥬", title:"Chips de kale crujientes", kcal:110, prot:4, carb:10, fat:6,
    ingredientes: ["150g kale", "30ml aceite", "Sal"],
    preparacion: `1. Retira tallo del kale. 2. Seca bien. 3. Rocía aceite ligeramente. 4. Sazona con sal. 5. Hornea a 190°C por 12-15 minutos. 6. Sirve crujiente.`
  },
  { 
    id:67, cat:"snack", emoji:"🫓", title:"Crackers de semillas", kcal:140, prot:5, carb:12, fat:8,
    ingredientes: ["100g semillas", "50ml aceite", "100ml agua", "Sal"],
    preparacion: `1. Mezcla semillas con aceite, agua, sal. 2. Extiende en bandeja. 3. Hornea 30 minutos a 180°C. 4. Corta en cuadros. 5. Sirve crujiente.`
  },
  { 
    id:68, cat:"snack", emoji:"🍌", title:"Banana con mantequilla de maní", kcal:260, prot:8, carb:32, fat:12,
    ingredientes: ["2 bananas", "30g mantequilla de maní"],
    preparacion: `1. Pela bananas. 2. Corta en rodajas o por la mitad. 3. Extiende mantequilla de maní. 4. Combina o sirve por separado. 5. Consume inmediatamente.`
  },
  { 
    id:69, cat:"snack", emoji:"🧀", title:"Dip de queso vegano con nachos", kcal:240, prot:6, carb:24, fat:14,
    ingredientes: ["150g queso vegano fundido", "50ml leche vegetal", "30g jalapeño", "Tortillas"],
    preparacion: `1. Calienta queso vegano con leche. 2. Agrega jalapeño picado. 3. Mezcla bien. 4. Calienta tortillas. 5. Corta en triángulos. 6. Fríe. 7. Sirve queso como dip.`
  },
  { 
    id:70, cat:"snack", emoji:"🥭", title:"Rollitos de arroz con mango", kcal:160, prot:3, carb:28, fat:4,
    ingredientes: ["8 envoltorios arroz", "1 mango", "50g lechuga", "30g cacahuete"],
    preparacion: `1. Humedece envoltorios de arroz. 2. Coloca lechuga, mango en rodajas. 3. Enrolla apretadamente. 4. Sirve con salsa cacahuete.`
  },
  { 
    id:71, cat:"snack", emoji:"🫒", title:"Tapenade de aceitunas", kcal:150, prot:2, carb:8, fat:12,
    ingredientes: ["150g aceitunas", "30ml aceite de oliva", "1 limón", "Ajo"],
    preparacion: `1. Licúa aceitunas. 2. Agrega aceite de oliva y ajo. 3. Exprime limón. 4. Mezcla bien. 5. Sirve con pan tostado.`
  },
  { 
    id:72, cat:"postre", emoji:"🍫", title:"Mousse de chocolate y aguacate", kcal:290, prot:4, carb:28, fat:19,
    ingredientes: ["1 aguacate mediano maduro", "100g chocolate negro (70% cacao)", "50ml leche de coco", "10ml miel o sirope de arce", "2ml extracto de vainilla pura", "Cacao en polvo sin azúcar"],
    preparacion: `1. Rompe 100g de chocolate negro (70% cacao) en trozos pequeños. Coloca en un bol apto para microondas. 2. Calienta en microondas a potencia media (50%) durante 1 minuto. Remueve con una cuchara. Si aún no está completamente derretido, calienta 30 segundos más (repite hasta lograr chocolate completamente derretido y suave). Alterna: calienta en una olla pequeña sobre baño María a fuego bajo. 3. Corta 1 aguacate maduro por la mitad, retira el hueso y extrae toda la pulpa a un procesador de alimentos o licuadora. 4. Agrega el chocolate derretido aún caliente al aguacate. 5. Vierte 50ml de leche de coco sin azúcar. 6. Agrega 10ml de miel o sirope de arce. 7. Añade 2ml (½ cucharadita) de extracto de vainilla pura. 8. Procesa/licúa durante 30-45 segundos hasta obtener una textura completamente suave, cremosa y homogénea (sin grumos). 9. Pasa a través de un colador fino (optional, pero proporciona una textura aún más suave). 10. Divide la mousse en 2 vasos o copas pequeñas, llenando aproximadamente 2/3 de su capacidad. 11. Refrigera durante al menos 30 minutos en el congelador (si prefieres una consistencia menos congelada, refrigera en el refrigerador durante 1-2 horas). 12. Justo antes de servir, espolvorea una pequeña cantidad de cacao en polvo sin azúcar sobre la superficie. Puede decorarse con fresas o almendras si deseas. 13. Sirve frío con una cucharita.`
  },
  { 
    id:73, cat:"postre", emoji:"🍪", title:"Galletas de avena y chocolate", kcal:160, prot:3, carb:22, fat:7,
    ingredientes: ["150g avena", "100g harina", "50g chocolate", "50ml aceite", "30ml sirope"],
    preparacion: `1. Precalienta 180°C. 2. Mezcla avena, harina, chocolate picado. 3. Agrega aceite y sirope. 4. Forma bolas. 5. Aplasta sobre bandeja. 6. Hornea 12 minutos.`
  },
  { 
    id:74, cat:"postre", emoji:"🍌", title:"Nice cream de banana", kcal:180, prot:2, carb:42, fat:1,
    ingredientes: ["2 bananas congeladas", "30ml leche almendra", "5ml vainilla"],
    preparacion: `1. Corta bananas congeladas en trozos. 2. Licúa con leche de almendra y vainilla. 3. Licúa hasta obtener helado. 4. Sirve inmediatamente.`
  },
  { 
    id:75, cat:"postre", emoji:"🥧", title:"Tarta de manzana vegana", kcal:280, prot:3, carb:42, fat:12,
    ingredientes: ["1 masa pie", "4 manzanas", "50g azúcar coco", "2g canela", "30ml aceite"],
    preparacion: `1. Precalienta 190°C. 2. Coloca masa en molde. 3. Pela manzanas, corta en rodajas. 4. Mezcla con azúcar y canela. 5. Coloca en masa. 6. Hornea 35 minutos.`
  },
  { 
    id:76, cat:"postre", emoji:"🍮", title:"Panna cotta de coco y mango", kcal:240, prot:2, carb:28, fat:14,
    ingredientes: ["300ml leche coco", "50g azúcar", "15g agar agar", "100g mango"],
    preparacion: `1. Calienta leche de coco con azúcar. 2. Agrega agar agar. 3. Vierte en moldes. 4. Refrigera 2 horas. 5. Desmolda. 6. Sirve con puré de mango.`
  },
  { 
    id:77, cat:"postre", emoji:"🧁", title:"Cupcakes de vainilla veganos", kcal:220, prot:3, carb:32, fat:9,
    ingredientes: ["150g harina", "100ml leche soja", "50ml aceite", "50g azúcar", "5g levadura", "Vainilla"],
    preparacion: `1. Precalienta 180°C. 2. Mezcla ingredientes secos. 3. Añade líquidos. 4. Reparte en moldes. 5. Hornea 18 minutos. 6. Enfría. 7. Decora.`
  },
  { 
    id:78, cat:"postre", emoji:"🫐", title:"Cheesecake vegano de arándanos", kcal:320, prot:6, carb:28, fat:22,
    ingredientes: ["200g galletas", "150g tofu sedoso", "100g queso coco", "50g arándanos", "30ml aceite"],
    preparacion: `1. Precalienta 175°C. 2. Mezcla galletas con aceite. 3. Presiona como base. 4. Licúa tofu con queso de coco. 5. Vierte sobre base. 6. Hornea 30 minutos. 7. Refrigera 4 horas. 8. Decora con arándanos.`
  },
  { 
    id:79, cat:"postre", emoji:"🍫", title:"Brownies veganos de chocolate", kcal:250, prot:4, carb:32, fat:13,
    ingredientes: ["200g harina", "100g chocolate", "100ml aceite", "50ml leche soja", "100g azúcar", "5g levadura"],
    preparacion: `1. Precalienta 180°C. 2. Derrite chocolate. 3. Mezcla con aceite, leche, azúcar. 4. Agrega harina y levadura. 5. Vierte en bandeja. 6. Hornea 20 minutos. 7. Corta en cuadros.`
  },
  { 
    id:80, cat:"postre", emoji:"🍓", title:"Fresas con chocolate fundido", kcal:180, prot:2, carb:24, fat:10,
    ingredientes: ["200g fresas", "100g chocolate negro", "30ml aceite coco"],
    preparacion: `1. Derrite chocolate con aceite. 2. Pela fresas manteniendo verde. 3. Sumerge en chocolate. 4. Coloca en papel pergamino. 5. Refrigera 30 minutos. 6. Sirve frío.`
  },
  { 
    id:81, cat:"postre", emoji:"🥥", title:"Bolitas de coco y limón", kcal:120, prot:2, carb:14, fat:7,
    ingredientes: ["150g coco rallado", "50ml leche coco", "30ml limón", "30g chocolate negro"],
    preparacion: `1. Mezcla coco rallado, leche, limón. 2. Forma bolitas. 3. Refrigera 1 hora. 4. Derrite chocolate. 5. Sumerge bolitas. 6. Refrigera de nuevo.`
  },
  { 
    id:82, cat:"postre", emoji:"🎂", title:"Pastel de zanahoria vegano", kcal:310, prot:5, carb:42, fat:14,
    ingredientes: ["200g zanahoria rallada", "200g harina", "100ml aceite", "100g azúcar", "100ml leche soja", "7g levadura"],
    preparacion: `1. Precalienta 180°C. 2. Mezcla ingredientes secos. 3. Añade aceite, leche, zanahoria. 4. Vierte en molde. 5. Hornea 35 minutos. 6. Enfría y decora.`
  },
  { 
    id:83, cat:"postre", emoji:"🍨", title:"Helado de mango y coco", kcal:210, prot:2, carb:34, fat:8,
    ingredientes: ["200g mango", "150ml leche coco", "30ml sirope", "Vainilla"],
    preparacion: `1. Licúa mango, leche de coco, sirope, vainilla. 2. Vierte en congelador. 3. Remueve cada 30 minutos durante 2-3 horas. 4. O usa heladera.`
  },
  { 
    id:84, cat:"postre", emoji:"🍩", title:"Donas veganas glaseadas", kcal:240, prot:4, carb:36, fat:9,
    ingredientes: ["200g harina", "100ml leche soja", "50ml aceite", "50g azúcar", "Glaseado vegano"],
    preparacion: `1. Precalienta 180°C. 2. Mezcla harina, leche, aceite, azúcar. 3. Vierte en moldes de donas. 4. Hornea 12 minutos. 5. Enfría. 6. Glasa.`
  },
  { 
    id:85, cat:"postre", emoji:"🫐", title:"Crumble de frutas del bosque", kcal:260, prot:4, carb:40, fat:10,
    ingredientes: ["300g frutas mixtas", "100g avena", "50g harina", "50ml aceite", "30g azúcar"],
    preparacion: `1. Precalienta 190°C. 2. Coloca frutas en bandeja. 3. Mezcla avena, harina, aceite, azúcar. 4. Esparce sobre frutas. 5. Hornea 25 minutos.`
  },
  { 
    id:86, cat:"postre", emoji:"🍋", title:"Tarta de limón vegana", kcal:270, prot:3, carb:36, fat:13,
    ingredientes: ["1 masa pie", "150ml jugo limón", "100g azúcar", "50ml aceite", "50g harina maíz"],
    preparacion: `1. Precalienta 180°C. 2. Coloca masa en molde. 3. Mezcla limón, azúcar, aceite, harina. 4. Vierte sobre masa. 5. Hornea 30 minutos.`
  },
  { 
    id:87, cat:"postre", emoji:"🍑", title:"Compota de frutas con granola", kcal:220, prot:4, carb:38, fat:6,
    ingredientes: ["300g frutas variadas", "30ml agua", "15g sirope", "50g granola"],
    preparacion: `1. Pica frutas. 2. Cocina en sartén con agua. 3. Agrega sirope. 4. Cocina 15 minutos. 5. Sirve en bol. 6. Corona con granola.`
  },
  { 
    id:88, cat:"postre", emoji:"🥜", title:"Trufas de chocolate y maní", kcal:140, prot:3, carb:14, fat:9,
    ingredientes: ["100g chocolate", "50g mantequilla maní", "30g coco rallado", "Cacao en polvo"],
    preparacion: `1. Derrite chocolate. 2. Mezcla con mantequilla de maní. 3. Forma bolitas. 4. Refrigera. 5. Rebozo en cacao o coco. 6. Refrigera nuevamente.`
  },
  { 
    id:89, cat:"bebida", emoji:"🥤", title:"Golden latte de cúrcuma", kcal:120, prot:3, carb:10, fat:7,
    ingredientes: ["200ml leche de almendra sin azúcar", "5g cúrcuma fresca molida o polvo", "2g jengibre fresco molido o polvo", "1g pimienta negra", "5ml miel pura", "Pizca de canela (opcional)"],
    preparacion: `1. Vierte 200ml de leche de almendra sin azúcar en una taza de cerámica u olla pequeña. 2. Calienta a fuego medio-bajo (NO dejes que hierva) durante 2-3 minutos, removiendo ocasionalmente, hasta que veas vapor ligero. 3. En un bol pequeño, mezcla: 5g de cúrcuma fresca molida (o polvo), 2g de jengibre molido fresco (o polvo), 1g de pimienta negra recién molida, y 30ml de agua tibia. 4. Revuelve bien esta mezcla de especias durante 30 segundos hasta obtener una pasta homogénea sin grumos (la pimienta es importante porque potencia la absorción de cúrcuma). 5. Vierte lentamente la mezcla de especias en la leche caliente mientras bates vigorosamente con un batidor de mano o batidor de varas. 6. Continúa batiendo durante 1-2 minutos para crear espuma y asegurar que se mezcle bien. 7. Retira del fuego. 8. Vierte en una taza. 9. Drizzle (vierte) 5ml de miel pura sobre la superficie. 10. Si deseas, añade una pequeña pizca de canela molida en la parte superior. 11. Revuelve ligeramente. 12. Sirve inmediatamente (la espuma se mantiene mejor en los primeros 5 minutos). 13. Bebe lentamente. Notas: El jengibre fresco tiene más potencia que el polvo; si usas raíz de jengibre fresco, ralla 10g y cuela antes de servir. La pimienta negra es esencial para mejorar significativamente los beneficios de la cúrcuma.`
  },
  { 
    id:90, cat:"bebida", emoji:"🍵", title:"Matcha latte con leche de avena", kcal:130, prot:3, carb:14, fat:5,
    ingredientes: ["200ml leche avena", "5g matcha en polvo", "50ml agua caliente", "5ml sirope"],
    preparacion: `1. Vierte agua caliente en taza. 2. Agrega matcha en polvo. 3. Bate hasta espuma. 4. Calienta leche de avena. 5. Vierte en taza. 6. Sirve caliente.`
  },
  { 
    id:91, cat:"bebida", emoji:"🥥", title:"Smoothie de coco y piña", kcal:200, prot:2, carb:32, fat:8,
    ingredientes: ["150ml leche coco", "150g piña", "1 banana", "Cubitos hielo"],
    preparacion: `1. Pica piña y banana. 2. Licúa con leche de coco. 3. Agrega hielo. 4. Licúa nuevamente. 5. Sirve inmediatamente. 🍍`
  },
  { 
    id:92, cat:"bebida", emoji:"🍓", title:"Limonada de fresa", kcal:90, prot:1, carb:22, fat:0,
    ingredientes: ["200g fresas frescas maduras", "150ml agua filtrada", "30ml jugo de limón fresco", "15ml sirope de arce puro", "Hielo", "Menta fresca (opcional)"],
    preparacion: `1. Lava 200g de fresas frescas y maduras bajo agua corriente fría. Retira los tallos verdes. 2. Coloca las fresas limpias en una licuadora. 3. Licúa durante 45-60 segundos hasta obtener un puré suave sin semillas visibles. 4. Cuela el puré a través de un colador fino sobre un bol o jarra, presionando con el dorso de una cuchara para extraer todo el líquido y la pulpa. Desecha las semillas. 5. En una jarra de vidrio, vierte el jugo de fresa colado. 6. Exprime ½ limón fresco para obtener 30ml de jugo (cuela para remover semillas y pulpa si es necesario). Vierte el jugo en la jarra. 7. Agrega 150ml de agua filtrada fría. 8. Vierte 15ml de sirope de arce puro. 9. Revuelve bien durante 20 segundos hasta que todo esté bien mezclado. 10. Prueba el sabor: debe tener un equilibrio entre dulce y ácido. Ajusta según preferencia. 11. Llena vasos highball con hielo hasta 2/3 de su capacidad. 12. Vierte la limonada de fresa lentamente en cada vaso sobre el hielo. 13. Si deseas, coloca 2-3 hojas frescas de menta en la parte superior o un trozo de fresa fresca como decoración. 14. Coloca una pajita. 15. Sirve inmediatamente mientras está fría. 16. La limonada se puede mantener en el refrigerador hasta 24 horas (el sabor y color cambian ligeramente después).`
  },
  { 
    id:93, cat:"bebida", emoji:"🥕", title:"Jugo de zanahoria y naranja", kcal:120, prot:2, carb:28, fat:0,
    ingredientes: ["200g zanahoria", "200g naranja", "50ml agua"],
    preparacion: `1. Exprime naranjas o licúa. 2. Extrae jugo de zanahoria. 3. Mezcla. 4. Agrega agua si es necesario. 5. Sirve fresco.`
  },
  { 
    id:94, cat:"bebida", emoji:"🫖", title:"Chai latte vegano", kcal:110, prot:2, carb:16, fat:4,
    ingredientes: ["200ml leche soja", "1 bolsa té chai", "5ml miel", "1 rama canela"],
    preparacion: `1. Calienta leche de soja. 2. Agrega bolsa de té chai. 3. Deja reposar 5 minutos. 4. Retira bolsa. 5. Agrega miel. 6. Sirve con canela.`
  },
  { 
    id:95, cat:"bebida", emoji:"🍫", title:"Chocolate caliente vegano", kcal:200, prot:4, carb:28, fat:8,
    ingredientes: ["200ml leche soja", "30g cacao en polvo", "30g azúcar", "5ml vainilla"],
    preparacion: `1. Calienta leche de soja. 2. Mezcla cacao y azúcar. 3. Agrega poco a poco a la leche. 4. Bate bien. 5. Agrega vainilla. 6. Sirve caliente.`
  },
  { 
    id:96, cat:"bebida", emoji:"🍉", title:"Agua fresca de sandía", kcal:60, prot:1, carb:14, fat:0,
    ingredientes: ["300g sandía", "200ml agua", "15ml limón", "Hielo"],
    preparacion: `1. Pica sandía. 2. Licúa con agua. 3. Cuela. 4. Agrega limón. 5. Sirve con hielo.`
  },
  { 
    id:97, cat:"bebida", emoji:"🥬", title:"Jugo verde detox", kcal:80, prot:2, carb:18, fat:0,
    ingredientes: ["100g espinaca", "1 manzana", "100g pepino", "50ml limón", "100ml agua"],
    preparacion: `1. Licúa espinaca, manzana, pepino. 2. Agrega limón y agua. 3. Cuela si deseas. 4. Sirve inmediatamente. 💚`
  },
  { 
    id:98, cat:"bebida", emoji:"🫚", title:"Té de jengibre y limón", kcal:40, prot:0, carb:10, fat:0,
    ingredientes: ["200ml agua", "10g jengibre fresco", "30ml limón", "5ml miel"],
    preparacion: `1. Calienta agua. 2. Agrega jengibre cortado. 3. Deja reposar 5 minutos. 4. Cuela. 5. Agrega limón y miel. 6. Sirve caliente.`
  },
  { 
    id:99, cat:"bebida", emoji:"🍑", title:"Smoothie de durazno y vainilla", kcal:160, prot:3, carb:30, fat:3,
    ingredientes: ["200g durazno", "150ml leche almendra", "5ml vainilla", "Hielo"],
    preparacion: `1. Pela durazno. 2. Licúa con leche de almendra y vainilla. 3. Agrega hielo. 4. Licúa nuevamente. 5. Sirve inmediatamente.`
  },
  { 
    id:100, cat:"bebida", emoji:"🍇", title:"Agua de jamaica", kcal:70, prot:0, carb:18, fat:0,
    ingredientes: ["20g flor de jamaica", "500ml agua", "30ml limón", "15ml sirope"],
    preparacion: `1. Hierve agua. 2. Agrega flores de jamaica. 3. Deja reposar 10 minutos. 4. Cuela. 5. Agrega limón y sirope. 6. Sirve frío.`
  },
  { 
    id:101, cat:"bebida", emoji:"🥒", title:"Agua de pepino y limón", kcal:15, prot:0, carb:4, fat:0,
    ingredientes: ["200g pepino", "1 limón", "1L agua", "Hielo", "Menta"],
    preparacion: `1. Corta pepino en rodajas. 2. Corta limón en rodajas. 3. Coloca en jarra con agua. 4. Agrega menta. 5. Refrigera 1 hora. 6. Sirve con hielo.`
  },
  { 
    id:102, cat:"bebida", emoji:"🫐", title:"Smoothie de arándanos y avena", kcal:240, prot:8, carb:40, fat:5,
    ingredientes: ["150g arándanos", "200ml leche soja", "30g avena", "5ml vainilla"],
    preparacion: `1. Licúa arándanos, avena, leche de soja. 2. Agrega vainilla. 3. Licúa bien. 4. Si es muy espeso, agrega más leche. 5. Sirve inmediatamente.`
  },
  { 
    id:103, cat:"bebida", emoji:"☕", title:"Café helado con leche de coco", kcal:100, prot:1, carb:12, fat:5,
    ingredientes: ["150ml café", "100ml leche coco", "Hielo", "5ml sirope"],
    preparacion: `1. Prepara café espresso o fuerte. 2. Enfría. 3. Vierte en vaso con hielo. 4. Agrega leche de coco. 5. Agrega sirope. 6. Mezcla y sirve.`
  },
  { 
    id:104, cat:"bebida", emoji:"🍊", title:"Zumo de naranja y remolacha", kcal:110, prot:2, carb:26, fat:0,
    ingredientes: ["200g naranja", "100g remolacha", "50ml agua"],
    preparacion: `1. Exprime naranjas. 2. Licúa o exprime remolacha. 3. Mezcla. 4. Agrega agua si es necesario. 5. Sirve fresco. 🧡`
  },
  { 
    id:105, cat:"bebida", emoji:"🌿", title:"Infusión de menta y hierba luisa", kcal:5, prot:0, carb:1, fat:0,
    ingredientes: ["200ml agua", "5g menta fresca", "5g hierba luisa", "Limón"],
    preparacion: `1. Calienta agua. 2. Agrega menta y hierba luisa. 3. Deja reposar 5 minutos. 4. Cuela. 5. Agrega limón si lo deseas. 6. Sirve caliente o fría.`
  },
];

const cats = [
  { key: "all", label: "Todas" },
  { key: "desayuno", label: "🌅 Desayuno" },
  { key: "almuerzo", label: "☀️ Almuerzo" },
  { key: "cena", label: "🌙 Cena" },
  { key: "snack", label: "🍎 Snack" },
  { key: "postre", label: "🍰 Postre" },
  { key: "bebida", label: "🥤 Bebida" },
];

const catLabels = {
  desayuno: "🌅 Desayuno",
  almuerzo: "☀️ Almuerzo",
  cena: "🌙 Cena",
  snack: "🍎 Snack",
  postre: "🍰 Postre",
  bebida: "🥤 Bebida",
};

function toQuickFood(recipe) {
  return {
    name: recipe.title,
    emoji: recipe.emoji,
    cal: recipe.kcal,
    prot: recipe.prot,
    carb: recipe.carb,
    fat: recipe.fat,
    fiber: 0,
    sugar: 0,
    iron: 0,
    calcium: 0,
    b12: 0,
    zinc: 0,
    per: 'porción',
    cat: recipe.cat,
  };
}

function toFoodDbEntry(recipe) {
  return {
    name: recipe.title.toLowerCase(),
    aliases: [recipe.cat],
    emoji: recipe.emoji,
    cal: recipe.kcal,
    prot: recipe.prot,
    carb: recipe.carb,
    fat: recipe.fat,
    fiber: 0,
    sugar: 0,
    iron: 0,
    calcium: 0,
    b12: 0,
    zinc: 0,
    cat: recipe.cat,
    recipeId: recipe.id,
  };
}

const quickFoods = recipeCatalog.map(toQuickFood);
const foodDatabase = recipeCatalog.map(toFoodDbEntry);
