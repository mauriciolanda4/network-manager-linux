#!/bin/bash

# Define las variables
LSB=/usr/bin/lsb_release

# Funcion: Muestra el prompt de pausa
# $1-> Mensaje (opcional)
function pause(){
local message="$@"
[ -z $message ] && message="Presiona la tecla [Enter] para continuar..."
read -p "$message" readEnterKey
}

# Funcion - Muestra el menu en la terminal
function show_menu(){
date
echo "---------------------------"
echo " Menu Principal "
echo "---------------------------"
echo "1. Informacion del Sistema Operativo"
echo "2. Informacion del Hostname y DNS"
echo "3. Informacion de la Red"
echo "4. Quien esta en linea"
echo "5. Ultimo Logueo de los Usuarios"
echo "6. Informacion de memoria Libre y en Uso"
echo "7. Obtener mi direccion IP"
echo "8. El Uso de los disco"
echo "9. El uso de los procesos"
echo "10. Operaciones de los Usuarios"
echo "11. Operaciones de los Archivos"
echo "12. Hacer ping"
echo "13. Trazar ruta"
echo "14. Cambiar IP"
echo "15. Consultar IP"
echo "16. Sniffear (captura de trafico en la red)"
echo "17. Salir"
}

# Funcion - Muestra el mensaje de Header
# $1 - mensaje
function write_header(){
local h="$@"
echo "---------------------------------------------------------------"
echo " ${h}"
echo "---------------------------------------------------------------"
}

# Funcion - Obtiene informacion de tu Sistema Operativo
function os_info(){
write_header " Informacion del Sistema "
echo "Sistema Operativo : $(uname)"
[ -x $LSB ] && $LSB -a || echo "$LSB comando no esta instalado (set \$LSB variable)"
#pause "Presiona la tecla [Enter] para continuar..."
pause
}

# Funcion - Obtiene informacion sobre el host como ser Hostname, DNS e IP
function host_info(){
local dnsips=$(sed -e '/^$/d' /etc/resolv.conf | awk '{if (tolower($1)=="nameserver") print $2}')
write_header " Informacion del Hostname y DNS "
echo "Hostname : $(hostname -s)"
echo "dominio DNS : $(hostname -d)"
echo "Nombre del dominio completamente calificado : $(hostname -f)"
echo "(IP) : $(hostname -i)"
echo "Nombre de los servidores DNS (DNS IP) : ${dnsips}"
pause
}

# Funcion - Informacion de la interfaz de red y ruteo
function net_info(){
devices=$(netstat -i | cut -d" " -f1 | egrep -v "^Kernel|Iface|lo")
write_header " Informacion de Red "
echo "Total de interfaces de red encontradas : $(wc -w <<<${devices})"

echo "*** Informacion de Direcciones IP ***"
ip -4 address show

echo "***********************"
echo "*** Ruteo de redes ***"
echo "***********************"
netstat -nr

echo "**************************************"
echo "*** Informacion de trafico de interfaces ***"
echo "**************************************"
netstat -i

pause
}

# Funcion - Muestra una lista de los usuarios logueados actualmente
function user_info(){
local cmd="$1"
case "$cmd" in
who) write_header " Quien esta en linea "; who -H; pause ;;
last) write_header " Lista de los ultimos usuarios logueados "; last ; pause ;;
esac
}

# Funcion - Muestra la informacion de memoria libre y en uso
function mem_info(){
write_header " Memoria Libre y en Uso "
free -m

echo "*********************************"
echo "*** Estadisticas de la Memoria Virtual ***"
echo "*********************************"
vmstat
echo "***********************************"
echo "*** Top 5 procesos que consumen memoria ***"
echo "***********************************"
ps auxf | sort -nr -k 4 | head -5
pause
}

# Funcion - Obtiene la direccion IP publica
function ip_info(){
write_header " Informacion IP Publica "
hostname -I
echo "Informacion todas las IPs"
hostname --all-ip-addresses
pause
}

