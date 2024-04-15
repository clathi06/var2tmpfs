# var2tmpfs
tmpfs var/dir saving and restore

# Problem
/var/log und /var/tmp und ggfs. Index-Dateien eines dovecot Mailservers ins RAM verschieben

# Lösung
ein bash-Skript /etc/init.d/var2tmpfs.sh, das die benötigten Verzeichnisse verwaltet
eine Service-Datei /etc/systemd/system/var2tmp.service, die Start und Stop des Skripts als Service ermöglicht.

# Setup
Die beiden Dateien als root an ihren Platz kopieren 
chmod +x /etc/init.d/var2tmpfs.sh
systemctl stop dovecot.service
/etc/init.d/var2tmpfs.sh start
grep tmpfs /etc/mounts # Überprüfen, ob die Verzeichnisse angelegt und gemountet sind
systemctl start dovecot.service
systemctl enable var2tmpfs.service
reboot
grep tmpfs /etc/mounts # nochmal Überprüfen, ob der Service den reboot überlebt



