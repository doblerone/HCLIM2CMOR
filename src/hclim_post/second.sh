#!/bin/ksh
#-------------------------------------------------------------------------
# Concatenats monthly time series files produced by CCLM chain script post
# to annual file for a given time period of years and creates additional 
# fields required by CORDEX
# 
# K. Keuler, Matthias Göbel 
# latest version: 15.09.2017
# HCLIM Version: Autumn 2019, Andreas Dobler / MET Norway
#-------------------------------------------------------------------------

typeset -Z2 MM MA ME MP MMA MME DHH EHH
typeset -Z4 YY YYA YYE YP


#---------------------------------------------------------------------
PERM=755 #Permission settings for output files

export IGNORE_ATT_COORDINATES=0

#variables
# all HCLIM variables representing a time interval (min, max, average, accumulated)
accu_list="evspsbl evspsbs evspsbl_P01 evspsbl_P02 hfls_eva hfls_sbl hfss mrrod mrros mrro prgrpl prrain prsnow rids rlds rlns rlnt rsdsdir rsds rsdt rsns rsnt tauu tauv pr hfls rlus rsus"
  
#all instantaneous variables
inst_list="albl cape cin clh cli100m cli200m cli300m cli400m cli50m clivi cll clm clt100m clt200m clt300m clt400m clt50m clt clw100m clw200m clw300m clw400m clw50m clwvi hurs hus1000 hus100m hus200 hus200m hus300m hus350 hus400m hus500 hus50m hus600 hus700 hus775 hus850 hus900 hus925 hus950 huss mrfso mrso p100m p200m p300m p400m p50m pcape pcin phi1000 phi200 phi350 phi500 phi600 phi700 phi775 phi850 phi900 phi925 phi950 prw ps psl sfcWindmax sic sncl snd_P01 snd_P02 snm snw_b_P01 snw_b_P02 sst ta1000 ta100m ta200 ta200m ta300m ta350 ta400m ta500 ta50m ta600 ta700 ta775 ta850 ta900 ta925 ta950 taL65 tas tas_nature tas_P01 tas_P02 tas_sea tas_town tas_water tg_L01_P01 tg_L01_P02 tg_L10_P01 tg_L10_P02 tg_L11_P01 tg_L11_P02 ticr tkeL65 ts_nature ts_rad ts ts_water tswi_L01_P01 tswi_L01_P02 tswil_L01 tswi twcr ua1000 ua100m ua200 ua200m ua300m ua350 ua400m ua500 ua50m ua600 ua700 ua775 ua850 ua900 ua925 ua950 uas va1000 va100m va200 va200m va300m va350 va400m va500 va50m va600 va700 va775 va850 va900 va925 va950 vas w1000 w200 w350 w500 w600 w700 w775 w850 w900 w925 w950 wsa_L01_P01 wsa_L01_P02 z0 zmla tasmax tasmin ugsm vgsm mrsol wsgsmax"

# constant variables
const_list=""

#additional variables
add_list=""

#-----------------------------------------------------------------------

# create subdirectory for full time series
[[ -d ${OUTDIR2} ]] || mkdir -p  ${OUTDIR2}
#Create and change to WORKDIR
[[ -d ${WORKDIR} ]] || mkdir -p  ${WORKDIR} 
cd ${WORKDIR}
#################################################
YY=$YYA

#copy constant variables
for constVar in ${const_list}
do 
  if [[ ! -e ${OUTDIR2}/${constVar}/${constVar}.nc ]] || ${overwrite} 
  then
    if [[ -e ${INDIR2}/${constVar}.nc ]]
    then
      echon "Copy constant variable ${constVar}.nc to output folder"
      [[ -d ${OUTDIR2}/${constVar} ]] || mkdir ${OUTDIR2}/${constVar}
      cp ${INDIR2}/${constVar}.nc ${OUTDIR2}/${constVar}/
    else
      echo "Required constant variable file ${constVar}.nc is not in input folder ${INDIR2}! Skipping this variable..."
    fi
  fi
done


