/etc/init.d/mysqld stop

rm -rf /mnt/*

# mysql build
cd ../mysql-5.6.14/BUILD
make -j9
make install

mkdir -p /mnt/InnoDB/redoLogs
mkdir -p /mnt/InnoDB/undoLogs
mkdir -p /mnt/InnoDB/ib_data

chgrp -R mysql /mnt
chown -R mysql /mnt/data
mkdir /mnt/logs /mnt/tmp
chown mysql:mysql /mnt/tmp /mnt/logs

cd ../..
cp my.cnf /etc/
cp my.cnf /etc/mysql/
cp my.cnf /mnt/

cd /mnt/scripts
cp /mnt/share/english/errmsg.sys /usr/share/mysql/errmsg.sys
chown -R mysql:mysql /mnt
./mysql_install_db --defaults-file=/mnt/my.cnf --basedir=/mnt --user=mysql --datadir=/mnt/data

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

# load data
cd /home/somnode/MySQL/tpcc-mysql
/mnt/bin/mysqladmin create tpcc100
/mnt/bin/mysql tpcc100 < create_table.sql
/mnt/bin/mysql tpcc100 < add_fkey_idx.sql
LD_LIBRARY_PATH=/mnt/lib/ ./tpcc_load -h localhost -d tpcc100 -u root -p "" -w 100

/etc/init.d/mysqld stop

# copy for backup
cp -r /mnt/data ~/tpcc/
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
