source ../../../environment-variables.sh

# Edit to reflect use-case specific vars
export EBADPM_BQ_DEV=ebadpm_dev
export EBADPM_BQ_DATA=ebadpm_data
export DPM_PROJECT_ID=scannell-fsi-dev
echo -e "\tUse case: EBA Data Point Model:"
echo -e "\t\tEBADPM_BQ_DEV                    :" $EBADPM_BQ_DEV
echo -e "\t\tEBADPM_BQ_DATA                   :" $EBADPM_BQ_DATA
echo -e "\t\tDPM_PROJECT_ID                   :" $DPM_PROJECT_ID
echo -e "\t\tDPM_DATASET                      :" $DPM_DATASET
echo -e "\n"
