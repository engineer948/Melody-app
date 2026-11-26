import 'package:flutter_test/flutter_test.dart';
import 'package:melody/features/home/home_shelves.dart';

void main() {
  test('default: every shelf in order', () {
    const s = HomeShelves();
    expect(s.visible, HomeShelf.values);
  });

  test('hide, move and survive a round trip', () {
    final s = const HomeShelves()
        .toggle(HomeShelf.mostPlayed, show: false)
        .move(HomeShelf.discover.index, 0);
    expect(s.order.first, HomeShelf.discover);
    expect(s.visible, isNot(contains(HomeShelf.mostPlayed)));
    final back = HomeShelves.fromJson(s.toJson());
    expect(back.order, s.order);
    expect(back.hidden, s.hidden);
    expect(back.toggle(HomeShelf.mostPlayed, show: true).hidden, isEmpty);
  });

  test('unknown names are dropped, new shelves added at the end', () {
    final s = HomeShelves.fromJson(const {
      'order': ['discover', 'gone', 'mix'],
      'hidden': ['gone'],
    });
    expect(s.order.take(2), [HomeShelf.discover, HomeShelf.mix]);
    expect(s.order.toSet(), HomeShelf.values.toSet());
    expect(s.hidden, isEmpty);
  });
}
