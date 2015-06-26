#!/bin/bash
START=$(date +%s)

##################################################################################
POSTGRESQL_LIB_DIR=/usr/lib/postgresql/9.4/lib
OB_INSTALL_DIR=$POSTGRESQL_LIB_DIR/openbabel
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
apt-get source postgresql-9.4
mv postgresql-9.4-9.4.4 postgresql #had to be changed accordingly
cd postgresql
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
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "It took $(( $DIFF/60)) min $(( $DIFF%60)) sec for complete process"