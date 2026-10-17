import 'package:kjd_core/kjd_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  VanshMember m(String id, {String? parent, int order = 0, bool female = false}) =>
      VanshMember(id: id, name: id, parentId: parent, order: order, female: female);

  test('vanshavali tree: children in order, lineage and generations', () {
    final t = VanshTree([
      m('grandson', parent: 'son'),
      m('daughter', parent: 'root', order: 2, female: true),
      m('son', parent: 'root', order: 1),
      m('root'),
      m('greatgrandson', parent: 'grandson'),
    ]);
    expect(t.roots.map((x) => x.id), ['root']);
    expect(t.childrenOf('root').map((x) => x.id), ['son', 'daughter']);
    final g = t.byId['greatgrandson']!;
    expect(t.lineage(g).map((x) => x.id), ['root', 'son', 'grandson', 'greatgrandson']);
    expect(t.generation(g), 4);
    expect(t.parentOf(g)!.id, 'grandson');
    expect(t.descendantCount('root'), 4);
    expect(t.descendantCount('daughter'), 0);
  });

  test('a missing parent or a loop starts its own branch', () {
    final t = VanshTree([m('orphan', parent: 'gone'), m('a', parent: 'b'), m('b', parent: 'a')]);
    expect(t.roots.map((x) => x.id), containsAll(['orphan']));
    // Every person is still shown once, and lineage always ends.
    final shown = <String>{};
    void walk(VanshMember x) {
      expect(shown.add(x.id), isTrue);
      t.childrenOf(x.id).forEach(walk);
    }
    t.roots.forEach(walk);
    expect(shown, {'orphan', 'a', 'b'});
    for (final x in t.byId.values) {
      expect(t.lineage(x).length, lessThanOrEqualTo(3));
    }
  });

  test('VanshMember map round trip and parampara link', () {
    const v = VanshMember(id: 'v', name: 'श्री', parentId: 'p', female: true, gadhipatiId: 'g1', spouse: 's', order: 2);
    final back = VanshMember.fromMap('v', v.toMap());
    expect(back.parentId, 'p');
    expect(back.female, isTrue);
    expect(back.heldGadi, isTrue);
    expect(VanshTree([back]).forGadhipati('g1')?.id, 'v');
  });
}
