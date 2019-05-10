sudo apt-get install libmysqlclient20 libmysqlclient-dev
sudo apt-get install gcc g++

# if using ubuntu 18.04, should reinstall gcc/g++ to gcc/g++ 5
# install gcc, g++
sudo apt install g++-5
sudo apt install gcc-5
# change the symlink to point to gcc 5 and g++ 5
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 10
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 20
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 20
sudo update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30
sudo update-alternatives --set cc /usr/bin/gcc
sudo update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30
sudo update-alternatives --set c++ /usr/bin/g++

sudo apt-get install fakeroot build-essential ncurses-dev xz-utils libssl-dev bc

tar -xvf mysql-5.6.14.tar.gz
cd mysql-5.6.14/
cmake . -DCMAKE_INSTALL_PREFIX=/mnt/ -DMYSQL_DATADIR=/mnt/data -DMYSQL_UNIX_ADDR=/var/run/mysqld/mysqld.sock -DSYSCONFDIR=/etc -DMYSQL_TCP_PORT=3306 -DMYSQL_USER=mysql -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=all -DENABLED_LOCAL_INFILE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1
make
sudo make install

sudo groupadd -g 27 -o -r mysql
sudo useradd -M -g mysql -o -r -d /mnt/data -s /bin/false -c “Mysql” -u 27 mysql

#- 디렉토리 생성 및 권한 설정
sudo mkdir -p /mnt/InnoDB/redoLogs
sudo mkdir -p /mnt/InnoDB/undoLogs
sudo mkdir -p /mnt/InnoDB/ib_data
sudo chgrp -R mysql /mnt
sudo chown -R mysql /mnt/data
sudo mkdir /mnt/logs /mnt/tmp
sudo chown mysql:mysql /mnt/tmp /mnt/logs

#- MariaDB system table 설치
cd /mnt/scripts
mkdir /usr/share/mysql
cp /mnt/share/english/errmsg.sys /usr/share/mysql/
sudo chown -R mysql:mysql /mnt
sudo ./mysql_install_db --basedir=/mnt --user=mysql --datadir=/mnt/data
 
#- mysqld startup script 설정
cd /mnt/support-files
sudo cp mysql.server /etc/init.d/mysqld

#* CentOS
#chkconfig –add mysqld
 
#* Debian, Ubuntu
update-rc.d mysqld defaults

#- library 등록
sudo su
echo “/mnt/lib” > /etc/ld.so.conf.d/mysql.conf

#* 64bit의 경우
cd /mnt
ln -s lib lib64

#- my.cnf 생성
cd /mnt/support-files
cp my-default.cnf /etc/my.cnf

#- 주요 명령어 등록
ln -s /mnt/bin/mysql /usr/local/bin/mysql
ln -s /mnt/bin/mysqladmin /usr/local/bin/mysqladmin
ln -s /mnt/bin/mysqldump /usr/local/bin/mysqldump
ln -s /mnt/bin/mysql_config /usr/local/bin/mysql_config

#4. MariaDB 실행
cp /mnt/bin/mysqld_safe /usr/bin/mysqld_safe
/etc/init.d/mysqld start
 
#- Root password 설정
#mysqladmin -u root password ‘new-password’
