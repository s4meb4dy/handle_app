class BleProtocol {
  static String saveGear(String gear) {
    return 'SAVE_GEAR=$gear';
  }

  static String deleteGear(String gear) {
    return 'DELETE_GEAR=$gear';
  }

  static const String deleteAll = 'DELETE_ALL';

  static const String getConfig = 'GET_CONFIG';

  static String setDelay(int milliseconds) {
    return 'SET_DELAY=$milliseconds';
  }

  static const String getDelay = 'GET_DELAY';

  static String setZone(double degrees) {
    return 'SET_ZONE=${degrees.toStringAsFixed(1)}';
  }

  static const String getZone = 'GET_ZONE';

  static String setScene(String scene) {
    return 'SET_SCENE=$scene';
  }

  static const String getScene = 'GET_SCENE';
}