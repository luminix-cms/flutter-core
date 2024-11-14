abstract class BaseModel {
  Map<String, dynamic> attributes = {};

  bool exists = false;
  bool wasRecentlyCreated = false;

  dynamic getAttribute(String key) {
    attributes[key];

    return attributes[key];
  }

  void setAttribute(String key, dynamic value) {
    attributes[key] = value;
  }
}
