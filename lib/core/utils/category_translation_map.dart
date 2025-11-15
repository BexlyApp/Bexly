/// Category translation mapping for AI category matching
///
/// AI always returns English category names for consistency.
/// This map helps match English names to localized category titles in database.
///
/// Structure: English key → List of possible translations in different languages
class CategoryTranslationMap {
  static const Map<String, List<String>> mapping = {
    // Food & Drinks
    'Food': [
      'Food & Drinks',
      'Food',
      'Ăn uống',
      'Đồ ăn',
      '食品',
      '食物',
      '餐饮',
    ],
    'Groceries': [
      'Groceries',
      'Tạp hóa',
      'Siêu thị',
      '杂货',
      '超市',
    ],
    'Restaurants': [
      'Restaurants',
      'Dining',
      'Nhà hàng',
      'Ăn ngoài',
      '餐厅',
      '餐馆',
    ],
    'Coffee': [
      'Coffee',
      'Café',
      'Cà phê',
      '咖啡',
    ],
    'Snacks': [
      'Snacks',
      'Đồ ăn vặt',
      '零食',
    ],

    // Transportation
    'Transportation': [
      'Transportation',
      'Transport',
      'Di chuyển',
      'Giao thông',
      '交通',
      '运输',
    ],
    'Public Transport': [
      'Public Transport',
      'Phương tiện công cộng',
      '公共交通',
    ],
    'Taxi': [
      'Taxi',
      'Ride-hailing',
      'Taxi',
      'Xe ôm',
      '出租车',
      '打车',
    ],
    'Fuel': [
      'Fuel',
      'Gas',
      'Xăng',
      'Nhiên liệu',
      '燃料',
      '汽油',
    ],

    // Entertainment
    'Entertainment': [
      'Entertainment',
      'Giải trí',
      '娱乐',
    ],
    'Movies': [
      'Movies',
      'Cinema',
      'Phim',
      'Rạp chiếu phim',
      '电影',
      '影院',
    ],
    'Music': [
      'Music',
      'Streaming',
      'Âm nhạc',
      'Nhạc',
      '音乐',
    ],
    'Sports': [
      'Sports',
      'Thể thao',
      '体育',
      '运动',
    ],
    'Games': [
      'Games',
      'Gaming',
      'Trò chơi',
      'Game',
      '游戏',
    ],

    // Shopping
    'Shopping': [
      'Shopping',
      'Mua sắm',
      '购物',
    ],
    'Clothing': [
      'Clothing',
      'Fashion',
      'Quần áo',
      'Thời trang',
      '服装',
      '衣服',
    ],
    'Electronics': [
      'Electronics',
      'Điện tử',
      'Đồ điện tử',
      '电子产品',
    ],

    // Healthcare
    'Healthcare': [
      'Healthcare',
      'Health',
      'Y tế',
      'Sức khỏe',
      '医疗',
      '健康',
    ],
    'Medicine': [
      'Medicine',
      'Pharmacy',
      'Thuốc',
      'Dược phẩm',
      '药品',
      '医药',
    ],
    'Doctor': [
      'Doctor',
      'Clinic',
      'Bác sĩ',
      'Phòng khám',
      '医生',
      '诊所',
    ],

    // Bills & Utilities
    'Bills': [
      'Bills',
      'Utilities',
      'Hóa đơn',
      'Tiện ích',
      '账单',
      '水电费',
    ],
    'Electricity': [
      'Electricity',
      'Electric',
      'Điện',
      '电费',
    ],
    'Water': [
      'Water',
      'Nước',
      '水费',
    ],
    'Internet': [
      'Internet',
      'Broadband',
      'Mạng',
      'Internet',
      '网络',
      '宽带',
    ],
    'Phone': [
      'Phone',
      'Mobile',
      'Điện thoại',
      'Di động',
      '电话费',
      '手机',
    ],
    'Rent': [
      'Rent',
      'Tiền nhà',
      'Thuê nhà',
      '房租',
    ],

    // Education
    'Education': [
      'Education',
      'Giáo dục',
      '教育',
    ],
    'Tuition': [
      'Tuition',
      'School fees',
      'Học phí',
      '学费',
    ],
    'Books': [
      'Books',
      'Sách',
      '书籍',
    ],

    // Personal Care
    'Personal Care': [
      'Personal Care',
      'Beauty',
      'Chăm sóc cá nhân',
      'Làm đẹp',
      '个人护理',
      '美容',
    ],
    'Haircut': [
      'Haircut',
      'Salon',
      'Cắt tóc',
      'Salon',
      '理发',
    ],

    // Gifts & Donations
    'Gifts': [
      'Gifts',
      'Presents',
      'Quà tặng',
      '礼物',
    ],
    'Donations': [
      'Donations',
      'Charity',
      'Từ thiện',
      'Quyên góp',
      '捐赠',
      '慈善',
    ],

    // Insurance
    'Insurance': [
      'Insurance',
      'Bảo hiểm',
      '保险',
    ],

    // Pets
    'Pets': [
      'Pets',
      'Thú cưng',
      '宠物',
    ],

    // Travel
    'Travel': [
      'Travel',
      'Vacation',
      'Du lịch',
      'Nghỉ dưỡng',
      '旅游',
      '度假',
    ],
    'Hotel': [
      'Hotel',
      'Accommodation',
      'Khách sạn',
      'Chỗ ở',
      '酒店',
      '住宿',
    ],

    // Income categories
    'Salary': [
      'Salary',
      'Income',
      'Lương',
      'Thu nhập',
      '工资',
      '收入',
    ],
    'Bonus': [
      'Bonus',
      'Thưởng',
      '奖金',
    ],
    'Investment': [
      'Investment',
      'Đầu tư',
      '投资',
    ],
    'Freelance': [
      'Freelance',
      'Side hustle',
      'Làm thêm',
      'Tự do',
      '自由职业',
    ],

    // General/Other
    'General': [
      'General',
      'Other',
      'Miscellaneous',
      'Chung',
      'Khác',
      '其他',
      '通用',
    ],
  };

  /// Find matching category from database by English keyword
  /// Returns null if no match found
  static String? findMatchingCategory(
    String englishKeyword,
    List<String> availableCategoriesInDb,
  ) {
    // Get possible translations for this English keyword
    final possibleNames = mapping[englishKeyword];
    if (possibleNames == null) {
      return null;
    }

    // Try to find a match in database categories (case-insensitive)
    for (final possibleName in possibleNames) {
      for (final dbCategory in availableCategoriesInDb) {
        if (dbCategory.toLowerCase() == possibleName.toLowerCase()) {
          return dbCategory;
        }
      }
    }

    return null;
  }
}
