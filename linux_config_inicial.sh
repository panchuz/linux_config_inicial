#!/usr/bin/env bash
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)

# creado por panchuz
# para automatizar la configuración inicial de lxc generado en base
# al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE

# Opciones para la configuración
export LANG=C.utf8 # quedará de forma permamente. Ver: crear_archivo_profile_local ()
export TZ='America/Argentina/Buenos_Aires'

# el contenido de la sig variable sirve para appendear a los nombres de los archivos creados por este script
MARCA="_panchuz"

# resto de las variables se definen en función principal


# GENERACIÓN DEL ENCABEZADO PARA LOS ARCHIVOS DE CONFIGURACIÓN
generacion_encabezado_stdout () {
	# https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
	cat <<-EOF
		# creado por (BASH_SOURCE):	${BASH_SOURCE}
		# fecha y hora:	$(date +%F_%T_TZ:%Z)
		# nombre host:	$(hostname)
		# $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"') / kernel version $(uname -r)
		#
		
	EOF
}

# CONFIGURACIÓN LOCAL
crear_archivo_profile_locale () {
	cat >/etc/profile.d/profile${MARCA}.sh <<-EOF
		${encabezado}
		# https://wiki.debian.org/Locale#Standard
		# https://www.debian.org/doc/manuals/debian-reference/ch08.en.html#_rationale_for_utf_8_locale
	
		LANG=${LANG}
	EOF
}

# CONFIGURACIÓN HUSO HORARIO
# https://linuxize.com/post/how-to-set-or-change-timezone-in-linux/
config_huso_horario () {
	timedatectl set-timezone ${TZ}
}

# --- CONFIGURACIÓN postfix ---
# https://www.postfix.org/STANDARD_CONFIGURATION_README.html#null_client	y ...#fantasy
# https://www.lynksthings.com/posts/sysadmin/mailserver-postfix-gmail-relay/
# https://forum.proxmox.com/threads/get-postfix-to-send-notifications-email-externally.59940/
# https://serverfault.com/questions/744761/postfix-aliases-will-be-ignored
config_postfix_nullclient_gmail () {
	cp /etc/postfix/main.cf /etc/postfix/main.cf.ORIGINAL${MARCA}
	# configuración postfix >> /etc/postfix/main.cf
	postconf 'relayhost = 'mydestination =' \
			'[smtp.gmail.com]:587' \
			'inet_interfaces = loopback-only' \
			'compatibility_level = 3.6' \
			'smtp_sasl_security_options = noanonymous' \
			'smtp_tls_security_level = encrypt' \
			'smtp_sasl_auth_enable = yes' \
			'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt' \
			'smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd'
	cat >/etc/postfix/sasl/sasl_passwd <<-EOF
		${encabezado}
		# https://www.lynksthings.com/posts/sysadmin/mailserver-postfix-gmail-relay/
		#
		[smtp.gmail.com]:587 username@gmail.com:${1}
	EOF
	postmap /etc/postfix/sasl/sasl_passwd
	chmod 0600 /etc/postfix/sasl/sasl_passwd*
	postfix reload
	#systemctl restart postfix
}


# --- CONFIGURACIÓN unattended-upgrades PARA PRUEBA MAIL ---
# ${encabezado//\#///} subtituye "#" por "//". Ref: https://stackoverflow.com/a/43421455
config_unattended-upgrades_prueba_mail () {
	cat >/etc/apt/apt.conf.d/51unattended-upgrades${MARCA} <<-EOF
		${encabezado//\#///}
		// https://wiki.debian.org/UnattendedUpgrades#Unattended_Upgrades
		// 
	
		Unattended-Upgrade::Mail "root";
	EOF
}


# --- CREA UN service PARA CONTINUAR LUEGO DEL REINICIO ---
# https://wiki.debian.org/systemd#Creating_or_altering_services
# $1: El service creado ejecuta $1 luego del reinicio
crear_reinicio-service () {
	local path_script_reinicio="$1"
 	
  	local nombre_reinicio_service=reinicio${MARCA}.service
 	local path_nombre_reinicio_service=/etc/systemd/system/${nombre_reinicio_service}
  
 	cat >${path_nombre_reinicio_service} <<-EOF
		${encabezado}
		# https://wiki.debian.org/systemd#Creating_or_altering_services
		# https://operavps.com/docs/run-command-after-boot-in-linux/
	 
		[Unit]
		Description=Ejecuta ${path_script_reinicio} por única vez luego de reinicio
		After=network.target auditd.service
		ConditionFileIsExecutable=${path_script_reinicio}
	
		[Service]
		Type=oneshot
		ExecStart=/bin/bash ${path_script_reinicio}
		# desactiva el servicio luego que cumplió su función:
		ExecStartPost=/bin/systemctl disable ${nombre_reinicio_service} 
	
		[Install]
		WantedBy=multi-user.target
	EOF
	systemctl enable ${nombre_reinicio_service}
}

#------------------FUNCIÓN PRINCIPAL------------------
principal () {
 	
  	# script para seguir el proceso luego del reboot (o del no reboot)
   	# debe coincidir con el de https://github.com/panchuz/linux_config_inicial/raw/main/....sh
	local script_reinicio=linux_config_inicial_reinicio.sh
 	local path_script_reinicio=/root/${script_reinicio}
  
	#wget -qP /root https://github.com/panchuz/linux_config_inicial/raw/main/${script_reinicio} &&
	wget -qO ${path_script_reinicio} https://github.com/panchuz/linux_config_inicial/raw/main/${script_reinicio}
	if [ $? -eq 0 ]; then
		chmod +x ${path_script_reinicio}
	else
		printf "ABORTANDO: No se pudo descargar ${script_reinicio}\n"
   		return 1
	fi
    
	# genera y guarda encabezado de texto para uso posterior en archivos creados por el script
 	local encabezado="$(generacion_encabezado_stdout)"
  
  	# genera locale $LANG permanente
	crear_archivo_profile_locale
 
 	# Setea huso horario
	config_huso_horario
 
 	# Actualización desatendida "confdef/confold"
	# mailx es pedido en /etc/apt/apt.conf.d/50unattended-upgrades para notificar por mail
	# apt-listchanges es indicado en https://wiki.debian.org/UnattendedUpgrades#Automatic_call_via_.2Fetc.2Fapt.2Fapt.conf.d.2F20auto-upgrades
	debian_dist-upgrade_install libsasl2-modules postfix-pcre bsd-mailx apt-listchanges unattended-upgrades sudo


	# configurar postfix:
	config_postfix_nullclient_gmail
 
 	# configurar uanttended-upgrades
	# escribir $(encabezado) Unattended-Upgrade::Mail "root"; > 51unattended-upgrades${MARCA}
	config_unattended-upgrades_prueba_mail

	# mail de prueba: unattended-upgrade -d
	# escribir Unattended-Upgrade::MailReport "only-on-error"; >> 51unattended-upgrades${MARCA}

	# panchuz = 1000
	# groups
	# set-cap
	# journal

 	# reboot necesario????
 	if [ -f /var/run/reboot-required ]; then
		crear_reinicio-service "$path_script_reinicio"
  		printf "Se procede a reiniciar\n"
		/bin/sleep 5
		reboot
 	else
 		printf "NO se necesita reiniciar\n"
   		${path_script_reinicio}
  	fi
}

# Verificación de privilegios
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
if (( $EUID == 0 )); then
	principal
else
	printf "ERROR: Este script se debe ejecutar con privilegios root\n"
fi
printf "con esto termina el script\nbye\n"