# Funcion - Obtener informacion del uso del disco
function disk_info() {
usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
  partition=$(echo $output | awk '{print $2}')
write_header " Informacion del uso del disco "
if [ "$EXCLUDE_LIST" != "" ] ; then
  df -H | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $5 " " $6}'
else
  df -H | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5 " " $6}'
fi
pause
}

#Funcion - Informacion del uso de procesos

function proc_info() {
write_header " Informacion del uso de procesos"
txtred=$(tput setaf 1)
txtgrn=$(tput setaf 2)
txtylw=$(tput setaf 3)
txtblu=$(tput setaf 4)
txtpur=$(tput setaf 5)
txtcyn=$(tput setaf 6)
txtrst=$(tput sgr0)
COLUMNS=$(tput cols)

center() {
	w=$(( $COLUMNS / 2 - 20 ))
	while IFS= read -r line
	do
		printf "%${w}s %s\n" ' ' "$line"
	done
}

centerwide() {
	w=$(( $COLUMNS / 2 - 30 ))
	while IFS= read -r line
	do
		printf "%${w}s %s\n" ' ' "$line"
	done
}

while :
do

clear

echo ""
echo ""
echo "${txtcyn}(Por favor ingrese el numero de su seleccion)${txtrst}" | centerwide
echo ""
echo "1.  Mostrar todos los procesos" | center
echo "2.  Matar un proceso" | center
echo "3.  Volver arriba" | center
echo "4.  ${txtpur}Retornar al menu principal${txtrst}" | center
echo "5.  ${txtred}Apagar${txtrst}" | center
echo ""

read processmenuchoice
case $processmenuchoice in

1 )
	clear && echo "" && echo "${txtcyn}(presiona ENTER o utiliza las flechas para navegar la lista, presiona Q para volver al menu)${txtrst}" | centerwide && read
	ps -ef | less
;;

2 )
	clear && echo "" && echo "Por favor ingresa el PID del proceso que desea matar:" | centerwide
	read pidtokill
	kill -2 $pidtokill && echo "${txtgrn}Proceso terminado exitosamente.${txtrst}" | center || echo "${txtred}El proceso fallo en terminar. Por favor revisa el PID e intenta de nuevo.${txtrst}" | centerwide
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

3 )
	top
;;

4 )
	clear && echo "" && echo "Esta seguro que quiere retornar al menu principal? ${txtcyn}y/n${txtrst}" | centerwide && echo ""
	read exitays
	case $exitays in
		y | Y )
			clear && exit
		;;
		n | N )
			clear && echo "" && echo "Ok. No se realiza la accion." | center && echo "" && echo "${txtcyn}(Presiona ENTER para continuar.)${txtrst}" | center && read
		;;
		* )
			clear && echo "" && echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center && echo "" && echo "${txtcyn}(Presiona ENTER para continuar.)${txtrst}" | center && read
	esac
;;

5 )
	clear && echo "" && echo "Estas seguro que deseas apagar la maquina? ${txtcyn}y/n${txtrst}" | centerwide && echo ""
	read shutdownays
	case $shutdownays in
		y | Y )
			clear && shutdown -h now
		;;
		n | N )
			clear && echo "" && echo "Ok. No se realiza la accion." | center && echo "" && echo "${txtcyn}(Presiona ENTER para continuar.)${txtrst}" | center && read
		;;
		* )
			clear && echo "" && echo "${txtred}Por favor realiza una seleccion valida." | center && echo "" && echo "${txtcyn}(Presiona ENTER para continuar.)${txtrst}" | center && read
		;;
	esac
;;

* )
	clear && echo "" && echo "${txtred}Por favor realiza una seleccion valida." | center && echo "" && echo "${txtcyn}(Presiona ENTER para continuar.)${txtrst}" | center && read
;;
esac

done
pause
}

