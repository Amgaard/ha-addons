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

