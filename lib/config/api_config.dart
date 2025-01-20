class ApiConfig {
  static const String baseUrl = 'https://eljincorp.com/api';
  /* static const String baseUrl = 'http://10.151.5.239:8080/api'; */
  /* static const String baseUrl = 'http://127.0.0.1:8000/api'; */
  static const Duration timeoutDuration = Duration(seconds: 30);

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