#Funcion - Para obtener la informacion y operaciones de los usuarios
function user_infos() {

write_header "Operaciones de los usuarios"

txtred=$(tput setaf 1)
txtgrn=$(tput setaf 2)
txtylw=$(tput setaf 3)
txtblu=$(tput setaf 4)
txtpur=$(tput setaf 5)
txtcyn=$(tput setaf 6)
txtrst=$(tput sgr0)
COLUMNS=$(tput cols)

center() {
	w=$(( $COLUMNS / 2 - 20 ))
	while IFS= read -r line
	do
		printf "%${w}s %s\n" ' ' "$line"
	done
}

centerwide() {
	w=$(( $COLUMNS / 2 - 30 ))
	while IFS= read -r line
	do
		printf "%${w}s %s\n" ' ' "$line"
	done
}

while :
do

clear

echo ""
echo ""
echo "${txtcyn}(por favor ingrese el numero de su seleccion)${txtrst}" | centerwide
echo ""
echo "1.  Crear un usuario" | center
echo "2.  Cambiar el grupo para un usuario" | center
echo "3.  Crear un grupo" | center
echo "4.  Eliminar un usuario" | center
echo "5.  Cambiar una contrasena" | center
echo "6.  ${txtpur}Volver al menu principal${txtrst}" | center
echo "7.  ${txtred}Apagar la maquina${txtrst}" | center
echo ""

read usermenuchoice
case $usermenuchoice in

1 )
	clear && echo "" && echo "Por favor ingrese el username:  ${txtcyn}(NO ESPACIOS O CARACTERES ESPECIALES!)${txtrst}" | centerwide && echo ""
	read newusername
	echo "" && echo "Por favor ingrese un grupo para el nuevo usuario:  ${txtcyn}(NO ESPACIOS O CARACTERES ESPECIALES!)${txtrst}" | centerwide && echo ""
	read newusergroup
	echo "" && echo "Cual es el nombre completo del nuevo usuario?  ${txtcyn}(Puedes utilizar espacios aqui si es necesario!)${txtrst}" | centerwide && echo ""
	read newuserfullname
	echo "" && echo ""
	groupadd $newusergroup
	useradd -g $newusergroup -c "$newuserfullname" $newusername && echo "${txtgrn}Usuario nuevo $newusername creado exitosamente.${txtrst}" | center || echo "${txtred}No se pudo crear un usuario nuevo.${txtrst}" | center
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center
	read
;;

2 )
	clear && echo "" && echo "Que usuario necesita estar en un diferente grupo? ${txtcyn}(EL USUARIO DEBE EXISTIR!)${txtrst}" | centerwide && echo ""
	read usermoduser
	echo "" && echo "Cual deberia ser el nuevo grupo para este usuario?  ${txtcyn}(NO ESPACIOS O CARACTERES ESPECIALES!)${txtrst}" | centerwide && echo ""
	read usermodgroup
	echo "" && echo ""
	groupadd $usermodgroup
	usermod -g $usermodgroup $usermoduser && echo "${txtgrn}Usuario $usermoduser agregado al grupo $usermodgroup exitosamente.${txtrst}" | center || echo "${txtred}No pudo agregar usuario al grupo.Por favor revisa si el usuario existe.${txtrst}" | centerwide
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center
	read
;;

3 )
	clear && echo "" && echo "Por favor ingresa un nombre para el nuevo grupo:  ${txtcyn}(NO ESPACIOS O CARACTERES ESPECIALES!)${txtrst}" | centerwide && echo ""
	read newgroup
	echo "" && echo ""
	groupadd $newgroup && echo "${txtgrn}Grupo $newgroup creado exitosamente.${txtrst}" | center || echo "${txtred}Fallo al crear grupo. Por favor revisa si el grupo existe.${txtrst}" | centerwide
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center
	read
;;

