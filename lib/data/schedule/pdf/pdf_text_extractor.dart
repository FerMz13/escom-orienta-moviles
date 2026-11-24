import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'pdf_text_models.dart';

/// Extrae texto con posiciones de un PDF.
abstract interface class PdfTextSource {
  PdfTextDocument extract(Uint8List bytes);
}

/// Implementación con Syncfusion (sustituye a PDFBox de la versión Kotlin).
///
/// Reconstruye las palabras a partir de los glifos con la misma regla que
/// `PositionedTextStripper`: se corta en blancos o cuando el hueco con el
/// glifo anterior supera [maxGlyphGap] puntos.
class SyncfusionPdfTextExtractor implements PdfTextSource {
  const SyncfusionPdfTextExtractor({this.maxGlyphGap = 3.5});

  final double maxGlyphGap;

  @override
  PdfTextDocument extract(Uint8List bytes) {
    final document = sf.PdfDocument(inputBytes: bytes);
    try {
      final extractor = sf.PdfTextExtractor(document);
      final text = StringBuffer();
      final tokens = <PdfTextToken>[];

      for (var page = 0; page < document.pages.count; page++) {
        text
          ..write(extractor.extractText(startPageIndex: page, endPageIndex: page, layoutText: true))
          ..write('\n');
        for (final line in extractor.extractTextLines(startPageIndex: page, endPageIndex: page)) {
          for (final word in line.wordCollection) {
            tokens.addAll(_tokensFromWord(word, page));
          }
        }
      }
      return PdfTextDocument(plainText: text.toString(), tokens: tokens);
    } finally {
      document.dispose();
    }
  }

  List<PdfTextToken> _tokensFromWord(sf.TextWord word, int pageIndex) {
    final glyphs = word.glyphs;
    if (glyphs.isEmpty) {
      final text = word.text.trim();
      if (text.isEmpty) return const [];
      return [_token(text, pageIndex, [word.bounds])];
    }

    final result = <PdfTextToken>[];
    final current = <sf.TextGlyph>[];
    void flush() {
      if (current.isEmpty) return;
      final text = current.map((g) => g.text).join().trim();
      if (text.isNotEmpty) {
        result.add(_token(text, pageIndex, [for (final g in current) g.bounds]));
      }
      current.clear();
    }

    double? previousEnd;
    for (final glyph in glyphs) {
      final blank = glyph.text.trim().isEmpty;
      final largeGap = previousEnd != null && glyph.bounds.left - previousEnd > maxGlyphGap;
      if (blank || largeGap) flush();
      if (blank) {
        previousEnd = null;
      } else {
        current.add(glyph);
        previousEnd = glyph.bounds.right;
      }
    }
    flush();
    return result;
  }

  static PdfTextToken _token(String text, int pageIndex, List<Rect> rects) {
    var left = double.infinity, right = double.negativeInfinity;
    var bottomSum = 0.0, height = 0.0;
    for (final r in rects) {
      left = math.min(left, r.left);
      right = math.max(right, r.right);
      bottomSum += r.bottom;
      height = math.max(height, r.height);
    }
    // Syncfusion acumula error de punto flotante (188.27000000000095 vs
    // 188.27000000000098 en el mismo renglón); se redondea a centésimas.
    return PdfTextToken(
      text: text,
      pageIndex: pageIndex,
      x: _round(left),
      y: _round(bottomSum / rects.length),
      endX: _round(right),
      height: _round(height),
    );
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}
