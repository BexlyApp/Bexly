import 'package:flutter/material.dart';

// --- Define Colors ---
const Color kPrimaryPurple = Color(0xFF6A00F4);
const Color kMutedTextColor = Colors.black54;
const Color kTextColor = Colors.black87;
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kLightGray = Color(0xFFF5F5F5);
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kWhiteColor = Colors.white;
const Color kIconColor = Colors.black54;

// --- Real Image URLs for Receipts and Invoices ---
const List<Map<String, String>> generalReceipts = [
  {'imageUrl': 'https://cdn.pixabay.com/photo/2017/09/07/08/54/money-2724241_640.jpg', 'label': 'General Invoice 1'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/22/23/44/porsche-1851246_640.jpg', 'label': 'General Invoice 2'},

  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/03/26/22/21/books-1281581_640.jpg', 'label': 'General Invoice 3'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/22/23/44/porsche-1851246_640.jpg', 'label': 'General Invoice 4'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/03/26/22/21/books-1281581_640.jpg', 'label': 'General Invoice 5'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/22/23/44/porsche-1851246_640.jpg', 'label': 'General Invoice 6'},
];

const List<Map<String, String>> purchaseReceipts = [
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/17/09/28/hotel-1831072_640.jpg', 'label': 'Bus Ticket Booking'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/17/09/28/hotel-1831072_640.jpg', 'label': 'Car Booking'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/17/09/28/hotel-1831072_640.jpg', 'label': 'Coffee Shop Invoice'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/17/09/28/hotel-1831072_640.jpg', 'label': 'Flight Booking Invoice'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/17/09/28/hotel-1831072_640.jpg', 'label': 'Hotel Booking Invoice'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2017/06/20/22/14/man-2425121_640.jpg', 'label': 'Internet Billing Invoice'},
];

const List<Map<String, String>> cashReceipts = [
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/22/23/44/porsche-1851246_640.jpg', 'label': 'Cash receipt 1'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/22/23/44/porsche-1851246_640.jpg', 'label': 'Cash receipt 2'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/22/23/44/porsche-1851246_640.jpg', 'label': 'Cash receipt 3'},
  {'imageUrl': 'https://cdn.pixabay.com/photo/2016/11/22/23/44/porsche-1851246_640.jpg', 'label': 'Cash receipt 4'},
];

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  int _selectedTabIndex = 0;

  final List<String> _tabTitles = ['General', 'Purchase', 'Receipt'];

  List<Map<String, String>> _getCurrentDataList() {
    switch (_selectedTabIndex) {
      case 0:
        return generalReceipts;
      case 1:
        return purchaseReceipts;
      case 2:
        return cashReceipts;
      default:
        return [];
    }
  }

  void _navigateToAddScreen() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add ${_tabTitles[_selectedTabIndex]}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _getCurrentDataList();
    final currentTitle = _tabTitles[_selectedTabIndex];
    final showTotalHeader = _selectedTabIndex == 2;
    final totalCount = currentData.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(currentTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26, color: kTextColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search Action')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: kWhiteColor,
        foregroundColor: kTextColor,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          if (showTotalHeader) _buildListHeader('Total Receipt', totalCount),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.7,
              ),
              itemCount: currentData.length,
              itemBuilder: (context, index) {
                return ReceiptGridItem(
                  imageUrl: currentData[index]['imageUrl']!,
                  label: currentData[index]['label']!,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped on ${currentData[index]['label']}')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        backgroundColor: kPrimaryPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: const Icon(Icons.add, color: kWhiteColor),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: kWhiteColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabTitles.length, (index) {
          final bool isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 3,
                      color: isSelected ? kPrimaryPurple : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  _tabTitles[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? kPrimaryPurple : kMutedTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildListHeader(String title, int count) {
    return Container(
      width: double.infinity,
      color: kWhiteColor,
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 10.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextColor),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: kAccentGreen.withAlpha((0.9 * 255).toInt()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: kWhiteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiptGridItem extends StatelessWidget {
  final String imageUrl;
  final String label;
  final VoidCallback onTap;

  const ReceiptGridItem({
    super.key,
    required this.imageUrl,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: kBorderColor.withAlpha((0.9 * 255).toInt())),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.9 * 255).toInt()),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