4 )
	clear && echo "" && echo "Por favor ingresa el username a ser eliminado:  ${txtcyn}(NO HAY VUELTA ATRAS!)${txtrst}" | centerwide && echo ""
	read deletethisuser
	echo "" && echo "${txtred}ESTA SEGURO EN ELIMINAR ESTE USUARIO? NO HAY VUELTA ATRAS! ${txtcyn}y/n${txtrst}" | centerwide
	read deleteuserays
	echo "" && echo ""
	case $deleteuserays in
		y | Y )
			userdel $deletethisuser && echo "${txtgrn}Usuario $deletethisuser eliminado exitosamente." | center || echo "${txtred}Fallo al eliminar usuario. Por favor revisa el username e intenta de nuevo.${txtrst}" | centerwide
		;;
		n | N )
			echo "Ok. No se realiza la accion." | center
		;;
		* )
			echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center
		;;
	esac
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center
	read
;;

5 )
	clear && echo "" && echo "Que contrasena de que usuario debe ser cambiado?" | centerwide
	read passuser
	echo ""
	passwd $passuser && echo "${txtgrn}Contrasena para $passuser cambiado exitosamente.${txtrst}" | center || echo "${txtred}Fallo en el cambio de contrasena.${txtrst}" | center
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center
	read
;;

6 )
	clear && echo "" && echo "Estas seguro que quieres regresar al menu principal? ${txtcyn}y/n${txtrst}" | centerwide && echo ""
	read exitays
	case $exitays in
		y | Y )
			clear && exit
		;;
		n | N )
			clear && echo "" && echo "Ok. No se realiza la accion." | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar.)${txtrst}" | center && read
		;;
		* )
			clear && echo "" && echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar.)${txtrst}" | center && read
		;;
	esac
;;

7 )
	clear && echo "" && echo "Estas seguro que quieres apagar la maquina? ${txtcyn}y/n${txtrst}" | centerwide && echo ""
	read shutdownays
	case $shutdownays in
		y | Y )
			clear && shutdown -h now
		;;
		n | N )
			clear && echo "" && echo "Ok. No se realiza la accion." | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar.)${txtrst}" | center && read
		;;
		* )
			clear && echo "" && echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar.)${txtrst}" | center && read
		;;
	esac
;;

* )
	clear && echo "" && echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar.)${txtrst}" | center && read
;;

esac

done
pause
}

#Funciones  - Para operaciones de archivos
function file_info() {
write_header "Operaciones de Archivos"
txtred=$(tput setaf 1)
txtgrn=$(tput setaf 2)
txtylw=$(tput setaf 3)
txtblu=$(tput setaf 4)
txtpur=$(tput setaf 5)
txtcyn=$(tput setaf 6)
txtrst=$(tput sgr0)
COLUMNS=$(tput cols)

center() {
	w=$(( $COLUMNS / 2 - 20 ))
	while IFS= read -r line
	do
		printf "%${w}s %s\n" ' ' "$line"
	done
}

centerwide() {
	w=$(( $COLUMNS / 2 - 30 ))
	while IFS= read -r line
	do
		printf "%${w}s %s\n" ' ' "$line"
	done
}

while :
do

clear

echo ""
echo ""
echo "${txtcyn}(Por favor ingrese el numero de su seleccion)${txtrst}" | centerwide
echo ""
echo "1.  Crear un archivo" | center
echo "2.  Eliminar un archivo" | center
echo "3.  Crear un directorio" | center
echo "4.  Eliminar un directorio" | center
echo "5.  Crear un link simbolico" | center
echo "6.  Cambiar ownership de un archivo" | center
echo "7.  Change permisos de un archivo" | center
echo "8.  Modificar texto dentro de un archivo" | center
echo "9.  Comprimir un archivo" | center
echo "10. Descomprimir un archivo" | center
echo "11. ${txtpur}Retornar al menu principal${txtrst}" | center
echo "12. ${txtred}Apagar la maquina${txtrst}" | center
echo ""

read mainmenuchoice
case $mainmenuchoice in

1 )
	clear && echo "" && echo "Directorio actual funcionando:" | center && pwd | center
	echo "" && echo "Por favor ingrese el ${txtcyn}path completo${txtrst} y filename para el nuevo archivo:" | centerwide && echo ""
	echo "${txtcyn}(si el archivo existe, sera tocado)${txtrst}" | center && echo ""
	read touchfile
	echo "" && echo ""
	touch $touchfile && echo "${txtgrn}Archivo $touchfile tocado exitosamente.${txtrst}" | centerwide || echo "${txtred}Toque fallido${txtrst}" | center
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

