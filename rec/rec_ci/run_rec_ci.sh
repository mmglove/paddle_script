#!/usr/bin/env bash
#param:
#imagename= paddlepaddle/paddle_manylinux_devel:cuda10.0-cudnn7
#paddle= develop_0.0.0\release_1.8.3
#python= 36
#################################
export GITHUB_API_TOKEN=dc7a0ebeb745af7689601ec00ce986a38e1f7f67
export GIT_PR_ID=
branch=$(echo "%teamcity.build.branch%")
echo $branch
if [[ $branch == *"pull/"* ]]; then
    export GIT_PR_ID=$(echo $branch | sed 's/[^0-9]*//g')
fi
echo -e "\033[35m ---- GIT_PR_ID: ${GIT_PR_ID} \033[0m"
#################################
#git config --global user.name "Paddle CI"
#git config --global user.email "paddle_ci@example.com"
#set +e
#git remote | grep upstream
#if [ $? == 1 ]; then git remote add upstream https://github.com/PaddlePaddle/PaddleRec.git; fi
#set -e
#git fetch upstream
#git checkout -b origin_pr
#git checkout -b test_pr upstream/%BRANCH%
#git merge --no-edit origin_pr
#git log --pretty=oneline -10
#set +e
#################################
export CUDA_SO="$(\ls /usr/lib64/libcuda* | xargs -I{} echo '-v {}:{}') $(\ls /usr/lib64/libnvidia* | xargs -I{} echo '-v {}:{}')"
export DEVICES=$(\ls /dev/nvidia* | xargs -I{} echo '--device {}:{}')
export NVIDIA_SMI="-v /usr/bin/nvidia-smi:/usr/bin/nvidia-smi"
nvidia-docker run -i --rm $CUDA_SO $DEVICES $NVIDIA_SMI \
--name Rec_CI_gmm_${GIT_PR_ID} --privileged \
--security-opt seccomp=unconfined --net=host \
-v $PWD:/workspace  \
-v /ssd1/guomengmeng01:/paddle \
-v /ssd1:/ssd1 \
-w /workspace \
-e "GIT_PR_ID=${GIT_PR_ID}" \
-e "GITHUB_API_TOKEN=${GITHUB_API_TOKEN}" \
paddlepaddle/paddle_manylinux_devel:cuda10.0-cudnn7 \
/bin/bash -c "
set -x
export http_proxy=%http_proxy%;
export https_proxy=%http_proxy%;
cp -r /paddle/rec_ci/. ./;
#bash rec_env.sh %python% %paddle% %http_proxy%;
#bash run_demo %run_demo% %run_con%;
bash rec_env.sh 37 develop_0.0.0 http://172.19.57.45:3128;
bash run_demo.sh run_demo no;
"
exit_code=$?
if [ $exit_code != 0 ]
then
    echo "FAIL"
    exit $exit_code
fi
