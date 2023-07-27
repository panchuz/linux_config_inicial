# linux_config_inicial
script para configurar linux: utf.8 / zona horaria / etc

## Comando para correr en la consola:
bash -c "$(wget -qLO - https://github.com/panchuz/linux_config_inicial/raw/main/linux_config_inicial.sh)"

## Comando para bajar el .sh y ejecutarlo localmente
wget -P /root https://github.com/panchuz/linux_config_inicial/raw/main/linux_config_inicial.sh
chmod +x /root/linux_config_inicial.sh
/root/linux_config_inicial.sh

## Comando para bajar el .sh y ejecutarlo localmente EN UNA LÍNEA
wget -P /root https://github.com/panchuz/linux_config_inicial/raw/main/linux_config_inicial.sh &&
chmod +x /root/linux_config_inicial.sh &&
/root/linux_config_inicial.sh
