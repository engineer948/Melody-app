/// Awaits futures in parallel and rethrows the first error unchanged.
///
/// Unlike the record `.wait` extension, which wraps failures in a
/// `ParallelWaitError`, callers can keep matching on the original error.
Future<(A, B)> waitBoth<A, B>(Future<A> a, Future<B> b) async {
  await Future.wait<void>([a, b]);
  return (await a, await b);
}

/// Three-future variant of [waitBoth].
Future<(A, B, C)> waitThree<A, B, C>(
  Future<A> a,
  Future<B> b,
  Future<C> c,
) async {
  await Future.wait<void>([a, b, c]);
  return (await a, await b, await c);
}

/// Four-future variant of [waitBoth].
Future<(A, B, C, D)> waitFour<A, B, C, D>(
  Future<A> a,
  Future<B> b,
  Future<C> c,
  Future<D> d,
) async {
  await Future.wait<void>([a, b, c, d]);
  return (await a, await b, await c, await d);
}
