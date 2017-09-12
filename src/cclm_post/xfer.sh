#!/bin/bash -l
#SBATCH --account=pr04
#SBATCH --nodes=1
#SBATCH --partition=xfer
#SBATCH --time=4:00:00
#SBATCH --output=logs/xfer_%j.out
#SBATCH --error=logs/xfer_%j.err
#SBATCH --job-name="xfer_sh"

source ./settings.sh
args=""
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
      -g|--gcm)
      GCM=$2
      args="${args} -g $2"
      shift
      ;;
      -x|--exp)
      EXP=$2
      args="${args} -x $2"
      shift
      ;;
      -s|--start)
      startyear=$2
      shift
      ;;
      -e|--end)
      endyear=$2
      args="${args} -e $2"
      shift
      ;;
      *)
      echo "unknown option!"
      ;;
  esac
  shift
done

EXPPATH=${GCM}/${EXP}
INPDIR=${INDIR_BASE1}/${EXPPATH}
ARCH_SUB=${GCM}_Hist_RCP85/${EXP}  #subdirectory where data of this simulation are archived
ARCHDIR=${ARCH_BASE}/${ARCH_SUB} # join archive paths
xfer=${SCRATCH}/CMOR/logs/shell/${GCM}_${EXP}_xfer

if [ ! -d ${INPDIR} ]
then
  mkdir -p ${INPDIR}
fi

#skip already extracted years
(( NEXT_YEAR=startyear + 1 ))
while [ -d ${INPDIR}/*${NEXT_YEAR} ] && [ ${NEXT_YEAR} -le ${endyear} ]
do
  echo "Input files for year ${NEXT_YEAR} have already been extracted. Skipping..."
  (( NEXT_YEAR=NEXT_YEAR + 1 ))
done


if [ ${NEXT_YEAR} -le ${endyear} ]
then
  sbatch  --job-name=CMOR_sh --error=${xfer}.${NEXT_YEAR}.err --output=${xfer}.${NEXT_YEAR}.out ${SRCDIR}/xfer.sh -s ${NEXT_YEAR} ${args}
fi


if [ ! -d ${INPDIR}/*${startyear} ]
then
  if [ -f ${ARCHDIR}/*${startyear}.tar ] 
  then
    echo "Extracting archive for year ${startyear}"
    tar -xf ${ARCHDIR}/*${startyear}.tar -C ${INPDIR}
    rm -r ${INPDIR}/${startyear}/input

  else
    echo "Cannot find .tar file for year ${startyear} in archive directory! Skipping..."
    exit 1
  fi
else
  echo "Input files for year ${startyear} have already been extracted. Skipping..."
fi


