#!/usr/bin/env bash
source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/linux_config_inicial/main/generales.func.sh)

# creado por panchuz
# para automatizar la configuración inicial de lxc generado en base
# al template debian-12-standard_12.0-1_amd64.tar.zst de Proxmox VE

# Opciones para la configuración
export LANG=C.utf8 # quedará de forma permamente. Ver: function crear_archivo_profile_local ()
export TZ='America/Argentina/Buenos_Aires'

# el contenido de la sig variable sirve para appendear a los nombres de los archivos creados por este script
MARCA="_panchuz"


# GENERACIÓN DEL ENCABEZADO PARA LOS ARCHIVOS DE CONFIGURACIÓN
function generacion_encabezado_stdout () {
	# https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
	cat <<-EOF
	# creado por (BASH_SOURCE):\t${BASH_SOURCE}
	# fecha y hora:\t$(date +%F_%T_TZ:%Z)
	# nombre del host:\t$(hostname)
	# $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"') / kernel version $(uname -r)
	#
	
EOF
}

# CONFIGURACIÓN LOCAL
function crear_archivo_profile_local () {
	cat >/etc/profile.d/profile${MARCA}.sh <<-EOF
	${encabezado}
	# https://wiki.debian.org/Locale#Standard
	# https://www.debian.org/doc/manuals/debian-reference/ch08.en.html#_rationale_for_utf_8_locale

	LANG=${LANG}
EOF
}

# CONFIGURACIÓN HUSO HORARIO
function cambiar_huso_horario () {
	# https://linuxize.com/post/how-to-set-or-change-timezone-in-linux/
	timedatectl set-timezone ${TZ}
}

#------------------FUNCIÓN PRINCIPAL------------------
function main () {
# FUNICIÓN PRINCIPAL
	# me aseguro que sea root o salgo con mensaje de error
	verif_privilegios_root
	local encabezado="$(generacion_encabezado_stdout)"
	# para comprobar
	printf  "Encabezado de todos los archivos generados:\n"
 	printf "${encabezado}"
	crear_archivo_profile_local
	cambiar_huso_horario
	nuevo_debian_dist-upgrade
 	# verificación
  	ls -la /var/run/
	printf "/var/run/reboot-required= "
	cat /var/run/reboot-required
	printf "\n"
}

# Verificación de privilegios
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
if (( $EUID = 0 )); then
	main
else
	printf "ERROR: Este script se debe ejecutar con privilegios root\n"
fi
printf "con esto termina el script\nbye\n"
