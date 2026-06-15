import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/shop_models.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'all';
  late List<Product> _filtered;
  int? _expandedProductId;

  @override
  void initState() {
    super.initState();
    _updateFiltered();
  }

  void _updateFiltered() {
    if (_selectedCategory == 'all') {
      _filtered = SHOP_PRODUCTS;
    } else {
      _filtered =
          SHOP_PRODUCTS.where((p) => p.category == _selectedCategory).toList();
    }

    final containsExpanded = _filtered.any((p) => p.id == _expandedProductId);
    if (!containsExpanded) {
      _expandedProductId = null;
    }
  }

  void _onCategoryChanged(String cat) {
    setState(() {
      _selectedCategory = cat;
      _updateFiltered();
    });
  }

  void _toggleExpanded(Product product) {
    setState(() {
      if (_expandedProductId == product.id) {
        _expandedProductId = null;
      } else {
        _expandedProductId = product.id;
      }
    });
  }

  Future<void> _launchRedbubble(Product product) async {
    final uri = Uri.parse('https://www.redbubble.com/shop/${product.redbubbleSlug}/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir la pagina de compra.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda VerdeMeta'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2E8A5E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFF2E8A5E),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Merch Oficial VerdeMeta',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ropa y accesorios para vivir lo verde',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFD2E4D7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryButton(
                      label: 'Todo',
                      icon: '🏪',
                      isSelected: _selectedCategory == 'all',
                      onTap: () => _onCategoryChanged('all'),
                    ),
                    const SizedBox(width: 8),
                    _CategoryButton(
                      label: 'Ropa',
                      icon: '👕',
                      isSelected: _selectedCategory == 'ropa',
                      onTap: () => _onCategoryChanged('ropa'),
                    ),
                    const SizedBox(width: 8),
                    _CategoryButton(
                      label: 'Accesorios',
                      icon: '🎒',
                      isSelected: _selectedCategory == 'accesorios',
                      onTap: () => _onCategoryChanged('accesorios'),
                    ),
                  ],
                ),
              ),
            ),

            // Products
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: _filtered.map((product) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProductCard(
                      product: product,
                      isExpanded: _expandedProductId == product.id,
                      onCardTap: () => _toggleExpanded(product),
                      onBuyTap: () => _launchRedbubble(product),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E8A5E) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E8A5E) : const Color(0xFFDCEBDD),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF234734),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isExpanded;
  final VoidCallback onCardTap;
  final VoidCallback onBuyTap;

  const _ProductCard({
    required this.product,
    required this.isExpanded,
    required this.onCardTap,
    required this.onBuyTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? const Color(0xFF2E8A5E) : const Color(0xFFDCEBDD),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isExpanded ? 0.08 : 0.05),
              blurRadius: isExpanded ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Stack(
              children: [
                Container(
                  height: isExpanded ? 230 : 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FCF8),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          insetPadding: const EdgeInsets.all(16),
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: InteractiveViewer(
                              panEnabled: true,
                              scaleEnabled: true,
                              child: Image.network(
                                product.image,
                                fit: BoxFit.contain,
                                headers: const {
                                  'User-Agent': 'Mozilla/5.0',
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFF3F8F3),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.grey[500],
                                          size: 42,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Imagen no disponible',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF7F8B81),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(isExpanded ? 15 : 15)),
                      child: Image.network(
                        product.image,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        headers: const {
                          'User-Agent': 'Mozilla/5.0',
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: const Color(0xFF2E8A5E),
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF3F8F3),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey[500],
                                  size: 34,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Imagen no disponible',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7F8B81),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Badge
                if (product.badge != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _BadgeWidget(badge: product.badge!),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category == 'ropa' ? '👕 Ropa' : '🎒 Accesorios',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A9E90),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    maxLines: isExpanded ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF234734),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: isExpanded ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A9E90),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFDCEBDD),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2E8A5E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (product.oldPrice != null)
                          Text(
                            '\$${product.oldPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: Color(0xFFB0B0B0),
                            ),
                          ),
                        const Spacer(),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: const Color(0xFF2E8A5E),
                        ),
                      ],
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onBuyTap,
                        icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                        label: const Text(
                          'Comprar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8A5E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _BadgeWidget extends StatelessWidget {
  final String badge;

  const _BadgeWidget({required this.badge});

  @override
  Widget build(BuildContext context) {
    final config = badgeConfig[badge];
    if (config == null) return const SizedBox.shrink();

    final emoji = config['emoji'] as String;
    final label = config['label'] as String;
    final color = config['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $label',
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
