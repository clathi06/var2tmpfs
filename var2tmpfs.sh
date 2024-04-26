#!/bin/bash
### BEGIN INIT INFO
# Provides:          var2tmpfs
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# X-Start-Before:    $syslog
# X-Stop-After:      $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/Stop tmpfs var/dir saving
### END INIT INFO
#
# var2tmpfs.sh        This init.d script is used to start tmpfs var/dir saving and restore e.g. for a dovecot mailserver.
# idea: https://forum-raspberrypi.de/forum/thread/4046-var-log-in-eine-art-ramdisk-auslagern-weitere-optimierungen-bezgl-logs
#

PATH=/sbin:/usr/sbin:/bin:/usr/bin
BASENAME=$(basename $0)
# without dovecot index directory
[ -n "$2" ] && SAVEDIRS="$2" || SAVEDIRS="log tmp"
# with dovecot index directory
#[ -n "$2" ] && SAVEDIRS="$2" || SAVEDIRS="log tmp vmail"

function _save() {
  echo "*** Saving /var/$1 to /var/$1.save"
	[ ! -d /var/$1.save/ ] && mkdir -p /var/$1.save/
  if [ -x "$(which rsync)" ]; then
    rsync -a --delete /var/$1/ /var/$1.save/
  else
    cp -Rpu /var/$1/* /var/$1.save/
  fi
  sync
}

function _restore() {
	echo "*** Restore /var/$1 from /var/$1.save"
  cp -Rpu /var/$1.save/* /var/$1/
  sync
	df /var/$1
}

function _mount() {
  [ -n "$(grep /var/$1 /proc/mounts)" ] && return
  _save $1
  tmpfs_size=$(grep /var/$1 /etc/fstab|awk {'print $4'}|cut -d"=" -f2)
  [ -z "$tmpfs_size" ] && tmpfs_size="100M"
  echo "*** Mounting tmpfs /var/$1 with size $tmpfs_size"
  mount -t tmpfs tmpfs /var/$1 -o defaults,size=$tmpfs_size
  chmod 777 /var/$1
}

function _umount() {
  [ -z "$(grep /var/$1 /proc/mounts)" ] && return 41
  echo "*** Unmounting tmpfs /var/$1"
  umount -f /var/$1/ || return 42
}

function _start() {
	_mount $1
	_restore $1
}

function _stop() {
  _save $1
	_umount $1 || return $?
	_restore $1
}

function _main() {
	echo "*** Processing $1 for $2"
	case $1 in
		start)
			_start $2
		;;
		stop)
			_stop $2
  	;;
		mount)
			_mount $2
		;;
		umount)
			_umount $2
  	;;
		save)
			_save $2
		;;
		restore)
			_restore $2
  	;;
	esac
}

function _loop() {
	for SAVEDIR in $SAVEDIRS
	do
		_main $1 $SAVEDIR
	done
}

case $1 in
	start | stop | mount | umount | save | restore | test)
		echo "*** Processing $0 with $1 for $SAVEDIRS"
		_loop $1
	;;
  *)
		echo "Usage: $0 {start|stop|mount|umount|save|restore|test}"
    exit 1
  ;;
esac

exit 0