2 )
	clear && echo "" && echo "Directorio actual funcionando:" | center && pwd | center && echo "" && ls && echo ""
	echo "Por favor ingrese el ${txtcyn}path completo${txtrst} y el filename para el archivo que sera eliminado:" | centerwide && echo ""
	read rmfile
	echo "" && echo ""
	rm -i $rmfile && echo "${txtgrn}Archivo removido exitosamente.${txtrst}" | center || echo "${txtred}Fallo el el archivo a ser removido.${txtrst}" | center
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

3 )
	clear && echo "" && echo "Directorio actual funcionando:" | center && pwd | center && echo "" && ls && echo ""
	echo "Por favor ingrese el ${txtcyn}path completp${txtrst} para que se cree el directorio:" | centerwide && echo ""
	read mkdirdir
	echo "" && echo ""
	mkdir $mkdirdir && echo "${txtgrn}Directorio $mkdirdir creado exitosamente.${txtrst}" | centerwide || echo "${txtred}Fallo al crear directorio.${txtrst}" | center
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

4 )
	clear && echo "" && echo "Directorio funcionando exitosamente:" | center && pwd | center && echo "" && ls && echo ""
	echo "Por favor ingrese el ${txtcyn}path completo${txtrst} para el directorio que sera removido:  ${txtcyn}(DEBE ESTAR VACIO!)${txtrst}" | centerwide && echo ""
	read rmdirdir
	echo "" && echo ""
	rmdir $rmdirdir && echo "${txtgrn}Directorio $rmdirdir removido exitosamente. ${txtrst}" | centerwide || echo "${txtred}Fallo al remover directorio. Por favor asegurese que el directorio este vacio.${txtrst}" | centerwide
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

5 )
	clear && echo "" && echo "Por favor ingresa el archivo de entrada para el link simbolico:  ${txtcyn}(PATH COMPLETO!)${txtrst}" | centerwide && echo ""
	read symlinfile
	echo "" && echo "Por favor ingresa el archivo de salida para el link simbolico:  ${txtcyn}(PATH COMPLETO!)${txtrst}" | centerwide && echo ""
	read symloutfile
	echo "" && echo ""
	ln -s $symlinfile $symloutfile
	cat $symloutfile && clear && echo "" && echo "${txtgrn}link simbolico creado exitosamente en $symloutfile${txtrst}" | centerwide || echo "${txtred}Fallo en crear link simbolico. Por favor revisa los path y filenames si existen.${txtrst}" | centerwide && rm -f $symloutfile
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

6 )
	clear && echo "" && echo "Que ownership de que archivos debe cambiar?  ${txtcyn}(DEBE EXISITR, USAR PATH COMPLETO!)${txtrst}" | centerwide && echo ""
	read chownfile
	echo "" && echo "Por favor ingresa el username para el nuevo owner de $chownfile:  ${txtcyn}(EL USUARIO DEBE EXISTIR)${txtrst}" | centerwide && echo ""
	read chownuser
	echo "" && echo "Por favor ingresa el nuevo grupo para $chownfile:  ${txtcyn}(EL GRUPO DEBE EXISTIR)${txtrst}" | centerwide && echo ""
	read chowngroup
	echo "" && echo ""
	chown $chownuser.$chowngroup $chownfile && echo "${txtgrn}Ownership de $chownfile ccambiado exitosamente.${txtrst}" | centerwide || echo "${txtred}Fallo en el cambio de ownership. Por favor revisa si el usuario, grupo y el archivo existe.${txtrst}" | center
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

