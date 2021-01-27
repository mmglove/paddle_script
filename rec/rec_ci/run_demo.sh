#!/bin/bash
####################################
#export CUDA_VISIBLE_DEVICES=2
#运行目录 PaddleRec/
export repo_path=$PWD
cd ${repo_path}
# git repo
#git clone https://github.com/PaddlePaddle/PaddleRec.git -b master
pip install --upgrade pip
################
if [ -d "$PWD/logs" ];then
    rm -rf $PWD/logs;
fi
mkdir $PWD/logs
export all_log_path=$PWD/logs
print_info(){
if [ $1 -ne 0 ];then
    mv ${log_path}/$2 ${log_path}/FAIL_$2.log
    echo -e "\033[31m ${log_path}/FAIL_$2 \033[0m"
else
    mv ${log_path}/$2 ${log_path}/SUCCESS_$2.log
    echo -e "\033[32m ${log_path}/SUCCESS_$2 \033[0m"
fi
}

###########
demo13(){
#必须先声明
declare -A dic
dic=([dnn]='models/rank/dnn' [wide_deep]='models/rank/wide_deep' [deepfm]='models/rank/deepfm' [fm]='models/rank/fm' [gateDnn]='models/rank/gateDnn' [logistic_regression]='models/rank/logistic_regression' \
[esmm]='models/multitask/esmm' [mmoe]='models/multitask/mmoe' \
[dssm]='models/match/dssm' [match-pyramid]='models/match/match-pyramid' [multiview-simnet]='models/match/multiview-simnet' \
[tagspace]='models/contentunderstanding/tagspace' [textcnn]='models/contentunderstanding/textcnn')
echo ${!dic[*]}   # 输出所有的key
echo ${dic[*]}    # 输出所有的value
i=1
for model in $(echo ${!dic[*]});do
    model_path=${dic[$model]}
    echo ${model} : ${model_path}
    cd ${repo_path}/${model_path}
    # dygraph
    python -u ../../../tools/trainer.py -m config.yaml > ${log_path}/${i}_demo_${model}_dy_train 2>&1
    print_info $? ${i}_demo_${model}_dy_train
    python -u ../../../tools/infer.py -m config.yaml > ${log_path}/${i}_demo_${model}_dy_infer 2>&1
    print_info $? ${i}_demo_${model}_dy_infer
    mv output_model_${model} output_model_${model}_dy

    # static
    python -u ../../../tools/static_trainer.py -m config.yaml > ${log_path}/${i}_demo_${model}_st_train 2>&1
    print_info $? ${i}_demo_${model}_st_train
    # 静态图预测
    python -u ../../../tools/static_infer.py -m config.yaml > ${log_path}/${i}_demo_${model}_st_infer 2>&1
    print_info $? ${i}_demo_${model}_st_infer
    mv output_model_${model} output_model_${model}_st
    let i+=1
done
}

word2vec(){
cd ${repo_path}/models/recall/word2vec
model=demo_word2vec
yaml_mode=config
if [[ "$1" =~ "con" ]]; then
model=all_word2vec
yaml_mode=config_bigdata
fi
# dygraph
python -u ../../../tools/trainer.py -m ${yaml_mode}.yaml > ${log_path}/${model}_dy_train 2>&1
print_info $? ${model}_dy_train
python -u infer.py -m ${yaml_mode}.yaml > ${log_path}/${model}_dy_infer 2>&1
print_info $? ${model}_dy_infer
mv output_model_${model} output_model_${model}_dy

# 静态图训练
python -u ../../../tools/static_trainer.py -m ${yaml_mode}.yaml > ${log_path}/${model}_st_train 2>&1
print_info $? ${model}_st_train
# 静态图预测
python -u static_infer.py -m ${yaml_mode}.yaml >${log_path}/${model}_st_infer 2>&1
print_info $? ${model}_st_infer
mv output_model_${model} output_model_${model}_st

}

