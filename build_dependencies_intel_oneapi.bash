#!/bin/bash

basedir="/"
cunitsource="CUnit-2.1-3.tar.bz2"
udunitssource="udunits-2.2.28.tar.gz"
szipsource="szip-2.1.1.tar.gz"
zlibsource="zlib-1.3.1.tar.gz"
hdf5source="hdf5-1.14.3.tar.gz"
#hdf5source="hdf5-1.12.1.tar.gz"
curlsource="curl-7.76.1.tar.gz"
#netcdfcsource="netcdf-c-4.9.2.tar.gz"
netcdfcsource="netcdf-c-4.9.3-rc1.tar.gz"
netcdffsource="netcdf-fortran-4.6.1.tar.gz"
libpngsource="libpng-1.6.43.tar.gz"
jaspersource="jasper-4.2.3.tar.gz"
flexsource="flex-2.6.4.tar.gz"

CUnit="CUnit"
udunits="udunits"
szip="szip"
zlib="zlib"
hdf5="hdf5"
curl="curl"
netcdf="netcdf"
libpng="libpng"
jasper="jasper"
flex="flex"

function clean_file(){
	if [ -e $1 ]; then
		rm -rf $1
	fi
}

environ_file=${basedir}environment.bash
environ_chem_file=${basedir}environment_chem.bash
clean_file ${environ_file}
clean_file ${environ_chem_file}
touch ${environ_file} ${environ_chem_file}

function construct_envs(){
	echo $1 >> ${environ_file}
	source ${environ_file}
}

function construct_chem_envs(){
	echo "export WRF_CHEM=1" >> ${environ_chem_file}
	echo "export WRF_KPP=1" >> ${environ_chem_file}
	echo "export FLEX_LIB_DIR=${flextarget}/lib" >> ${environ_chem_file}
	echo "export LD_LIBRARY_PATH=\${FLEX_LIB_DIR}:\${LD_LIBRARY_PATH}" >> ${environ_chem_file}
	echo "export PATH=${flextarget}/bin:\${PATH}" >> ${environ_chem_file}
	echo "export YACC=\"/usr/bin/yacc -d\"" >> ${environ_chem_file}
	cat ${environ_chem_file} ${environ_file} > test.txt
	mv test.txt ${environ_chem_file}
	source ${environ_chem_file}
}

construct_envs "module load cuda intel intel-mpi"
construct_envs "export OPTIM=\"-O3\""
construct_envs "export CC=icx"
construct_envs "export CXX=icpx"
construct_envs "export CFLAGS=\${OPTIM}"
construct_envs "export CXXFLAGS=\${OPTIM}"
construct_envs "export F77=ifx"
construct_envs "export FC=ifx"
construct_envs "export F90=ifx"
construct_envs "export FFLAGS=\${OPTI}"
construct_envs "export CPP=\"icx -E\""
construct_envs "export CXXCPP=\"icpx -E\""

function build_cunit() {
	cutarget=$1
	cunits=$(sed 's/.tar.bz2//' <<< ${cunitsource})
	clean_file ${cunits}
	clean_file ${cutarget}
	echo "Building "${cunitsource}
	tar -xjf ${basedir}${cunitsource}
	cd ${basedir}${cunits}
	libtoolize --force
	aclocal
	autoheader
	automake --force-missing --add-missing
	autoconf
	./configure --prefix=${cutarget}
	make
	make install
	cd ..
}

function build_expat() {
	expatsource=${basedir}libexpat/expat
	expattarget=${basedir}expat
	cd ${expatsource}
	./buildconf.sh
	make clean
	./configure --prefix=${expattarget}
	make
	make install
	cd ${basedir}
}

function build_udunits() {
	udunitstarget=$1
	echo "Building ${udunitstarget}"
	udunitss=$(sed 's/.tar.gz//' <<< ${udunitssource})
	clean_file ${udunitss}
	clean_file ${udunitstarget}
	echo "Building "${udunitssource}
	tar -xzf ${basedir}${udunitssource}
	cd ${basedir}${udunitss}
	./configure LDFLAGS="-L//gs/bs/tga-guc-lab/dependencies/dependencies_intel_oneapi/expat/lib" CPPFLAGS="-I/gs/bs/tga-guc-lab/dependencies/dependencies_intel_oneapi/expat/include" --prefix=${udunitstarget}
	make
	make check
	make install
	cd ..
}

function build_szip() {
	sziptarget=$1
	szips=$(sed 's/.tar.gz//' <<< ${szipsource})
	clean_file ${szips}
	clean_file ${sziptarget}
	echo "Building "${szipsource}
	tar -xzf ${basedir}${szipsource}
	cd ${basedir}${szips}
	./configure --prefix=${sziptarget}
	make
	make check
	make install
	cd ${basedir}
}