7 )
	clear && echo "" && echo "Que permisos de que archivos quiere cambiar?  ${txtcyn}(DEBE EXISTIR EL PATH COMPLETO!)${txtrst}" | centerwide && echo ""
	read chmodfile
	echo "" && echo "Por favor ingrese la cadena numerica de 3 digitos para los permisos que quiere cambiar:" | centerwide
	echo ""
	echo "${txtcyn}( el formato es [dueno][grupo][todo]  |  ejm: ${txtrst}777${txtcyn} para el control completo para todos )${txtrst}" | centerwide
	echo ""
	echo "${txtcyn}4 = lectura${txtrst}" | center
	echo "${txtcyn}2 = escribir${txtrst}" | center
	echo "${txtcyn}1 = ejecutar${txtrst}" | center
	echo ""
	read chmodnum
	echo "" && echo ""
	chmod $chmodnum $chmodfile && echo "${txtgrn}Permisos para $chmodfile cambiados exitosamente.${txtrst}" | centerwide || echo "${txtred}Fallo la configuracion de permisos.${txtrst}" | center
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

8 )
	clear && echo "" && echo "Por favor ingrese el path completo y el filename del archivo que desea editar:" | centerwide && echo ""
	read editfile
	echo "Que programa desea utilizar para editar este archivo?" | centerwide && echo ""
	echo "${txtcyn}(Por favor ingrese el numero de su seleccion)${txtrst}" | centerwide
	echo "1. vim" | center
	echo "2. nano" | center
	echo "3. mcedit" | center
	echo "4. emacs" | center
	echo "5. pico" | center
	echo ""
	read editapp
	echo ""
	case $editapp in
		1 )
			vim $editfile || echo "${txtred}Fallo la apertura de vim. Por favor revise si lo tiene instalado.${txtrst}" | centerwide
		;;

		2 )
			nano $editfile || echo "${txtred}Fallo la apertura de nano. Por favor revise si lo tiene instalado.${txtrst}" | centerwide
		;;

		3 )
			mcedit $editfile || echo "${txtred}Fallo la apertura de mcedit. Por favor revise si lo tiene instalado.${txtrst}" | centerwide
		;;

		4 )
			emacs $editfile || echo "${txtred}Fallo la apertura de emacs. Por favor revise si lo tiene instalado.${txtrst}" | centerwide
		;;

		5 )
			pico $editfile || echo "${txtred}Fallo la apertura de pico. Por favor revise si lo tiene instalado.${txtrst}" | centerwide
		;;

		* )
			echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center
		;;
	esac
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

9 )
	clear && echo "" && echo "Por favor ingrese el ${txtcyn}path completo${txtrst} y el filename del archivo que desea comprimir:" | centerwide && echo ""
	read pressfile
	echo "" && echo "Que metodo de comprimido desea utilizar?" | centerwide && echo ""
	echo "${txtcyn}(Por favor ingrese el numero de su seleccion)${txtrst}" | centerwide
	echo ""
	echo "1. gzip" | center
	echo "2. bzip2" | center
	echo "3. compress" | center
	echo ""
	read pressmethod
	echo ""
	case $pressmethod in
		1 )
			gzip $pressfile && echo "${txtgrn}Archivo comprimido exitosamente.${txtrst}" | center || echo "${txtred}El archivo ha fallado a ser comprimido.${txtrst}" | center
		;;

		2 )
			bzip2 $pressfile && echo "${txtgrn}Archivo comprimido exitosamente.${txtrst}" | center || echo "${txtred}El archivo ha fallado a ser comprimido.${txtrst}" | center
		;;

		3 )
			compress $pressfile && echo "${txtgrn}Archivo comprimido exitosamente.${txtrst}" | center || echo "${txtred}El archivo ha fallado a ser comprimido.${txtrst}" | center
		;;

		* )
			echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center
		;;
	esac
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

