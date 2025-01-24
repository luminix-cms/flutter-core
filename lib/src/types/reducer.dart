typedef ReducerCallback<T> = T Function(
  T value, [
  List<dynamic>? args,
]);

class Reducer<T> {
  final int priority;
  final ReducerCallback<T> callback;

  Reducer(this.callback, this.priority);
}
