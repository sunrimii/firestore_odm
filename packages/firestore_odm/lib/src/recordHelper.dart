/// Extension for converting Records to List with support up to 30 positional fields
extension RecordToListExtension on Record {
  /// Convert record to list using pattern matching
  /// Supports up to 30 positional fields
  List<dynamic> toList() {
    return switch (this) {
      // 1 field
      (var a,) => [a],
      
      // 2 fields
      (var a, var b) => [a, b],
      
      // 3 fields
      (var a, var b, var c) => [a, b, c],
      
      // 4 fields
      (var a, var b, var c, var d) => [a, b, c, d],
      
      // 5 fields
      (var a, var b, var c, var d, var e) => [a, b, c, d, e],
      
      // 6 fields
      (var a, var b, var c, var d, var e, var f) => [a, b, c, d, e, f],
      
      // 7 fields
      (var a, var b, var c, var d, var e, var f, var g) => 
        [a, b, c, d, e, f, g],
      
      // 8 fields
      (var a, var b, var c, var d, var e, var f, var g, var h) => 
        [a, b, c, d, e, f, g, h],
      
      // 9 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i) => 
        [a, b, c, d, e, f, g, h, i],
      
      // 10 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j) => 
        [a, b, c, d, e, f, g, h, i, j],
      
      // 11 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k) => 
        [a, b, c, d, e, f, g, h, i, j, k],
      
      // 12 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l) => 
        [a, b, c, d, e, f, g, h, i, j, k, l],
      
      // 13 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m],
      
      // 14 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n],
      
      // 15 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o],
      
      // 16 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p],
      
      // 17 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q],
      
      // 18 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r],
      
      // 19 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s],
      
      // 20 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t],
      
      // 21 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u],
      
      // 22 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v],
      
      // 23 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w],
      
      // 24 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x],
      
      // 25 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y],
      
      // 26 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z],
      
      // 27 fields (using a1, a2, etc. after z)
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z, var a1) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, a1],
      
      // 28 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z, var a1, var b1) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, a1, b1],
      
      // 29 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z, var a1, var b1, var c1) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, a1, b1, c1],
      
      // 30 fields
      (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z, var a1, var b1, var c1, var d1) => 
        [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, a1, b1, c1, d1],
      
      // Unsupported record type
      _ => throw UnsupportedError(
        'Record type not supported. Only positional records with 1-30 fields are supported.'
      ),
    };
  }
  
  /// Get the number of fields in the record
  int get fieldCount => toList().length;
  
  /// Check if the record is supported by this extension
  bool get isSupported {
    try {
      toList();
      return true;
    } catch (e) {
      return false;
    }
  }
}
