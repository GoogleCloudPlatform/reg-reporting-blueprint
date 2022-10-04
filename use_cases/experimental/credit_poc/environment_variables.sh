

source ../../../environment-variables.sh
export CREDIT_POC_BQ_DATA=creditrisk_dev
export TRAINING_DATA_TABLE=training_data
export TENSORBOARD_INSTANCE=3973582246224330752 # Put a valid instance

echo -e "\tUse case: Credit Risk PoC:"
echo -e "\t\tCREDIT_POC_BQ_DATA               :" $CREDIT_POC_BQ_DATA
echo -e "\t\tTRAINING_DATA_TABLE              :" $TRAINING_DATA_TABLE
echo -e "\t\tTENSORBOARD_INSTANCE             :" $TENSORBOARD_INSTANCE
echo -e "\n\n"
