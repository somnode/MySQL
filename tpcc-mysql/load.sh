/etc/init.d/mysqld stop

rm -rf /mysql/*

# mysql build
cd ../mysql-5.6.14/
make -j9
make install

mkdir -p /mysql/InnoDB/redoLogs
mkdir -p /mysql/InnoDB/undoLogs
mkdir -p /mysql/InnoDB/ib_data

chgrp -R mysql-lxc /mysql
chown -R mysql-lxc /mysql/data
mkdir /mysql/logs /mysql/tmp
chown mysql-lxc:mysql-lxc /mysql/tmp /mysql/logs

cd ~/MySQL/tpcc-mysql/
cp my.cnf /etc/
cp my.cnf /etc/mysql/
cp my.cnf /etc/mysql/conf.d/
cp my.cnf /mysql/

cd /mysql/scripts
#cp /mysql/share/english/errmsg.sys /usr/share/mysql/errmsg.sys
chown -R mysql-lxc:mysql-lxc /mysql
./mysql_install_db --defaults-file=/mysql/my.cnf --basedir=/mysql --user=mysql-lxc --datadir=/mysql/data

cd /mysql/support-files
cp mysql.server /etc/init.d/mysqld

update-rc.d mysqld defaults
echo "/mysql/lib" > /etc/ld.so.conf.d/mysql.conf
cd /mysql
ln -s lib lib64

rm /usr/local/bin/mysql*
ln -s /mysql/bin/mysql /usr/local/bin/mysql
ln -s /mysql/bin/mysqladmin /usr/local/bin/mysqladmin
ln -s /mysql/bin/mysqldump /usr/local/bin/mysqldump
ln -s /mysql/bin/mysql_config /usr/local/bin/mysql_config

cp /mysql/bin/mysqld_safe /usr/bin/mysqld_safe
systemctl daemon-reload
/etc/init.d/mysqld start

# load data
cd ~/MySQL/tpcc-mysql
/mysql/bin/mysqladmin create tpcc100
/mysql/bin/mysql tpcc100 < create_table.sql
/mysql/bin/mysql tpcc100 < add_fkey_idx.sql
LD_LIBRARY_PATH=/mysql/lib/ ./tpcc_load -h localhost -d tpcc100 -u root -p "" -w 100

/etc/init.d/mysqld stop

# copy for backup
cp -r /mysql/data ~/tpcc/
echo "data copy completed."

:<<'END'
export LD_LIBRARY_PATH=/usr/local/mysql/lib/mysql/
DBNAME=$1
WH=$2
HOST=127.0.0.1
STEP=100

./tpcc_load -h $HOST -d $DBNAME -u root -p "" -w $WH -l 1 -m 1 -n $WH >> 1.out &

x=1

while [ $x -le $WH ]
do
 echo $x $(( $x + $STEP - 1 ))
./tpcc_load -h $HOST -d $DBNAME -u root -p "" -w $WH -l 2 -m $x -n $(( $x + $STEP - 1 ))  >> 2_$x.out &
./tpcc_load -h $HOST -d $DBNAME -u root -p "" -w $WH -l 3 -m $x -n $(( $x + $STEP - 1 ))  >> 3_$x.out &
./tpcc_load -h $HOST -d $DBNAME -u root -p "" -w $WH -l 4 -m $x -n $(( $x + $STEP - 1 ))  >> 4_$x.out &
 x=$(( $x + $STEP ))
done
END