demo_movie_recommand(){
cd ${repo_path}/models/movie_recommand
# download
pip install py27hash
bash data_prepare.sh
model=demo_movie_recommand_rank
# 动态图训练
python -u ../../../tools/trainer.py -m rank/config.yaml > ${log_path}/${model}_dy_train 2>&1
print_info $? ${model}_dy_train
# 动态图预测
python -u infer.py -m rank/config.yaml > ${log_path}/${model}_dy_infer 2>&1
print_info $? ${model}_dy_infe
# rank模型的测试结果解析
python parse.py rank_offline rank_infer_result >${log_path}/${model}_dy_parse 2>&1
print_info $? ${model}_dy_parse
# 静态图训练
python -u ../../../tools/static_trainer.py -m rank/config.yaml > ${log_path}/${model}_st_train  2>&1
print_info $? ${model}_st_train
# 静态图预测
python -u static_infer.py -m rank/config.yaml >${log_path}/${model}_st_infer 2>&1
print_info $? ${model}_st_infer
# recall模型的测试结果解析
python parse.py recall_offline recall_infer_result >${log_path}/${model}_st_parse 2>&1
print_info $? ${model}_st_parse

model=demo_movie_recommand_recall
# 动态图训练
python -u ../../../tools/trainer.py -m recall/config.yaml > ${log_path}/${model}_dy_train 2>&1
print_info $? ${model}_dy_train
# 动态图预测
python -u infer.py -m recall/config.yaml > ${log_path}/${model}_dy_infer 2>&1
print_info $? ${model}_dy_infe
# rank模型的测试结果解析
python parse.py rank_offline rank_infer_result >${log_path}/${model}_dy_parse 2>&1
print_info $? ${model}_dy_parse
# 静态图训练
python -u ../../../tools/static_trainer.py -m recall/config.yaml > ${log_path}/${model}_st_train  2>&1
print_info $? ${model}_st_train
# 静态图预测
python -u static_infer.py -m recall/config.yaml >${log_path}/${model}_st_infer 2>&1
print_info $? ${model}_st_infer
# recall模型的测试结果解析
python parse.py recall_offline recall_infer_result >${log_path}/${model}_st_parse 2>&1
print_info $? ${model}_st_parse
}

################################################

download_all_data(){
echo  "start download  data"
cp -r ${repo_path}/datasets ${all_data}/
cd ${all_data}/datasets
for name in `ls`;
do
    if [ -d "${name}" ];then
    cd ${all_data}/datasets/${name}
    sh run.sh >${log_path}/con_${name}_down_data 2>&1
    print_info $? con_${name}_down_data
    cd -
    fi
done
}
con_dy_train_infer(){
echo "start run $1 dygraph con"
# 动态图训练
python -u ../../../tools/trainer.py -m config_bigdata.yaml > ${log_path}/con_$1_train 2>&1
print_info $? con_$1_train
# 动态图预测
python -u ../../../tools/infer.py -m config_bigdata.yaml > ${log_path}/con_$1_infer 2>&1
print_info $? con_$1_infer

}
con_st_train_infer(){
echo "start run $1 static con"
# 静态图训练
python -u ../../../tools/static_trainer.py -m config_bigdata.yaml > ${log_path}/con_$1_train 2>&1
print_info $? con_$1_train
# 静态图预测
python -u ../../../tools/static_infer.py -m config_bigdata.yaml > ${log_path}/con_$1_infer 2>&1
print_info $? con_$1_infer
}
con13(){
#必须先声明
declare -A dic
dic=([dnn]='models/rank/dnn' [wide_deep]='models/rank/wide_deep' [deepfm]='models/rank/deepfm' [fm]='models/rank/fm' [gateDnn]='models/rank/gateDnn' [logistic_regression]='models/rank/logistic_regression' \
[esmm]='models/multitask/esmm' [mmoe]='models/multitask/mmoe' \
[dssm]='models/match/dssm' [match-pyramid]='models/match/match-pyramid' [multiview-simnet]='models/match/multiview-simnet' \
[tagspace]='models/contentunderstanding/tagspace' [textcnn]='models/contentunderstanding/textcnn')
echo ${!dic[*]}   # 输出所有的key
echo ${dic[*]}    # 输出所有的value
i=1
for model in $(echo ${!dic[*]});do
    model_path=${dic[$model]}
    echo ${model} : ${model_path}
    cd ${repo_path}/${model_path}
#    con_dy_train_infer ${i}_rank_${model}_dy
#    mv output_model_all_${model} output_model_all_${model}_dy

    con_st_train_infer ${i}_rank_${model}_st
    mv output_model_all_${model} output_model_all_${model}_st
    let i+=1
done
}
################################################
run_demo(){
mkdir ${all_log_path}/demo_log
export log_path=${all_log_path}/demo_log
demo13
word2vec
demo_movie_recommand
}
################################################
run_con(){
mkdir ${all_log_path}/con_log
export log_path=${all_log_path}/con_log
if [ ! -d "${all_data}/datasets" ];then
    download_all_data
fi
mv ${repo_path}/datasets ${repo_path}/datasets_bk
ln -s ${all_data}/datasets ${repo_path}/datasets

# rank
con13
word2vec con
}
################################################
#run_demo
#run_con


$1
$2

cd ${log_path}
FF=`ls *FAIL_*|wc -l`
if [ "${FF}" -gt "0" ];then
    exit 1
else
    exit 0
fi