10 )
	clear && echo "" && echo "Por favor ingrese el ${txtcyn}path completo${txtrst} y el filename del archivo que desea descomprimir:" | centerwide && echo ""
	read depressfile
	case $depressfile in
		*.gz | *.GZ )
			gunzip $depressfiles && echo "${txtgrn}Archivo descomprimido exitosamente.${txtrst}" | center || echo "${txtred}El archivo ha fallado a ser descomprimido.${txtrst}" | center
		;;

		*.bz2 | *.BZ2 )
			bunzip2 $depressfile && echo "${txtgrn}Archivo descomprimido exitosamente.${txtrst}" | center || echo "${txtred}El archivo ha fallado a ser descomprimido.${txtrst}" | center
		;;

		*.z | *.Z )
			uncompress $depressfile && echo "${txtgrn}Archivo descomprimido exitosamente.${txtrst}" | center || echo "${txtred}El archivo ha fallado a ser descomprimido.${txtrst}" | center
		;;

		* )
			echo "${txtred}El archivo no parece utilizar un methodo de comprimido valido (gzip, bzip2, o compress). Por favor descomprimalo manualmente.${txtrst}" | centerwide
	esac
	echo "" && echo "${txtcyn}(presiona ENTER para continuar)${txtrst}" | center && read
;;

11 )
	clear && echo "" && echo "Estas seguro que quieres volver al menu principal? ${txtcyn}y/n${txtrst}" | centerwide && echo ""
	read exitays
	case $exitays in
		y | Y )
			clear && exit
		;;
		n | N )
			clear && echo "" && echo "Ok. No se realiza la accion." | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar.)${txtrst}" | center && read
		;;
		* )
			clear && echo "" && echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar.)${txtrst}" | center && read
	esac
;;

12 )
	clear && echo "" && echo "Estas seguro que deseas apagar la maquina? ${txtcyn}y/n${txtrst}" | centerwide && echo ""
	read shutdownays
	case $shutdownays in
		y | Y )
			clear && shutdown -h now
		;;
		n | N )
			clear && echo "" && echo "Ok. No se realiza la accion." | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar..)${txtrst}" | center && read
		;;
		* )
			clear && echo "" && echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar.)${txtrst}" | center && read
		;;
	esac
;;

* )
	clear && echo "" && echo "${txtred}Por favor realiza una seleccion valida.${txtrst}" | center && echo "" && echo "${txtcyn}(presiona ENTER para continuar.)${txtrst}" | center && read
;;

esac

done
pause
}
# Funcion - Obtiene el input del teclado y toma una decision usando case..esac
function read_input(){
local c
read -p "Ingresa tu seleccion [ 1 - 18 ] " c
case $c in
1) os_info ;;
2) host_info ;;
3) net_info ;;
4) user_info "who" ;;
5) user_info "last" ;;
6) mem_info ;;
7) ip_info ;;
8) disk_info ;;
9) proc_info ;;
10) user_infos ;;
11) file_info ;;
12) write_header "Realizar Ping"
echo "Ingrese la IP a realizarle el ping: "
read ip
ping -c 5 $ip
pause
 ;;
 13)
write_header "Trazar ruta a una ip"
echo "Ingrese la IP:"
read ip
mtr $ip
pause
 ;;
 14)
write_header "Cambiar IP"
echo "Ingrese la nueva IP:"
read ip
echo "Ingrese la GW:"
read gw
echo "Ingrese la interfaz:"
read int
sudo ip a add $ip broadcast $gw dev $int
echo "La nueva IP es $ip "
 pause
 ;;
 15)
write_header "Consulta de IP"
echo "Ingrese la interfaz: "
read int
echo -e "Su IP es: "
ip addr show $int | grep "inet"
pause
 ;;
 16)
write_header "Capturar paquetes de la red"
echo "Presione Ctrl+c para detener"
read
tcpdump
pause
 ;;
17) echo "Hasta la proxima!"; exit 0 ;;
*)
echo "Por favor selecciona un numero solamente entre 1 a 18."
pause
esac
}

# ignora CTRL+C, CTRL+Z
trap '' SIGINT SIGQUIT SIGTSTP

# logica principal
while true
do
clear
show_menu # muestra el menu
read_input # espera el input del usuario
done
