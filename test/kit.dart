// The frames of a kit master export (test/fixtures/kit/*.json: Sketch symbol master, children
// with `frame` x, y, w, h and `text`), for the kit-parity tests.

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

class KitLayer {
  const KitLayer(this.name, this.rect, this.text, this.children);

  final String name;
  final Rect rect;
  final String text;
  final List<KitLayer> children;

  /// The first child (at any depth) called [name].
  KitLayer layer(String name) {
    for (final c in children) {
      if (c.name == name) return c;
      final deep = c._find(name);
      if (deep != null) return deep;
    }
    throw StateError('no layer "$name" in "${this.name}"');
  }

  KitLayer? _find(String name) {
    for (final c in children) {
      if (c.name == name) return c;
      final deep = c._find(name);
      if (deep != null) return deep;
    }
    return null;
  }

  Size get size => rect.size;
}

KitLayer loadKit(String fixture) {
  KitLayer parse(Map<String, dynamic> node) {
    final f = node['frame'] as Map<String, dynamic>;
    return KitLayer(
      '${node['name']}',
      Rect.fromLTWH(
        (f['x'] as num).toDouble(),
        (f['y'] as num).toDouble(),
        (f['w'] as num).toDouble(),
        (f['h'] as num).toDouble(),
      ),
      '${node['text'] ?? ''}',
      [
        for (final c in (node['children'] as List? ?? const []))
          parse(c as Map<String, dynamic>),
      ],
    );
  }

  return parse(
    jsonDecode(File('test/fixtures/kit/$fixture.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}
