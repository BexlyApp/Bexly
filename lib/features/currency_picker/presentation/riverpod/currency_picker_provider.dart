import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/data/repositories/currency_repository.dart';
import 'package:bexly/features/currency_picker/data/sources/currency_local_source.dart';

class CurrencyNotifier extends Notifier<Currency> {
  @override
  Currency build() => CurrencyLocalDataSource.dummy;

  void setCurrency(Currency currency) => state = currency;
}

final currencyProvider = NotifierProvider<CurrencyNotifier, Currency>(
  CurrencyNotifier.new,
);

/// This provider will be filled by currenciesProvider on SplashScreen
class CurrenciesStaticNotifier extends Notifier<List<Currency>> {
  @override
  List<Currency> build() => <Currency>[];

  void setCurrencies(List<Currency> currencies) => state = currencies;
}

final currenciesStaticProvider = NotifierProvider<CurrenciesStaticNotifier, List<Currency>>(
  CurrenciesStaticNotifier.new,
);

final currenciesProvider = FutureProvider.autoDispose<List<Currency>>((
  ref,
) async {
  final currenciesRepo = CurrencyRepositoryImpl();
  return currenciesRepo.fetchCurrencies();
});
