#!/bin/bash

#set -eu -o pipefail # fail on error and report it, debug all lines

sudo -n true
test $? -eq 0 || exit 1 "You should have sudo privilege to run this script"

HOME=$(eval echo ~$SUDO_USER)
GREEN='\033[0;32m'
NO_COLOR='\033[0m'
PYTHON_VERSION=$(python -c 'import sys; print(".".join(map(str, sys.version_info[0:2])))')
PYTHON_VERSION_FOLDER=$(python -c 'import sys; print("python"+".".join(map(str, sys.version_info[0:2])))')
#echo "$PYTHON_VERSION_FOLDER"
OPENCV_PYTHON3_INSTALL_PATH=~/.virtualenvs/cv/lib/$PYTHON_VERSION_FOLDER/site-packages

echo -e "${GREEN}Update and upgrade packages${NO_COLOR}"

apt update
apt upgrade

echo -e "${GREEN}Installing required packages${NO_COLOR}"
	    
apt install build-essential cmake pkg-config unzip yasm git checkinstall onnx-graphsurgeon -y
apt-get install python3-dev python3-pip python3-testresources -y
sudo -H pip3 install -U pip numpy
apt-get install libtbb-dev libatlas-base-dev gfortran -y

echo -e "${GREEN}Downloading OpenCV${NO_COLOR}"

cd $HOME/Downloads
wget -O opencv.zip https://github.com/opencv/opencv/archive/refs/tags/4.9.0.zip
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/refs/tags/4.9.0.zip
unzip opencv.zip
unzip opencv_contrib.zip

echo -e "${GREEN}Create a virtual environtment for the python binding module${NO_COLOR}"
pip install virtualenv virtualenvwrapper
rm -rf ~/.cache/pip
WORKON_HOME="$HOME/.virtualenvs"
VIRTUALENVWRAPPER_PYTHON="$HOME/../../usr/bin/python3"
source /usr/local/bin/virtualenvwrapper.sh
mkvirtualenv cv -p python3
pip install numpy

echo -e "${GREEN}Procced with the installation${NO_COLOR}"
cd opencv-4.9.0
mkdir build
cd build

cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/local \
	-D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-4.9.0/modules \
	-D WITH_TBB=ON \
	-D ENABLE_FAST_MATH=1 \
	-D CUDA_FAST_MATH=1 \
	-D WITH_CUBLAS=1 \
	-D WITH_CUDA=ON \
	-D BUILD_opencv_cudacodec=OFF \
	-D WITH_CUDNN=ON \
	-D OPENCV_DNN_CUDA=ON \
	-D CUDA_ARCH_BIN=8.7 \
	-D WITH_V4L=ON \
	-D WITH_QT=OFF \
	-D WITH_OPENGL=ON \
	-D WITH_GSTREAMER=ON \
	-D OPENCV_GENERATE_PKGCONFIG=ON \
	-D OPENCV_PC_FILE_NAME=opencv.pc \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D OPENCV_PYTHON3_INSTALL_PATH="$OPENCV_PYTHON3_INSTALL_PATH" \
	-D INSTALL_PYTHON_EXAMPLES=OFF \
	-D INSTALL_C_EXAMPLES=OFF \
	-D BUILD_EXAMPLES=OFF ..
	
make -jnproc
make install
	
echo -e "${GREEN}Include the libs in your environment${NO_COLOR}"

/bin/bash -c 'echo "$HOME/../../usr/local/lib" >> $HOME/../../etc/ld.so.conf.d/opencv.conf'
ldconfig

cp -r $HOME/.virtualenvs/cv/lib/$PYTHON_VERSION_FOLDER/site-packages/cv2 $HOME/../../usr/local/lib/$PYTHON_VERSION_FOLDER/dist-packages
echo -e "PYTHON_EXTENSIONS_PATHS = [\n os.path.join('$HOME/../../usr/local/lib/$PYTHON_VERSION_FOLDER/dist-packages/cv2', 'python-$PYTHON_VERSION')\n] + PYTHON_EXTENSIONS_PATHS" >> $HOME/../../usr/local/lib/$PYTHON_VERSION_FOLDER/dist-packages/cv2/config-$PYTHON_VERSION.py
