#!/bin/sh
# Kører ved opstart, før Laravel-migreringerne.
set -e
APP=/var/www/html

opt() {
  php -r '$o=json_decode(file_get_contents("/data/options.json"),true);
          $v=$o[$argv[1]]??"";
          echo is_bool($v)?($v?"1":"0"):$v;' "$1"
}

# Database og genererede billeder i /data, så de overlever genstart/opdatering
mkdir -p /data/generated
[ -f /data/database.sqlite ] || touch /data/database.sqlite

GEN=$APP/storage/app/public/images/generated
if [ ! -L "$GEN" ]; then
  rm -rf "$GEN"
  mkdir -p "$(dirname "$GEN")"
  ln -s /data/generated "$GEN"
fi

# Egen APP_KEY, genereres én gang og gemmes
[ -f /data/app_key ] || echo "base64:$(head -c 32 /dev/urandom | base64)" > /data/app_key

sed -i "s|^APP_KEY=.*|APP_KEY=$(cat /data/app_key)|" $APP/.env
sed -i "s|^APP_URL=.*|APP_URL=$(opt app_url)|" $APP/.env
sed -i "s|^REGISTRATION_ENABLED=.*|REGISTRATION_ENABLED=$(opt registration_enabled)|" $APP/.env

chown -R www-data:www-data /data $APP/.env

# Del enhedens API-nøgle med Home Assistant (input_text.trmnl_api_nogle),
# så HA kan sende skærmbilleder til LaraPaper.
php -r '
try {
  $db = new PDO("sqlite:/data/database.sqlite");
  $key = $db->query("SELECT api_key FROM devices ORDER BY id LIMIT 1")->fetchColumn();
} catch (Throwable $e) { exit(0); }
$tok = getenv("SUPERVISOR_TOKEN");
if (!$key || !$tok) exit(0);
$ctx = stream_context_create(["http" => [
  "method" => "POST", "ignore_errors" => true, "timeout" => 10,
  "header" => "Authorization: Bearer $tok\r\nContent-Type: application/json\r\n",
  "content" => json_encode(["entity_id" => "input_text.trmnl_api_nogle", "value" => $key]),
]]);
@file_get_contents("http://supervisor/core/api/services/input_text/set_value", false, $ctx);
echo "TRMNL API-nøgle delt med Home Assistant\n";
' || true
