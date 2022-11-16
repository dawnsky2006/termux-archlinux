#!/data/data/com.termux/files/usr/bin/bash
repo=https://mirrors.bfsu.edu.cn
folder=arch-fs
if [ -f "$folder" ]; then
	first=1
	echo "检测到已经下载过文件,正在取消下载。"
	echo "Canceling download"
fi
tarball="rootfs.tar.xz"
if [ "$first" != 1 ];then
	if [ ! -f $tarball ]; then
		echo "正在下载Rootfs。"
		echo "Downloading Rootfs"
		case `dpkg --print-architecture` in
		aarch64)
			archurl="aarch64" ;;
		arm)
			archurl="armv7" ;;
		*)
			echo "unknown architecture"; exit 1 ;;
		esac
		wget -c "$repo/archlinuxarm/os/ArchLinuxARM-${archurl}-latest.tar.gz" -O $tarball
	fi
	cur=`pwd`
	mkdir -p "$folder"
	cd "$folder"
	echo "Decompressing Rootfs"
	echo "正在解压Rootfs。"
	proot --link2symlink tar -xzvf ${cur}/${tarball}||:
	cd "$cur"
fi
mkdir -p arch-binds
bin=start-arch.sh
echo "Generating startup script"
echo "正在生成启动脚本。"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A arch-binds)" ]; then
    for f in arch-binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b arch-fs/root:/dev/shm"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to / 
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

termux-fix-shebang $bin

echo "Setting permissions"
echo "正在设置权限 $bin "

rm $folder/etc/resolv.conf
echo "nameserver 8.8.8.8">$folder/etc/resolv.conf
chmod a+x $folder/etc/resolv.conf
chmod +x $bin

echo "Clearing cache"
echo "正在删除临时文件"

rm $tarball

echo "############################"
echo "You can now type  ./${bin}  to start ArchLinux"
echo "你现在可以输入 ./${bin}  启动ArchLinux"