function build_zlib() {
	zlibtarget=$1
	zlibs=$(sed 's/.tar.gz//' <<< ${zlibsource})
	clean_file ${zlibs}
	clean_file ${zlibtarget}
	echo "Building "${zlibsource}
	tar -xzf ${basedir}${zlibsource}
	cd ${basedir}${zlibs}
	./configure --prefix=${zlibtarget}
	make
	make check
	make install
	cd ${basedir}
}

function build_hdf5() {
	hdf5target=$1
	hdf5s=$(sed 's/.tar.gz//' <<< ${hdf5source})
	clean_file ${hdf5s}
	clean_file ${hdf5target}
	#export I_MPI_CC=mpicc
	#export I_MPI_CXX=mpiicpx
	#export I_MPI_F77=mpiifx
	#export I_MPI_F90=mpiifx
	export CC=mpiicx
	export CXX=mpiicpx
	export FC=mpiifx
	export F77=mpiifx
	export F90=mpiifx
	echo "Building "${hdf5source}
	tar -xzf ${basedir}${hdf5source}
	cd ${basedir}${hdf5s}
	mkdir ${hdf5target}

	./configure --prefix=${hdf5target} --with-zlib=${basedir}${zlib}/lib --with-szlib=${basedir}${szip}/lib --enable-hl --enable-fortran --enable-parallel --with-default-api-version=v18
	make
	make check
	make install
	make check-install
	cd ${basedir}
}

function build_curl() {
	curltarget=$1
	curls=$(sed 's/.tar.gz//' <<< ${curlsource})
	clean_file ${curls}
	clean_file ${curltarget}
	echo "Building "${curlsource}
	tar -xzf ${basedir}${curlsource}
	cd ${basedir}${curls}
	export OPTIM="-O3 -mcmodel=large -fPIC"
	# "-mcmodel=large" option is necessary
	export CC=icx
	export CXX=icpx
	export CPP="icx -E -mcmodel=large"
	export CXXCPP="icpx -E -mcmodel=large"
	export CFLAGS="${OPTIM}"
	export CXXFLAGS="${OPTIM}"
	./configure --prefix=${curltarget}
	make
	make install
	cd ${basedir}
}

function build_libpng() {
	libpngtarget=$1
	libpngs=$(sed 's/.tar.gz//' <<< ${libpngsource})
	clean_file ${libpngs}
	clean_file ${libpngtarget}
	echo "Building "${libpngsource}
	tar -xzf ${basedir}${libpngsource}
	cd ${basedir}${libpngs}
	./configure --prefix=${libpngtarget}
	make
	make install
	cd ${basedir}
}

function build_jasper() {
	jaspertarget=$1
	jaspers=$(sed 's/.tar.gz//' <<< ${jaspersource})
	clean_file ${jaspers}
	clean_file ${jaspertarget}
	echo "Building "${jaspersource}
	tar -xzf ${basedir}${jaspersource}
	cd ${basedir}${jaspers}
	mkdir ../builddir
	export jaspersourcedir=${basedir}${jaspers}
	export jasperbuilddir=${basedir}builddir
	cmake -H$jaspersourcedir -B$jasperbuilddir -DCMAKE_INSTALL_PREFIX=${jaspertarget}
	cd $jasperbuilddir
	make
	make install
	cd ${jaspertarget}
	ln -sf ./lib64 ./lib
	rm -r $jasperbuilddir
	cd ${basedir}
}

function build_netcdfc() {
	netcdfctarget=$1
	netcdfcs=$(sed 's/.tar.gz//' <<< ${netcdfcsource})
	clean_file ${netcdfcs}
	clean_file ${netcdfctarget}
	echo "Building "${netcdfcsource}
	tar -xzf ${basedir}${netcdfcsource}
	cd ${basedir}${netcdfcs}
	export CC=mpiicx
	export CXX=mpiicpx
	export FC=mpiifx
	export F77=mpiifx
	export F90=mpiifx
	export LDFLAGS="-L${basedir}${hdf5}/lib -L${basedir}${zlib}/lib -L${basedir}${curl}/lib"
	export CPPFLAGS="-I${basedir}${hdf5}/include -I${basedir}${zlib}/include -I${basedir}${curl}/include -fhonor-infinities"
	#export LIBS="-lhdf5_hl -lhdf5 -lz -lcurl -lgcc -lm -ldl -lpnetcdf"
	export OPTIM="-O3 -mcmodel=large -fPIC"
	export CPP="mpiicx -E -mcmodel=large"
	export CXXCPP="mpiicpx -E -mcmodel=large"
	export CFLAGS="${OPTIM}"
	export CXXFLAGS="${OPTIM}"
	./configure --prefix=${netcdfctarget} --enable-large-file-tests --with-pic --disable-dap --enable-netcdf-4 --enable-netcdf4 --enable-shared --enable-cdf5 --enable-parallel-tests 
	make
	make check
	make install
	cd ${basedir}
}

