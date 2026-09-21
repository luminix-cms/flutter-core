import 'package:flutter/foundation.dart';

class A11yCenterPresenter extends ChangeNotifier {
  bool _open = false;
  int _fabHiddenBy = 0;
  bool _disposed = false;

  bool get isOpen => _open;

  bool get fabVisible => _fabHiddenBy == 0;

  // As rotas soltam o contador em post-frame: o pop pode chegar depois de o
  // escopo que criou o presenter já ter sido desmontado.
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void open() {
    if (_disposed || _open) return;
    _open = true;
    notifyListeners();
  }

  void close() {
    if (_disposed || !_open) return;
    _open = false;
    notifyListeners();
  }

  void toggle() => _open ? close() : open();

  void pushFabHidden() {
    if (_disposed) return;

    _fabHiddenBy++;
    if (_fabHiddenBy == 1) notifyListeners();
  }

  void popFabHidden() {
    if (_disposed || _fabHiddenBy == 0) return;
    _fabHiddenBy--;
    if (_fabHiddenBy == 0) notifyListeners();
  }
}
