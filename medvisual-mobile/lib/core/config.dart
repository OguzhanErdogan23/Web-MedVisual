/// Uygulama yapilandirmasi (derleme zamani sabitleri).
library;

/// API taban adresi. Android emulatorunde 10.0.2.2 ana makineyi gosterir;
/// gercek cihazda `--dart-define=API_BASE_URL=http://<LAN-IP>:8000` kullanin.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

const supabaseUrl = 'https://dwihzurpusgljdjnnquu.supabase.co';
const supabasePublishableKey = 'sb_publishable_Ge6Nq5wgcE54JVA0VN2ClQ_RhePrmNp';
