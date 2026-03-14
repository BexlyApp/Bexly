import 'package:bexly/core/localization/generated/app_localizations.dart';

/// Extension for looking up localized category names by their database ID.
extension CategoryNameL10n on AppLocalizations {
  static const Map<int, String Function(AppLocalizations)> _getters = {
    // Main categories
    1: (l) => l.categoryFoodDrinks,
    2: (l) => l.categoryTransportation,
    3: (l) => l.categoryHousing,
    4: (l) => l.categoryEntertainment,
    5: (l) => l.categoryHealth,
    6: (l) => l.categoryShopping,
    7: (l) => l.categoryEducation,
    8: (l) => l.categoryTravel,
    9: (l) => l.categoryFinance,
    10: (l) => l.categoryUtilities,
    // Food & Drinks subcategories
    101: (l) => l.categoryGroceries,
    102: (l) => l.categoryRestaurants,
    103: (l) => l.categoryCoffee,
    104: (l) => l.categorySnacks,
    105: (l) => l.categoryTakeout,
    // Transportation subcategories
    201: (l) => l.categoryPublicTransport,
    202: (l) => l.categoryFuelGas,
    203: (l) => l.categoryTaxiRideshare,
    204: (l) => l.categoryVehicleMaintenance,
    205: (l) => l.categoryParking,
    // Housing subcategories
    301: (l) => l.categoryRent,
    302: (l) => l.categoryMortgage,
    303: (l) => l.categoryUtilitiesHousing,
    304: (l) => l.categoryMaintenance,
    305: (l) => l.categoryPropertyTax,
    // Entertainment subcategories
    401: (l) => l.categoryMovies,
    402: (l) => l.categoryStreaming,
    403: (l) => l.categoryGaming,
    404: (l) => l.categoryEvents,
    405: (l) => l.categorySubscriptions,
    // Health subcategories
    501: (l) => l.categoryDoctorVisits,
    502: (l) => l.categoryPharmacy,
    503: (l) => l.categoryInsurance,
    504: (l) => l.categoryFitness,
    505: (l) => l.categoryDental,
    // Shopping subcategories
    601: (l) => l.categoryClothing,
    602: (l) => l.categoryElectronics,
    603: (l) => l.categoryShoes,
    604: (l) => l.categoryAccessories,
    605: (l) => l.categoryOnlineShopping,
    // Education subcategories
    701: (l) => l.categoryTuition,
    702: (l) => l.categoryBooks,
    703: (l) => l.categoryOnlineCourses,
    704: (l) => l.categoryWorkshops,
    705: (l) => l.categorySchoolSupplies,
    // Travel subcategories
    801: (l) => l.categoryFlights,
    802: (l) => l.categoryHotels,
    803: (l) => l.categoryTours,
    804: (l) => l.categoryTransport,
    805: (l) => l.categorySouvenirs,
    // Finance subcategories
    901: (l) => l.categoryLoanPayments,
    902: (l) => l.categorySavings,
    903: (l) => l.categoryInvestments,
    904: (l) => l.categoryCreditCard,
    905: (l) => l.categoryBankFees,
    // Utilities subcategories
    1001: (l) => l.categoryElectricity,
    1002: (l) => l.categoryWater,
    1003: (l) => l.categoryGas,
    1004: (l) => l.categoryInternet,
    1005: (l) => l.categoryPhone,
  };

  /// Returns the localized category name for the given DB category ID.
  /// Falls back to 'Unknown Category' if the ID is not recognized.
  String getCategoryName(int? categoryId) {
    if (categoryId == null) return 'Unknown Category';
    final getter = _getters[categoryId];
    return getter?.call(this) ?? 'Unknown Category';
  }
}
