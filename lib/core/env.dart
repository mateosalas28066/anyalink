// lib/core/env.dart
// Comentario (ES): Config de entorno simple + flags de demo.

class Env {
  static const supabaseUrl = 'https://vnalfxtgewdefpoxkuwu.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuYWxmeHRnZXdkZWZwb3hrdXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NjUwNjQsImV4cCI6MjA3NDE0MTA2NH0.3OVHiVAgI9WUJZ4ar3YVOH49N_IAEEwN2f7TBJhXg9M';

  static const lightAlias = 'Lamp';

  // Fuente de datos (polling estable por ahora)
  static const useRealtime = false;

  // Demo UI
  static const addDemoTiles = false;
  static const cameraAsset = 'assets/sample/camera.jpg';

  // Comentario (ES): Config del clima (Cali por defecto). Cambia si quieres otra ciudad.
  static const weatherLatitude = 3.4516; // Cali
  static const weatherLongitude = -76.5320;
  static const weatherPlaceLabel = 'Santiago de Cali, Colombia';

  // Cada cuántos segundos refrescar (desarrollo: 60–120; producción: 300)
  static const weatherPollSeconds = 120;

  // OpenWeather (https://openweathermap.org/api) -> pon tu API key aquí.
  static const openWeatherApiKey = 'e5807545e823fc9c06efd9dd005dd505';
  // VDO
   static const demoCameraUrl = 'https://vdo.ninja/?view=qYNR9K6';
}
