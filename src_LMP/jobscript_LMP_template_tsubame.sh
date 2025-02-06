#!/bin/bash
#$ -cwd
#$ -l AAAAAA
#$ -l h_rt=01:00:00
#$ -N LMPBBBBBB


DirectoryName=BBBBBB
input_file=CCCCCC
data_file=NaN


process_number=DDDDDD
total_process=EEEEEE
gpu_number=FFFFFF
##################################
export LD_LIBRARY_PATH=@@@@/LAMMMPS_29Aug2024_cuda/build_v2:$LD_LIBRARY_PATH
. /etc/profile.d/modules.sh
conda deactivate
module purge
module load  cuda/12.3.2  openmpi/5.0.2-gcc fftw/3.3.10-gcc  nvhpc/24.1  intel 
GPU_ARCH=sm_90

LMP_path=@@@@@@@/0.MD/LAMMMPS_29Aug2024_cuda/build_v2
LMP_bin_type=lmp_mpi_cuda




MeasureStartingTime(){

res1=$(date +%s.%N)

}

CopyInputFile(){

cp ../${input_file}.in ./

}


CopyDataFile() {
  if [[ -z "$data_file" || "$data_file" == "Nan" ]]; then
    echo "data_file is empty or Nan. Skipping copy."
    return
  fi

  cp ../${data_file} ./
}


MeasureEndingTime(){

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)
LC_NUMERIC=C printf "Total runtime: %d:%02d:%02d:%02.4f\n" $dd $dh $dm $ds

}

RunASingleJob(){

 echo $DirectoryName
 mkdir $DirectoryName
 cd $DirectoryName
 
 CopyInputFile
 CopyDataFile
 
 MeasureStartingTime
 mpirun -x PATH -x LD_LIBRARY_PATH -x PYTHONPATH \
	 -npernode ${process_number}  -np ${total_process} \
	 ${LMP_path}/${LMP_bin_type} \
	 -sf gpu -pk gpu ${gpu_number} -in ${input_file}.in \
	 -log ${input_file}.log  2>&1
 MeasureEndingTime
 cd ..

}

RunASingleJob


