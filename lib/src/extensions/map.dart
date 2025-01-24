extension MapExtension<K, V> on Map<K, V> {
  Map<K, V> set(K key, V value) {
    return <K, V>{...this, key: value};
  }
}