while [[ ${YY} -le ${YYE} ]]      # year loop
do
  echo ""
  echo "####################"
  echo ${YY}
  echo "####################"
  DATE1=$(date +%s)
	
    #check if directories for all months exist
  MMA=01 #first month of each yearly time-series
  MME=12 #last month of each yearly time-series
  MM=${MMA}
  start=true
  endmonth=${MME}
  while [[ ${MM} -le ${endmonth} ]] 
  do 
    if [[ ! -d ${INDIR2}/${YY}_${MM} ]] 
    then
      echo "Directory ${INDIR2}/${YY}_${MM} does not exist!"
      if ${start}
      then
        (( MMA=MMA+1))
      else
        (( MME=MMA-1))
      fi
    else
      start=false
    fi
    (( MM=MM+1 ))
  done
  if ! ${proc_all} 
  then
    FILES=${proc_list} 
  else
    FILES=$(ls ${INDIR2}/${YY}_${MMA}/*_ts.nc)
  fi
  

  if [[ ${LFILE} -ne 2 ]] 
  then
  # concatenate monthly files to annual file
    for FILE in ${FILES}        # var name loop
    do
      FILEIN=$(basename ${FILE})
      
      if  ${proc_all}  
      then
        (( c2 = ${#FILEIN}-6 ))
        FILEOUT=$(echo ${FILEIN} | cut -c1-${c2}) # cut off "_ts.nc"
      else
        FILEOUT=${FILE} 
      fi
      
      varname=${FILEOUT}

      #process variable if in proc_list or if proc_all is set
      if [[ ${proc_list} =~ (^|[[:space:]])${varname}($|[[:space:]]) ]] || ${proc_all}
      then
        if ls ${OUTDIR2}/${FILEOUT}/${FILEOUT}_${YY}* 1> /dev/null 2>&1 
        then
          if ${overwrite} 
          then    
            echon ""
            echon ${FILEOUT}
            echon "File for variable ${FILEOUT} and year ${YY} already exists. Overwriting..."
          else
            echov ""
            echov "File for variable ${FILEOUT} and year ${YY} already exists. Skipping..."
            continue
          fi
        else
          echon ""
          echon ${FILEOUT}
        fi

      else
        continue
      fi
      


      # determine if current variable is an accumulated or instantaneous quantity
      if [[ ${accu_list} =~ (^|[[:space:]])${varname}($|[[:space:]]) ]]
      then
        LACCU=1
        echon "${varname} is accumulated variable"
      elif [[ ${inst_list} =~ (^|[[:space:]])${varname}($|[[:space:]]) ]]
      then
        LACCU=0
        echon "${varname} is an instantaneous variable"
      elif [[ ${add_list} =~ (^|[[:space:]])${varname}($|[[:space:]]) ]]
      then
        continue
      else
        echo "Error for ${varname}: neither contained in accu_list nor in inst_list! Skipping..."
        continue
      fi
      
      

      FILELIST=""
      MA=${MMA}
      ME=${MME}
      MM=${MA}
       
      while [[ ${MM} -le ${ME} ]] 
      do 
        if [[ ! -e ${INDIR2}/${YY}_${MM}/${FILEOUT}_ts.nc ]] 
        then
          echo "WARNING: File ${INDIR2}/${YY}_${MM}/${FILEOUT}_ts.nc does not exist! Continue anyway..."
          #continue 2
        fi
        FILELIST="$(echo ${FILELIST}) $(ls ${INDIR2}/${YY}_${MM}/${FILEOUT}_ts.nc)"
        (( MM=MM+1 ))
      done
      echon "Concatenate files"
      echov "${FILELIST}"
      # concatenate monthly files to yearly file
      FILEIN=${FILEOUT}_${YY}${MA}-${YY}${ME}.nc
      export SKIP_SAME_TIME=1
      cdo mergetime ${FILELIST} ${FILEIN}.tmp
      cdo setgrid,${DATADIR}/griddes.txt ${FILEIN}.tmp ${FILEIN}.tmp2
      cdo selindexbox,9,581,9,493 ${FILEIN}.tmp2 ${FILEIN}

      [ -f ${FILEIN}.tmp ] && rm ${FILEIN}.tmp
      [ -f ${FILEIN}.tmp2 ] && rm ${FILEIN}.tmp2

      # extract attribute units from variable time -> REFTIME in ... since XX-XX-XX ...
      RT=$(ncks -m -v time  ${FILEIN} | grep -E 'since' | sed s/".*since "//)

      REFTIME="days since "${RT}
      # extract number of timesteps and timestamps
      NT=$(cdo -s ntime ${FILEIN})
      VT=($(cdo -s showtimestamp ${FILEIN}))
      TYA=$(echo ${VT[0]} | cut -c1-4)
      TMA=$(echo ${VT[0]} | cut -c6-7)
      TDA=$(echo ${VT[0]} | cut -c9-10)
      THA=$(echo ${VT[0]} | cut -c12-13)
      TDN=$(echo ${VT[1]} | cut -c9-10)
      THN=$(echo ${VT[1]} | cut -c12-13)
      TYE=$(echo ${VT[-1]} | cut -c1-4)
      TME=$(echo ${VT[-1]} | cut -c6-7)
      TDE=$(echo ${VT[-1]} | cut -c9-10)
      THE=$(echo ${VT[-1]} | cut -c12-13)
      (( DHH=(TDN-TDA)*24+THN-THA ))
      (( EHH=24-DHH ))
      (( DTS=DHH*1800 ))
      echov "First date: ${VT[0]} "
      echov "Last date: ${VT[-1]} "
      echov "Number of timesteps: $NT"
      echov "Time step: $DHH h"
      echov "New reference time: ${REFTIME}"

      #create output directory
      [[ -d ${OUTDIR2}/${FILEOUT} ]] || mkdir ${OUTDIR2}/${FILEOUT}
      
      if [[ ${LACCU} -eq 1 ]] 
      then
  #   Check dates in files for accumulated variables
  #   if necessary: delete first date apend first date of next year
        if [[ ${TDA} -eq 01 && ${THA} -eq 00 ]]
        then
          echov "Eliminating first time step from tmp1-File"
          ncks -O -h -d time,1, ${FILEIN} ${FILEOUT}_tmp1_${YY}.nc
        elif [[ ${TDA} -eq 01 &&  ${THA} -eq ${DHH} ]]
        then
          echov "Number of timesteps in tmp1-File is OK"
          cp ${FILEIN} ${FILEOUT}_tmp1_${YY}.nc
        else
          echo "Error: Start date  ${TDA} ${THA}"
          echo in "${FILEIN} "
          echo "is not correct! Exiting..."
          continue
        fi
        if [[ ${TDE} -ge 28 && ${THE} -eq ${EHH} ]]
        then
          YP=${YY}
          (( MP=TME+1 ))
          if [[ ${MP} -gt 12 ]] 
          then
            MP=01
            (( YP=YP+1 ))
          fi
          FILENEXT=${INDIR2}/${YP}_${MP}/${FILEOUT}_ts.nc
          if [[ -e ${FILENEXT} ]] 
          then
            echov "Append first date from next month's file to the end of current month"
            ncks -O -h -d time,0 ${FILENEXT} ${FILEOUT}_tmp2_${YY}.nc
            ncrcat -O -h  ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp2_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc
          else
            echo "ERROR: Tried to append first date from next month's file but"
            echo "${FILENEXT} does not exist. Skip year for this variable..."
            continue
          fi
        elif [[ ${TDE} -eq 01 &&  ${THE} -eq 00 ]]
        then
          (( MP=TME ))
          (( YP=TYE ))
          echov "Last timestep in tmp3-File is OK"
          mv ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc
        else
          echo "ERROR: END date  ${TDE} ${THE}"
          echo in "${FILEIN} "
          echo "is not correct. Skip year for this variable..."
          continue
        fi
        ENDFILE=${OUTDIR2}/${FILEOUT}/${FILEOUT}_${TYA}${TMA}${TDA}00-${YP}${MP}0100.nc
  #     shift time variable by half a timestep and set reference time       
        echov "Modifying time and time_bnds values and attributes"
        cdo shifttime,-${DTS}second ${FILEOUT}_tmp3_${YY}.nc ${ENDFILE}
        ncatted -O -h -a units,time,o,c,"${REFTIME}" -a units,time_bnds,o,c,"${REFTIME}" ${ENDFILE}
      else
  #   Check dates in files for instantaneous variables
        if [[ ${TDA} -eq 01 && ${THA} -eq 00 ]]
        then
          echov "First date of instantaneous file is OK"
          cp ${FILEIN} ${FILEOUT}_tmp1_${YY}.nc          
        else
          echo "ERROR: Start date " ${TDA} ${THA}
          echo in "${FILEIN} "
          echo "is not correct.  Skip year for this variable..."
          continue       
        fi
        if [[ ${TDE} -ge 28  && ${THE} -eq ${EHH} ]]
        then
          echov "Last date of instantaneous file is OK"
          mv ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc
        elif  [[ ${TDE} -eq 01 && ${THE} -eq 00 ]]
        then
          (( NTM=NT-2 )) 
          echov "Last date of instantaneous file is removed"
          ncks -O -h -d time,0,${NTM} ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc
          #change TDE
          VT=($(cdo -s showtimestamp ${FILEOUT}_tmp3_${YY}.nc))
          TDE=$(echo ${VT[-1]} | cut -c9-10)
        else
          echo "ERROR: END date " ${TDE} ${THE}
          echo in "${FILEIN} "
          echo "is not correct.  Skip year for this variable..."
          echo ${EHH}
          continue       
        fi
        ENDFILE=${OUTDIR2}/${FILEOUT}/${FILEOUT}_${TYA}${TMA}${TDA}00-${YY}${ME}${TDE}${EHH}.nc
  #    remove time_bnds from instantaneous fields and set reference time
        echov "Modifying reference time"
        ncks -O -C -h -x -v time_bnds ${FILEOUT}_tmp3_${YY}.nc ${ENDFILE}
        ncatted -O -h -a units,time,o,c,"${REFTIME}" -a bounds,time,d,, ${ENDFILE}    
      fi


      echov "Output to $ENDFILE"
  #   change permission of final file
      chmod ${PERM} ${ENDFILE}
  #
  #   clean temporary files
      rm -f ${FILEOUT}_tmp?_${YY}.nc
      #rm ${FILEIN}

    done                    # var name loopende
#
  fi                              #concatenate part



  #
  # create additional fields required by ESGF
  #
  function create_add_vars {
    name1=$1 #first input variable
    name2=$2 #second input variable
    name3=$3 #output variable
    formula=$4 #formula how to create output variable
    standard_name=$5
    if [[ ${formula} == "add" ]]
    then
      formula="${name3}=${name1}+${name2}"
    elif [[ ${formula} == "subs" ]]
    then
      formula="${name3}=${name1}-${name2}"
    elif [[ ${formula} == "add_sqr" ]]
    then
      formula="${name3}=sqrt(${name1}^2+${name2}^2)"
    #MED>>
    elif [[ ${formula} == "snow_case" ]]
    then
      #MED: FR_SNOW=Max(0.01,Min(1.,W_SNOW/0.015))*H(x) with H(x)=1 if W_SNOW>0.5E-06, else H(x)=0
      formula="SNOW_flg=float($name1>0.0000005);SNOW=float($name1/0.015);where(SNOW>1.0)SNOW=1.0f;where(SNOW<0.01)SNOW=0.01f;$name3=float(SNOW*SNOW_flg)"
    #MED<<
    else
      echo "Formula ${formula} not known! Skipping"
      return
    fi
        
    if [[ ${proc_list} =~ (^|[[:space:]])${name3}($|[[:space:]]) ]] || ${proc_all}
    then
      file1=$(ls ${OUTDIR2}/${name1}/${name1}_${YY}${MMA}0100*.nc) 
      #MED>> file2=$(ls ${OUTDIR2}/${name2}/${name2}_${YY}${MMA}0100*.nc)
      if [[ ${name2} == "" ]]
      then
        file2=""
      else
        file2=$(ls ${OUTDIR2}/${name2}/${name2}_${YY}${MMA}0100*.nc)
      fi
      #MED<<
      echov "Input files and formula:"
      echov "$file1"
      echov "$file2"
      echov "$formula"

      #MED>> if [[ -f ${file1} && -f ${file2} ]] 
      if [[ -e ${file1} ]]
      #MED<<
      then
        ((c1 = ${#file1}-23 )) 
        ((c2 = ${#file1}-3 ))
        DATE=$(ls ${file1} |cut -c${c1}-${c2})
        file3=${OUTDIR2}/${name3}/${name3}_${DATE}.nc
        if [[ ! -e ${file3} ]] ||  ${overwrite}
        then
          echon "Create ${name3}"
          [[ -d ${OUTDIR2}/${name3} ]] || mkdir  ${OUTDIR2}/${name3} 
          cp ${file1} temp1_${YY}.nc
          #MED>>
          if [[ -e ${file2} ]]
          then
            ncks -h --no_abc -A -v ${name2} ${file2} temp1_${YY}.nc
          fi
          #MED<<
          ncap2 -h -O -s ${formula} temp1_${YY}.nc temp1_${YY}.nc 
          #MED>>ncks -h -a -O -v ${name3},lat,lon,rotated_pole temp1_${YY}.nc ${file3}
          ncks -h --no_abc -O -v ${name3},lat,lon,rotated_pole temp1_${YY}.nc ${file3}
          #MED<<
          ncatted -h -a long_name,${name3},d,, ${file3}
          ncatted -h -a standard_name,${name3},m,c,${standard_name} ${file3}
          chmod ${PERM} ${file3}
          rm temp1_${YY}.nc
        else
          echov "$(basename ${file3})  already exists. Use option -o to overwrite. Skipping..."
        fi
      else
        echo "Input Files for generating ${name3} are not available"
      fi
    fi
  }

  if [[ ${LFILE} -ne 1 ]] 
  then
    
    echon ""
    echon " Create additional fields for CORDEX"

    # Mean wind spdeed at 10m height: SP_10M
    create_add_vars "U_10M" "V_10M" "SP_10M" "add_sqr" "wind_speed"
    
    # Total downward global radiation at the surface: ASWD_S
    create_add_vars "ASWDIR_S" "ASWDIFD_S" "ASWD_S" "add" "averaged_downward_sw_radiation_sfc" 
    
    # upward solar radiation at TOA: ASOU_T
    create_add_vars "ASOD_T" "ASOB_T" "ASOU_T" "subs" "averaged_solar_upward_radiation_top" 
    
    # Total runoff: RUNOFF_T
    create_add_vars "RUNOFF_S" "RUNOFF_G" "RUNOFF_T" "add" "total_runoff_amount"
    
    # Total convective precipitation: PREC_CON
    create_add_vars "RAIN_CON" "SNOW_CON" "PREC_CON" "add" "convective_precipitation_amount"
    
    # Total snow: TOT_SNOW
    create_add_vars "SNOW_GSP" "SNOW_CON" "TOT_SNOW" "add" "total_snowfall_amount"
    
    # cloud condensed water content TQW
    create_add_vars "TQC" "TQI" "TQW" "add" "atmosphere_cloud_condensed_water_content"  

    #MED>>
    # Mean snow fraction: FR_SNOW
    create_add_vars "W_SNOW" "" "FR_SNOW" "snow_case" "surface_snow_area_fraction" 
    #MED<<
  fi
  
  (( YY=YY+1 ))
  DATE2=$(date +%s)
	SEC_TOTAL=$(python -c "print(${DATE2}-${DATE1})")
	echon "Time for postprocessing: ${SEC_TOTAL} s"
  done                                      # year loopend



  # Remove monthly subdirs YYYY_MM
  #YY=${YYA}
  #MM=${MMA}
  #while [[ ${YY}${MM} -le ${YYE}${MME} ]]      # year loop
  #do
  #  Remove the input files if you are shure that they are no longer needed:
  #  Files with monthly time series of single variables generated by subchain-script "post.job"
  #
  #  rm -rf ${YY}_${MM}
   # (( MM=MM+1 ))
    #if [[ ${MM} -gt 12 ]] 
    #then
    #  (( YY=YY+1 ))
     # MM=1
    #fi
  #done