function build_netcdff() {
	netcdfftarget=$1
	netcdffs=$(sed 's/.tar.gz//' <<< ${netcdffsource})
	clean_file ${netcdffs}
	echo "Building "${netcdffsource}
	tar -xzf ${basedir}${netcdffsource}
	cd ${basedir}${netcdffs}
	export NCDIR=${netcdfftarget}
	export LD_LIBRARY_PATH="${NCDIR}/lib:${LD_LIBRARY_PATH}"
	export NFDIR="${netcdfftarget}"
	export CPPFLAGS="-I${NCDIR}/include"
	echo $CPPFLAGS
	export LDFLAGS="-L${NCDIR}/lib"
	export OPTIM="-O3 -mcmodel=large -fPIC"
	export CC=mpiicx
	export CXX=mpiicpx
	export FC=mpiifx
	export F77=mpiifx
	export F90=mpiifx
	export CPP="mpiicx -E -mcmodel=large"
	export CXXCPP="mpiicpx -E -mcmodel=large"
	export CPPFLAGS="-DNDEBUG -DpgiFortran ${LDFLAGS} $CPPFLAGS"
	export CFLAGS="${OPTIM}"
	#export CXXFLAGS="${OPTIM}"
	export FCFLAGS="${OPTIM}"
	export F77FLAGS="${OPTIM}"
	export F90FLAGS="${OPTIM}"
	mkdir ${basedir}${hdf5}/plugins
	construct_envs "export HDF5_PLUGIN_PATH=${basedir}${hdf5}/plugins"
	./configure --prefix=${NFDIR} --enable-large-file-tests --with-pic
	make
	make check
	make install
}

function build_flex() {
	flextarget=$1
	flexs=$(sed 's/.tar.gz//' <<< ${flexsource})
	clean_file ${flexs}
	clean_file ${flextarget}
	echo "Building "${flexsource}
	tar -xzf ${basedir}${flexsource}
	cd ${basedir}${flexs}
	./configure --prefix=${flextarget}
	make
	make check
	make install
	cd ${basedir}
}
build_expat
cutarget=${basedir}${CUnit}
build_cunit ${cutarget}
construct_envs "export LD_LIBRARY_PATH=${cutarget}/lib:\${LD_LIBRARY_PATH}"
udunitstarget=${basedir}${udunits}
build_udunits ${udunitstarget}
construct_envs "export UDUNITS2_XML_PATH=${udunitstarget}/share/udunits/udunits2.xml"
construct_envs "export PATH=${udunitstarget}/bin:\${PATH}"
sziptarget=${basedir}${szip}
build_szip ${sziptarget}
construct_envs "export LD_LIBRARY_PATH=${sziptarget}/lib:\${LD_LIBRARY_PATH}"
zlibtarget=${basedir}${zlib}
build_zlib ${zlibtarget}
construct_envs "export LD_LIBRARY_PATH=${zlibtarget}/lib:\${LD_LIBRARY_PATH}"
hdf5target=${basedir}${hdf5}
build_hdf5 ${hdf5target}
construct_envs "export PATH=${hdf5target}/bin:\${PATH}"
construct_envs "export LD_LIBRARY_PATH=${hdf5target}/lib:\${LD_LIBRARY_PATH}"
curltarget=${basedir}${curl}
build_curl ${curltarget}
construct_envs "export PATH=${curltarget}/bin:\${PATH}"
construct_envs "export LD_LIBRARY_PATH=${curltarget}/lib:\${LD_LIBRARY_PATH}"
netcdftarget=${basedir}${netcdf}
build_netcdfc ${netcdftarget}
build_netcdff ${netcdftarget}
construct_envs "export PATH=${netcdftarget}/bin:\${PATH}"
construct_envs "export LD_LIBRARY_PATH=${netcdftarget}/lib:\${LD_LIBRARY_PATH}"
libpngtarget=${basedir}${libpng}
build_libpng ${libpngtarget}
construct_envs "export PATH=${libpngtarget}/bin:\${PATH}"
construct_envs "export LD_LIBRARY_PATH=${libpngtarget}/lib:\${LD_LIBRARY_PATH}"
jaspertarget=${basedir}${jasper}
build_jasper ${jaspertarget}
construct_envs "export PATH=${jaspertarget}/bin:\${PATH}"
construct_envs "export LD_LIBRARY_PATH=${jaspertarget}/lib:\${LD_LIBRARY_PATH}"
construct_envs "export NETCDF=${netcdftarget}"
construct_envs "export HDF5=${hdf5target}"
flextarget=${basedir}${flex}
build_flex ${flextarget}
construct_chem_envs
