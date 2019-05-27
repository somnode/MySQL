# real utilization 49%

ERROR=0

CDATE=`date '+%y%m%d'`
BENCHMARK=copytar

/etc/init.d/mysqld stop
rm -rf /mnt/*

#	echo -e "n\n\n\n\n+64G\nw\n" | fdisk /dev/sdc
#mkfs.ext4 /dev/sdc1
#mount /dev/sdc1 /mnt

echo "filecopy Statr"
cp -r ~/tpcc/data /mnt/
#mv /mnt/data_tpcc_100 /mnt/data
cd ~/MySQL/tpcc-mysql/
cp my.cnf /etc/
cp my.cnf /etc/mysql/
cp my.cnf /mnt/

cd ../mysql-5.6.14
make -j9
make install

mkdir -p /mnt/InnoDB/redoLogs
mkdir -p /mnt/InnoDB/undoLogs
mkdir -p /mnt/InnoDB/ib_data
chgrp -R mysql /mnt
chown -R mysql /mnt/data
mkdir /mnt/logs /mnt/tmp
chown mysql:mysql /mnt/tmp
chown mysql:mysql /mnt/logs

cd /mnt/scripts
#cp /mnt/share/english/errmsg.sys /usr/share/mysql/errmsg.sys
chown -R mysql:mysql /mnt
./mysql_install_db --basedir=/mnt --user=mysql --datadir=/mnt/data

cd /mnt/support-files
cp mysql.server /etc/init.d/mysqld

update-rc.d mysqld defaults
echo "/mnt/lib" > /etc/ld.so.conf.d/mysql.conf
cd /mnt
ln -s lib lib64

rm /usr/local/bin/mysql*
ln -s /mnt/bin/mysql /usr/local/bin/mysql
ln -s /mnt/bin/mysqladmin /usr/local/bin/mysqladmin
ln -s /mnt/bin/mysqldump /usr/local/bin/mysqldump
ln -s /mnt/bin/mysql_config /usr/local/bin/mysql_config

cp /mnt/bin/mysqld_safe /usr/bin/mysqld_safe
systemctl daemon-reload
/etc/init.d/mysqld start

echo 3 > /proc/sys/vm/drop_caches
cd /home/somnode/MySQL/tpcc-mysql
echo "FILEBENCH START"
LD_LIBRARY_PATH=/mnt/lib/ ./tpcc_start -h 127.0.0.1 -P 3306 -d tpcc100 -u root -p "" -w 100 -c 30 -r 120 -l 600 > ~/tpcc/tpcc.trace
echo "FILEBENCH END"
