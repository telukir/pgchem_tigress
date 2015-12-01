#!/bin/bash
START=$(date +%s)

##################################################################################
POSTGRESQL_LIB_DIR=/usr/lib/postgresql/9.4/lib
OB_INSTALL_DIR=$POSTGRESQL_LIB_DIR/openbabel
##################################################################################
read -p "Have you set the postgresql apt repository settings?(Yy/Nn)" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Nn]$ ]]
then
	echo "Set the postgresql apt repository as given in the following website according to your version: http://www.postgresql.org/download/linux/ubuntu/"
fi
##################################################################################
echo "Required software installation. The script is trying to install following packages: gcc(build-essential, perl, python2.7, mawk, bison, flex, zlibc, libxml2"
sudo apt-get install build-essential checkinstall perl python2.7 mawk bison flex libreadline6 libreadline6-dev zlibc libeigen3-dev libcairo2-dev cmake libxml2

##################################################################################
read -p "Do you want to delete old library files?(Yy/Nn) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Delete old libraries and local postgres folder
	sudo rm $POSTGRESQL_LIB_DIR/libinchi*
	sudo rm $POSTGRESQL_LIB_DIR/libopenbabel.*
	sudo rm $POSTGRESQL_LIB_DIR/libbarsoi.so
	sudo rm $POSTGRESQL_LIB_DIR/inchiformat.so
	sudo rm $POSTGRESQL_LIB_DIR/openbabel/ -rf
	rm postgres* -rf
fi
##################################################################################
echo "Starting the process.. ==================================>>>>>>>>>>>>>>>>>>>>>>"
read -p "Have you checked the version of the Postgresql? If you have checked say (Y or y) else say (N or n) and edit your postgresql version in line 27:" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	apt-get source postgresql-9.4
	mv postgresql-9.4-9.4.5 postgresql #had to be changed accordingly
	cd postgresql
else
	exit
fi
########################################################################################
echo "Configuring PostgreSql...==============================>>>>>>>>>>>>>>>>>>>>>>>"
./configure
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "It took $(( $DIFF/60)) min $(( $DIFF%60)) sec for configuring..."
#####################################################################################
cd contrib
git clone https://github.com/telukir/pgchem_tigress.git
#git clone https://github.com/bgruening/pgchem_tigress.git
#git clone https://github.com/ergo70/pgchem_tigress.git

mv pgchem_tigress pgchem
cd pgchem/src
#cp openbabel_addon/fingerpc8.cpp openbabel-2.3.2/src/fingerprints/
# git clone https://github.com/openbabel/openbabel.git # need to take from here
mkdir openbabel-2.3.2/build
cd openbabel-2.3.2/build
###################################################################################
echo "CMake of Openbabel ========================================>>>>>>>>>>>>>>>>>>>>>"
#cmake .. -DBUILD_SHARED:BOOL=OFF -DBUILD_GUI=OFF -DBUILD_TESTING=OFF
#cmake .. -DBUILD_SHARED=OFF -DBUILD_GUI=OFF -DBUILD_TESTING=OFF
#cmake .. -DBUILD_SHARED=ON -DBUILD_GUI=OFF -DBUILD_TESTING=OFF
cmake .. -DBUILD_SHARED=ON -DBUILD_GUI=OFF -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=$OB_INSTALL_DIR
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "It took $(( $DIFF/60)) min $(( $DIFF%60)) sec for cmake...."
########################################################################################
echo "Make of Openbabel.... ===================================>>>>>>>>>>>>>>>>>>>>>>>"
make
sudo make install

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "It took $(( $DIFF/60)) min $(( $DIFF%60)) sec for make after cmake..................."
########################################################################################
cd ../../
cd barsoi
make -f Makefile.linux
echo "barsoi make done.... ===================================>>>>>>>>>>>>>>>>>>>>>>>"
cd ..
mv openbabel-2.3.2/include/openbabel/locale.h openbabel-2.3.2/include/openbabel/_locale.h
cd openbabel-2.3.2/build/lib/
ln -s ./inchiformat.so ./libinchiformat.so
cd ../../../
echo "PGChem Making .....===================================>>>>>>>>>>>>>>>>>>>>>>>>>>"
make -f Makefile.linux.x64
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "It took $(( $DIFF/60)) min $(( $DIFF%60)) sec for make of PGChem ............."
#######################################################################################
read -p "Do you want to continue to copy to your main Installation?(Yy/Nn) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	sudo cp libpgchem.so $POSTGRESQL_LIB_DIR/
	sudo cp barsoi/libbarsoi.so $POSTGRESQL_LIB_DIR/
	sudo cp openbabel-2.3.2/build/lib/libinchi.so.0.4.1 $POSTGRESQL_LIB_DIR/libinchi.so.0.4.1
	sudo cp openbabel-2.3.2/build/lib/libopenbabel.so.4.0.2 $POSTGRESQL_LIB_DIR/libopenbabel.so.4.0.2
	sudo cp openbabel-2.3.2/build/lib/inchiformat.so $POSTGRESQL_LIB_DIR/inchiformat.so
	sudo cp ../setup/tigress/obdata/dictionary* $POSTGRESQL_LIB_DIR/openbabel/share/openbabel/2.3.2/
	cd $POSTGRESQL_LIB_DIR/
	sudo ln -s libinchi.so.0.4.1 libinchi.so.0
	sudo ln -s libinchi.so.0 libinchi.so
	sudo ln -s libopenbabel.so.4.0.2 libopenbabel.so.4
	sudo ln -s libopenbabel.so.4 libopenbabel.so
	sudo ln -s inchiformat.so libinchiformat.so 

	echo '$POSTGRESQL_LIB_DIR/' | sudo tee -a /etc/ld.so.conf.d/libc.conf
	sudo ldconfig
fi

read -p "Do you want to continue to copy to your /usr/lib location?(Yy/Nn) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	sudo ln -s $POSTGRESQL_LIB_DIR/libinchi.so.0.4.1 /usr/lib/libinchi.so.0
	sudo ln -s $POSTGRESQL_LIB_DIR/inchiformat.so /usr/lib/inchiformat.so
	sudo ln -s $POSTGRESQL_LIB_DIR/libinchi.so.0 /usr/lib/libinchi.so
	sudo ln -s $POSTGRESQL_LIB_DIR/libopenbabel.so.4 /usr/lib/libopenbabel.so
	sudo ln -s $POSTGRESQL_LIB_DIR/libbarsoi.so /usr/lib/libbarsoi.so
fi
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "It took $(( $DIFF/60)) min $(( $DIFF%60)) sec for complete process"
