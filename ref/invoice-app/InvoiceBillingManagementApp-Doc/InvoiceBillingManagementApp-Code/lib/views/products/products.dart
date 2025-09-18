import 'package:flutter/material.dart';

import 'addcategory.dart';
import 'addnew.dart';
import 'addunit.dart';

// Assuming these files exist in your project structure


// --- Color Constants (Sampled from Image) ---
const Color kPrimaryPurple = Color(0xFF6A00F4); // Adjusted Purple
const Color kLightPurple = Color(0xFFF2E6FF); // Light purple for tags/bg
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kTagBgColor = Color(0xFFFFF0E0); // Light orange/peach for tags
const Color kTagTextColor = Color(0xFFFA8100); // Orange text for tags
const Color kTextColor = Colors.black87;
const Color kMutedTextColor = Colors.black54;
const Color kLightGray = Color(0xFFF5F5F5);
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kPriceColor = Color(0xFFE53935); // Red for struck-out price
const Color kIconColor = Colors.black54;


// Renamed for clarity, matches previous examples, but ProductsScreen is also fine
class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key}); // Use ProductCatalogScreen if preferred

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  int _currentIndex = 0; // 0: Products, 1: Categories, 2: Units
  late PageController _pageController;

  // Placeholder Data (Keep as is or replace with your data source)
  final List<Map<String, dynamic>> _products = List.generate(
    10,
        (index) => {
      'id': '#P1253${90 - index}',
      'name': [
        'Beats Pro',
        'Nike Jordan',
        'iPhone 14 Pro',
        'Woodcraft Sandal',
        'Amazon Echo Dot',
        'Samsung Galaxy Tab',
        'Logitech MX Master 3',
        'Adidas Running Shoes',
        'Sony WH-1000XM4',
        'Backpack Classic'
      ][index],
      'category': [
        'Electronics',
        'Shoes',
        'Mobile Phones',
        'Shoes',
        'Electronics',
        'Tablets',
        'Accessories',
        'Shoes',
        'Electronics',
        'Bags'
      ][index],
      'alertQty': 10,
      'price': [130.0, 253.0, 280.0, 253.0, 50.0, 320.0, 99.0, 210.0, 350.0, 80.0][index],
      'oldPrice': [null, 248.0, null, 248.0, null, 310.0, 109.0, 200.0, 370.0, 90.0][index],
      'imageUrl': [
        'https://img.icons8.com/fluency/96/headphones.png',
        'https://img.icons8.com/color/96/trainers.png',
        'https://img.icons8.com/fluency/96/iphone14-pro.png',
        'https://img.icons8.com/color/96/backpack.png',
        'https://img.icons8.com/fluency/96/iphone14-pro.png',
        'https://img.icons8.com/fluency/96/samsung.png',
        'https://img.icons8.com/color/96/mouse.png',
        'https://img.icons8.com/color/96/backpack.png',
        'https://img.icons8.com/color/96/headphones.png',
        'https://img.icons8.com/color/96/backpack.png',
      ][index],
    },
  );


  final List<Map<String, dynamic>> _categories = List.generate(
    8,
        (index) => {
      'name': [
        'Electronics',
        'Shoes',
        'Mobile Phones',
        'Speakers',
        'Bags',
        'Tablets',
        'Accessories',
        'Wearables'
      ][index],
      'count': [15, 20, 30, 15, 40, 10, 25, 12][index],
    },
  );


  final List<Map<String, dynamic>> _units = [
    {'name': 'Kilogram', 'symbol': 'kg'},
    {'name': 'Gram', 'symbol': 'g'},
    {'name': 'Liter', 'symbol': 'L'},
    {'name': 'Millimeter', 'symbol': 'mm'},
    {'name': 'Piece', 'symbol': 'Pc'},
    {'name': 'Pack', 'symbol': 'pk'},
    {'name': 'Box', 'symbol': 'bx'},
    {'name': 'Dozen', 'symbol': 'dz'},
  ];


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // --- Navigation Logic ---
  void _navigateToAddScreen() {
    Widget? nextPage;
    switch (_currentIndex) {
      case 0: // Products
        nextPage = const AddNewProductScreen();
        break;
      case 1: // Categories
        nextPage = const AddNewCategoryScreen();
        break;
      case 2: // Units
        nextPage = const AddNewUnitsScreen();
        break;
    }
    if (nextPage != null && mounted) { // Check if widget is still mounted
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => nextPage!),
      );
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          ['Products', 'Categories', 'Units'][_currentIndex], // Dynamic title
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            onPressed: () {
              // Handle search action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search not implemented yet.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        // Consistent AppBar styling (optional)
        backgroundColor: Colors.white,
        foregroundColor: kTextColor,
        elevation: 0.5, // Slight elevation to separate from body
      ),
      body: Column(
        children: [
          _buildCustomTabBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildProductsList(),
                _buildCategoriesList(),
                _buildUnitsGrid(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen, // Use the extracted navigation logic
        backgroundColor: kPrimaryPurple,
        elevation: 4.0,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // --- Custom Tab Bar Widget --- (Now inside State class)
  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: kLightGray,
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        children: [
          _buildTabItem(index: 0, label: 'Products'),
          _buildTabItem(index: 1, label: 'Categories'),
          _buildTabItem(index: 2, label: 'Units'),
        ],
      ),
    );
  }

  Widget _buildTabItem({required int index, required String label}) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : kMutedTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // --- Header Row for Lists/Grids --- (Now inside State class)
  Widget _buildListHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kTextColor),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kAccentGreen.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                      color: kAccentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildActionButton(icon: Icons.add, onTap: _navigateToAddScreen), // Use extracted logic
              const SizedBox(width: 10),
              _buildActionButton(icon: Icons.filter_list, onTap: () {
                // Add filter logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filter not implemented yet.')),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap}) {
    // (Now inside State class)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimaryPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }


  // --- Content Widgets for PageView --- (Now inside State class)

  Widget _buildProductsList() {
    return Column(
      children: [
        _buildListHeader('Total Products', _products.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return ProductListItem( // Keep separate item widgets outside State if preferred
                id: product['id'],
                name: product['name'],
                category: product['category'],
                alertQty: product['alertQty'],
                price: product['price'],
                oldPrice: product['oldPrice'],
                imageUrl: product['imageUrl'],
                onEdit: () { /* Handle Edit */ },
                onDelete: () { /* Handle Delete */ },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    return Column(
      children: [
        _buildListHeader('Total Categories', _categories.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return CategoryListItem( // Keep separate item widgets outside State if preferred
                name: category['name'],
                productCount: category['count'],
                onEdit: () { /* Handle Edit */ },
                onDelete: () { /* Handle Delete */ },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnitsGrid() {
    return Column(
      children: [
        _buildListHeader('Total Units', _units.length),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 1.4,
            ),
            itemCount: _units.length,
            itemBuilder: (context, index) {
              final unit = _units[index];
              return UnitGridItem( // Keep separate item widgets outside State if preferred
                name: unit['name'],
                symbol: unit['symbol'],
                onEdit: () { /* Handle Edit */ },
                onDelete: () { /* Handle Delete */ },
              );
            },
          ),
        ),
      ],
    );
  }


  // --- Common Helper Widgets --- (Now inside State class)



} // End of _ProductCatalogScreenState



class ProductListItem extends StatelessWidget {
  // ... (Keep implementation as before) ...
  final String id;
  final String name;
  final String category;
  final int alertQty;
  final double price;
  final double? oldPrice;
  final String imageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductListItem({super.key,
    required this.id,
    required this.name,
    required this.category,
    required this.alertQty,
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    required this.onEdit,
    required this.onDelete,
  });

  // Helper method specific to this item, moved here for better encapsulation
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: kTagBgColor, // Light orange/peach
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 10, color: kTagTextColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Helper method specific to this item, moved here for better encapsulation
  Widget _buildItemAction({required IconData icon, required VoidCallback onTap}) {
    return InkWell( // Make icon tappable
      onTap: onTap,
      borderRadius: BorderRadius.circular(4), // Match container radius
      child: Container(
        padding: const EdgeInsets.all(6), // Adjust padding as needed
        decoration: BoxDecoration(
          color: kLightGray, // Light grey background for icon button
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: kIconColor),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt()))
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Image Placeholder/Actual Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kLightGray,
                borderRadius: BorderRadius.circular(8.0),
              ),
              // Use Image.network for better error handling if needed
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Return a placeholder widget on error
                  return const Icon(Icons.broken_image_outlined, color: kMutedTextColor, size: 30);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child; // Image loaded
                  return Center( // Show progress indicator while loading
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryPurple),
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null, // Indeterminate progress if total size unknown
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id, style: const TextStyle(fontSize: 11, color: kMutedTextColor)),
                  const SizedBox(height: 4),
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTag(category), // Use the helper method from this class
                      const SizedBox(width: 8),
                      Text(
                        'Alert Quantity : $alertQty',
                        style: const TextStyle(fontSize: 11, color: kMutedTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions & Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildItemAction(icon: Icons.edit_outlined, onTap: onEdit), // Use helper
                    const SizedBox(width: 8),
                    _buildItemAction(icon: Icons.delete_outline, onTap: onDelete), // Use helper
                  ],
                ),
                const SizedBox(height: 15), // Spacer
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (oldPrice != null)
                      Text(
                        '\$${oldPrice?.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: kPriceColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (oldPrice != null) const SizedBox(width: 4),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kTextColor),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryListItem extends StatelessWidget {
  // ... (Keep implementation as before) ...
  final String name;
  final int productCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryListItem({super.key,
    required this.name,
    required this.productCount,
    required this.onEdit,
    required this.onDelete
  });

  // Helper method specific to this item, moved here for better encapsulation
  Widget _buildTag(String text) {
    // Copied from _ProductListItem - consider making a truly common widget if desired
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: kTagBgColor, // Light orange/peach
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 10, color: kTagTextColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Helper method specific to this item, moved here for better encapsulation
  Widget _buildItemAction({required IconData icon, required VoidCallback onTap}) {
    // Copied from _ProductListItem - consider making a truly common widget if desired
    return InkWell( // Make icon tappable
      onTap: onTap,
      borderRadius: BorderRadius.circular(4), // Match container radius
      child: Container(
        padding: const EdgeInsets.all(6), // Adjust padding as needed
        decoration: BoxDecoration(
          color: kLightGray, // Light grey background for icon button
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: kIconColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt()))
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                  const SizedBox(height: 6),
                  Text(
                    'Total Number of Products : $productCount',
                    style: const TextStyle(fontSize: 12, color: kMutedTextColor),
                  ),
                  const SizedBox(height: 10),
                  _buildTag(name), // Use helper method from this class
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildItemAction(icon: Icons.edit_outlined, onTap: onEdit), // Use helper
                const SizedBox(width: 10),
                _buildItemAction(icon: Icons.delete_outline, onTap: onDelete), // Use helper
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UnitGridItem extends StatelessWidget {
  // ... (Keep implementation as before) ...
  final String name;
  final String symbol;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UnitGridItem({super.key,
    required this.name,
    required this.symbol,
    required this.onEdit,
    required this.onDelete
  });

  // Helper method specific to this item, moved here for better encapsulation
  Widget _buildTag(String text) {
    // Copied from _ProductListItem - consider making a truly common widget if desired
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: kTagBgColor, // Light orange/peach
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 10, color: kTagTextColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Helper method specific to this item, moved here for better encapsulation
  Widget _buildItemAction({required IconData icon, required VoidCallback onTap}) {
    // Copied from _ProductListItem - consider making a truly common widget if desired
    return InkWell( // Make icon tappable
      onTap: onTap,
      borderRadius: BorderRadius.circular(4), // Match container radius
      child: Container(
        padding: const EdgeInsets.all(6), // Adjust padding as needed
        decoration: BoxDecoration(
          color: kLightGray, // Light grey background for icon button
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: kIconColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: kBorderColor.withAlpha((0.2 * 255).toInt()))
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextColor)),
                const SizedBox(height: 8),
                _buildTag('Symbol : $symbol'), // Use helper method from this class
              ],
            ),
            // Actions at the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.start, // Align actions left
              children: [
                _buildItemAction(icon: Icons.edit_outlined, onTap: onEdit), // Use helper
                const SizedBox(width: 10),
                _buildItemAction(icon: Icons.delete_outline, onTap: onDelete), // Use helper
              ],
            )
          ],
        ),
      ),
    );
  }
}