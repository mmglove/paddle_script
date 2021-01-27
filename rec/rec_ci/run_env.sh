#!/bin/bash
echo $1 $2 $3
# set python env
case $1 in
27)
  export LD_LIBRARY_PATH=/opt/_internal/cpython-2.7.11-ucs2/lib/:${LD_LIBRARY_PATH}
  export PATH=/opt/_internal/cpython-2.7.11-ucs2/bin/:${PATH}
  ;;
35)
  export LD_LIBRARY_PATH=/opt/_internal/cpython-3.5.1/lib/:${LD_LIBRARY_PATH}
  export PATH=/opt/_internal/cpython-3.5.1/bin/:${PATH}
  ;;
36)
  export LD_LIBRARY_PATH=/opt/_internal/cpython-3.6.0/lib/:${LD_LIBRARY_PATH}
  export PATH=/opt/_internal/cpython-3.6.0/bin/:${PATH}
  ;;
37)
  export LD_LIBRARY_PATH=/opt/_internal/cpython-3.7.0/lib/:${LD_LIBRARY_PATH}
  export PATH=/opt/_internal/cpython-3.7.0/bin/:${PATH}
  ;;
esac
python -c 'import sys; print(sys.version_info[:])'
echo "python="$1
####################################
# for paddle env
set -x
python -m pip install --upgrade pip
paddle=$2
version=${paddle%_*}
version_num=${paddle#*_}
case ${version} in
release)
    unset http_proxy && unset https_proxy
    python -m pip install -U paddlepaddle-gpu==${version_num}.post100 -f https://paddlepaddle.org.cn/whl/stable.html
    export http_proxy=$3;
    export https_proxy=$3;
  ;;
develop)
  unset http_proxy
  unset https_proxy
  python -m pip install -U https://paddle-wheel.bj.bcebos.com/develop-gpu-cuda10-cudnn7-mkl/paddlepaddle_gpu-2.1.0_dev0.post100-cp37-cp37m-linux_x86_64.whl
  export http_proxy=$3;
  export https_proxy=$3;
  ;;
local)
    # need to copy
  python -m pip install /paddle/tools/paddlepaddle_gpu-0.0.0-cp37-cp37m-linux_x86_64.whl
  ;;
build)
  git clone https://github.com/PaddlePaddle/Paddle.git
  cd Paddle
  git checkout ${version_num}
  mkdir build && cd build
  cmake .. -DPY_VERSION=3.7 -DWITH_FLUID_ONLY=ON -DWITH_GPU=ON -DWITH_TESTING=OFF -DCMAKE_BUILD_TYPE=Release -DCUDA_ARCH_NAME=Auto -DWITH_DISTRIBUTE=ON
  make -j$(nproc)
  python -m pip install -U python/dist/paddlepaddle_gpu-0.0.0-cp37-cp37m-linux_x86_64.whl
  cd ../..
  ;;
esac

bash run_demo.sh run_demo