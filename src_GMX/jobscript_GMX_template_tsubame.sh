#!/bin/sh
#$ -cwd
#$ -l AAAAAA
#$ -l h_rt=00:10:00
#$ -N BBBBBB


module load cuda/12.3.2 intel-mpi/2021.11  intel/2024.0.2
module load openmpi/5.0.2-gcc fftw/3.3.10-gcc
PREFIX=BBBBBB

FILE_TOP="CCCCCC.top"       # トポロジーファイル
FILE_ORI="CCCCCC.gro" 
JOBNAME=${PREFIX}_gmx_tmp
DO_EXTEND=no
THREADS=1
pwd

set -v
set +v
echo "*************************************************"
echo "***               GROMACS START               ***"
echo "*************************************************"
set -v
set +v
echo "*************************************************"
echo "***             define variables              ***"
echo "*************************************************"
set -v
### 変数定義
BINGMXSERI="@@@@@@/gromacs_2024.4_cuda/build_serial/bin/gmx_serial"           # GROMACSシリアルバイナリ
BINGMXMPI="@@@@@@@/gromacs_2024.4_cuda/build_cuda/bin/gmx_mpi_cuda"            # GROMACS MPIバイナリ
MPICOMM="mpirun -np EEEEEE "
DO_MPI=no
UNZIP_WORKDIR=no
DO_BACKUP=yes
DO_CONCAT=no
DO_RESCALEVEL=no
DO_RESCALEBOX=no
DO_PULL=no
DO_NOJUMP=yes
DO_GENVEL=no
NSTEPS=1000
TEMPRESCALE=300
OPT_GROMPP=" -maxwarn 10"
OPT_MDRUN=" -v"
OPT_MDRUNPULL=""
set +v
MDPSTR=$(cat <<EOF
integrator    = md
dt            = 0.002
nsteps        = 1000
nstxout       = 1000
nstvout       = 1000
nstenergy     = 100
nstlog        = 100
continuation  = no

cutoff-scheme = Verlet
nstlist       = 10
ns_type       = grid
rlist         = 1.0
vdwtype       = cut-off
rvdw          = 1.0

tcoupl        = V-rescale
tc-grps       = System
tau_t         = 0.1
ref_t         = 300.0

pbc           = xyz

gen_vel = yes
gen_temp = 300.0
gen_seed = 12345
EOF
)
NDXPULL=""
set -v
set +v
echo "*************************************************"
echo "***             check environment             ***"
echo "*************************************************"
set -v
which ${BINGMXSERI}
RES=$?
set +v
if [ $RES -ne 0 ]; then
  echo "Error : ${BINGMXSERI} was not found. Install and set PATH."
  sleep 5
  exit 1
fi
set -v
if [ ${UNZIP_WORKDIR} = "yes" ]; then
  set +v
  if [ ! -f ${JOBNAME}.zip ]; then
    echo "Error : zip file was not found."
    sleep 5
    exit 1
  fi
  set -v
fi
set +v
echo "*************************************************"
echo "***    make a backup of working directory     ***"
echo "*************************************************"
set -v
if [ ${DO_BACKUP} = "yes" ]; then
  dir=${JOBNAME}
  if [ -d $dir ]; then
    for i in `seq 1 1000`; do
      if [ ! -d $dir$i ]; then
        set -v
        cp -r $dir $dir$i;
        set +v
        break
      fi
    done
  fi
fi
set +v
echo "*************************************************"
echo "***               prepare files               ***"
echo "*************************************************"
set -v
mkdir -p ${JOBNAME}
if [ ${DO_EXTEND} = "no" ]; then
  cp ${FILE_TOP} ${JOBNAME}/gmx_tmp.top
  cp ${FILE_ORI} ${JOBNAME}/gmx_tmp_mdrun.gro
  cp ${FILE_ORI} ${JOBNAME}/input.gro
fi
set +v
if [ ! -d ${JOBNAME} ]; then
  echo "Error : Failed to enter the working folder"
  sleep 5
  exit 1
fi
set -v
cd ${JOBNAME}
if [ ${UNZIP_WORKDIR} = "yes" ]; then
  unzip -o ../$JOBNAME || exit 1
fi
if [ ${DO_CONCAT} = "yes" ]; then
  cp gmx_tmp_mdrun.trr gmx_tmp_mdrun_last.trr
  cp gmx_tmp_mdrun.edr gmx_tmp_mdrun_last.edr
fi
set +v
echo "*************************************************"
echo "***               make mdp file               ***"
echo "*************************************************"
set -v
echo "$MDPSTR" | tee gmx_tmp.mdp
set +v
echo "*************************************************"
echo "***              make index file              ***"
echo "*************************************************"
set -v
if [ -f gmx_tmp_mdrun.gro ]; then
  echo q | ${BINGMXSERI} make_ndx -f gmx_tmp_mdrun.gro -o gmx_tmp_mdrun.ndx
  RES=$?
  set +v
  if [ $RES -ne 0 ]; then
    echo "Error : Failed to make ndx file."
    sleep 5
    exit 1
  fi
  set -v
  echo 
fi
if [ ${DO_PULL} = "yes" ]; then
  echo "$NDXPULL" | tee -a gmx_tmp_mdrun.ndx
fi
set +v
echo "*************************************************"
echo "***               make tpr file               ***"
echo "*************************************************"
set -v
rm -f gmx_tmp_mdrun.tpr
${BINGMXSERI} grompp -f gmx_tmp.mdp -c gmx_tmp_mdrun.gro -p gmx_tmp.top -o gmx_tmp_mdrun.tpr  -n gmx_tmp_mdrun.ndx ${OPT_GROMPP}
RES=$?
set +v
if [ $RES -ne 0 -o ! -f gmx_tmp_mdrun.tpr ]; then
  echo "Error : Failed to make the TPR file with grompp."
  sleep 5
  exit 1
fi
set -v
# if [ ${DO_GENVEL} = "no" -a ${DO_RESCALEBOX} = "no" -a ${DO_RESCALEVEL} = "no" -a ${DO_PULL} = "no" ]; then
#   cp -f gmx_tmp_mdrun.tpr gmx_tmp_mdrun_novel.tpr
#   ${BINGMXSERI} convert-tpr -s gmx_tmp_mdrun_novel.tpr -f gmx_tmp_mdrun.trr -e gmx_tmp_mdrun.edr -o gmx_tmp_mdrun.tpr -nsteps ${NSTEPS}
# fi
set +v
echo "*************************************************"
echo "***                run Gromacs                ***"
echo "*************************************************"
set -v
${MPICOMM} ${BINGMXMPI} mdrun -deffnm  gmx_tmp_mdrun -ntomp ${THREADS} ${OPT_MDRUN} ${OPT_MDRUNPULL}
RES=$?
set +v
if [ $RES -ne 0 ]; then
  echo "Error : Failed to run Gromacs with mdrun"
  sleep 5
  exit 1
fi
set -v
unix2dos gmx_tmp_mdrun.log
set +v
echo "*************************************************"
echo "***            convert gro to pdb             ***"
echo "*************************************************"
set -v
for GROFILE in gmx_tmp_*.gro
do
  PDBFILE=${GROFILE%gro}pdb
  echo "${BINGMXSERI} editconf -f $GROFILE -o $PDBFILE"
  ${BINGMXSERI} editconf -f $GROFILE -o $PDBFILE
  echo 
  if [ ! -f $PDBFILE ]; then
    echo "Error : Failed to convert GRO to PDB."
    sleep 5
    exit 12
  else
    awk '{
     atom = substr($0,1,6);
     res  = substr($0,18,3);
     if(atom=="ATOM  "){
      if(res=="MOL"||res=="UNK"||res=="SOL"||res==" NA"||res==" CL"){
       sub("ATOM  ","HETATM",$0);
      }
      if(res=="SOL"){
       sub("HW1","H1 ",$0);
       sub("HW2","H2 ",$0);
       sub("OW ","O  ",$0);
      }
     }
     print $0;
    }' $PDBFILE > $PDBFILE.temp
    mv $PDBFILE.temp $PDBFILE
  fi
done
set +v
echo "*************************************************"
echo "***          concatenate gro and edr          ***"
echo "*************************************************"
set -v
if [ ${DO_EXTEND} = "yes" -a ${DO_CONCAT} = "yes" ] ; then
  mv gmx_tmp_mdrun.trr gmx_tmp_mdrun_new.trr
  echo -e "c\nc" | ${BINGMXSERI} trjcat  -settime -f gmx_tmp_mdrun_last.trr gmx_tmp_mdrun_new.trr -o gmx_tmp_mdrun.trr
  RES=$?
  set +v
  if [ $RES -ne 0 -o ! -f gmx_tmp_mdrun.trr ]; then
    echo "Error : trjcat failed."
    sleep 5
    exit 1
  fi
  set -v
  mv gmx_tmp_mdrun.edr gmx_tmp_mdrun_new.edr
  echo -e "c\nc" | ${BINGMXSERI} eneconv -settime -f gmx_tmp_mdrun_last.edr gmx_tmp_mdrun_new.edr -o gmx_tmp_mdrun.edr
  RES=$?
  set +v
  if [ $RES -ne 0 -o ! -f gmx_tmp_mdrun.edr ]; then
    echo "Error : eneconv failed."
    sleep 5
    exit 1
  fi
  set -v
fi
if [ ${DO_NOJUMP} = "yes" ]; then
set +v
echo "*************************************************"
echo "***        edit trajectory/coordinate         ***"
echo "*************************************************"
set -v
  mv gmx_tmp_mdrun.trr gmx_tmp_mdrun_tmp.trr
  echo 0 | ${BINGMXSERI} trjconv -pbc mol -s gmx_tmp_mdrun.tpr -f gmx_tmp_mdrun_tmp.trr -o gmx_tmp_mdrun.trr
  RES=$?
  set +v
  if [ $RES -ne 0 -o ! -f gmx_tmp_mdrun.trr ]; then
    echo "Error : trjconv failed."
    sleep 5
    exit 1
  fi
  set -v
  rm -f gmx_tmp_mdrun_tmp.trr
  mv gmx_tmp_mdrun.gro gmx_tmp_mdrun_tmp.gro
  ${BINGMXSERI} check -f gmx_tmp_mdrun.trr 2>&1 | tee check.log
  first_t=`perl -lne 'print $1 if /Reading frame +0 time +([^ ]+)/' check.log`
  echo "First time: " $first_t
  len_t=`grep '^Step' check.log | awk '{print ($2-1)*$3}'`
  echo "(Last time) - (First time): " $len_t
  last_t=`echo "$first_t + $len_t" | bc -l`
  echo "Last time: " $last_t
  echo 0 | ${BINGMXSERI} trjconv -dump $last_t -s gmx_tmp_mdrun.tpr -f gmx_tmp_mdrun.trr -o gmx_tmp_mdrun.gro
  RES=$?
  set +v
  if [ $RES -ne 0 -o ! -f gmx_tmp_mdrun.gro ]; then
    echo "Error : trjconv failed."
    sleep 5
    exit 1
  fi
  set -v
  rm -f gmx_tmp_mdrun_tmp.gro
fi
if [ ${DO_RESCALEVEL} = "yes" ]; then
set +v
echo "*************************************************"
echo "***            rescale velocities             ***"
echo "*************************************************"
set -v
  echo 0 | ${BINGMXSERI} energy -f gmx_tmp_mdrun.edr 2> g_energy.out 
  if [ `grep Temperature g_energy.out | wc -l | awk "{print \$1}"` -eq 1 ]; then
    IDXTEMP=`grep Temperature g_energy.out | sed -e "s/^.* \\([0-9]\\+\\) \\+Temperature.*\$/\\1/g"`
    TEMP1=`echo ${IDXTEMP} | ${BINGMXSERI} energy -f gmx_tmp_mdrun.edr 2>&1 | grep Temperature | tail -n 1 | awk "{printf(\\"%f\\",\\$2)}"`
    TEMP0=${TEMPRESCALE}
    TFACTOR=`echo "sqrt(${TEMP0}/${TEMP1})" | bc -l`
    set +v
    echo "Target temperature:" $TEMP1
    echo "Temperature at the final step of the last run:" $TEMP0
    echo "Scaling factor for velocity:" $TFACTOR
    set -v
    head -n -1 gmx_tmp_mdrun.gro | sed -n -e "3,\$p" | cut -c45- | awk "{printf(\"%8.4f%8.4f%8.4f\\n\",\$1*${TFACTOR},\$2*${TFACTOR},\$3*${TFACTOR});}" > gmx_tmp_mdrun_vr_vel.d
    head -n -1 gmx_tmp_mdrun.gro | sed -n -e "3,\$p" | cut -c1-44 > gmx_tmp_mdrun_vr_pos.d
    head -n 2 gmx_tmp_mdrun.gro > gmx_tmp_mdrun_vr.gro
    paste --delimiters="" gmx_tmp_mdrun_vr_pos.d gmx_tmp_mdrun_vr_vel.d >> gmx_tmp_mdrun_vr.gro
    tail -n 1 gmx_tmp_mdrun.gro >> gmx_tmp_mdrun_vr.gro
    mv gmx_tmp_mdrun.gro gmx_tmp_mdrun.gro.bak
    mv gmx_tmp_mdrun_vr.gro gmx_tmp_mdrun.gro
  fi
fi
if [ ${DO_RESCALEBOX} = "yes" ]; then
set +v
echo "*************************************************"
echo "***             rescale box size              ***"
echo "*************************************************"
set -v
  echo 0 | ${BINGMXSERI} energy -f gmx_tmp_mdrun.edr 2> g_energy.out 
  if [ `grep Box-X g_energy.out | wc -l | awk "{print \$1}"` -eq 1 ]; then
    LX1=`echo -e "Box-X\n0" | ${BINGMXSERI} energy -f gmx_tmp_mdrun.edr 2>&1 | grep Box-X | tail -n 1 | awk "{printf(\\"%f\\",\\$2)}"`
    LX0=`tail -n 1 gmx_tmp_mdrun.gro | awk "{print \\$1}"`
    XFACTOR=`echo "${LX1}/${LX0}-1" | bc -l`
    LY1=`echo -e "Box-Y\n0" | ${BINGMXSERI} energy -f gmx_tmp_mdrun.edr 2>&1 | grep Box-Y | tail -n 1 | awk "{printf(\\"%f\\",\\$2)}"`
    LY0=`tail -n 1 gmx_tmp_mdrun.gro | awk "{print \\$2}"`
    YFACTOR=`echo "${LY1}/${LY0}-1" | bc -l`
    LZ1=`echo -e "Box-Z\n0" | ${BINGMXSERI} energy -f gmx_tmp_mdrun.edr 2>&1 | grep Box-Z | tail -n 1 | awk "{printf(\\"%f\\",\\$2)}"`
    LZ0=`tail -n 1 gmx_tmp_mdrun.gro | awk "{print \\$3}"`
    ZFACTOR=`echo "${LZ1}/${LZ0}-1" | bc -l`
    set +v
    echo "Target Lx:" $LX1
    echo "Lx at the final step of the last run:" $LX0
    echo "Scaling factor for x:" $XFACTOR
    echo "Target Ly:" $LY1
    echo "Ly at the final step of the last run:" $LY0
    echo "Scaling factor for y:" $YFACTOR
    echo "Target Lz:" $LZ1
    echo "Lz at the final step of the last run:" $LZ0
    echo "Scaling factor for z:" $ZFACTOR
    set -v
    head -n -1 gmx_tmp_mdrun.gro | sed -n -e "3,\$p" | cut -c1-44 | awk "BEGIN{RESOLD=-1;}{RESID=substr(\$0,1,5);x0=substr(\$0,21,8)+0;y0=substr(\$0,29,8)+0;z0=substr(\$0,37,8)+0;if(RESID!=RESOLD){x=x0; while(x>=${LX0}) x-=${LX0};  while(x<0) x+=${LX0}; dx=x*${XFACTOR};y=y0; while(y>=${LY0}) y-=${LY0};  while(y<0) y+=${LY0}; dy=y*${YFACTOR};z=z0; while(z>=${LZ0}) z-=${LZ0};  while(z<0) z+=${LZ0}; dz=z*${ZFACTOR};};RESOLD=RESID;printf(\"%8.3f%8.3f%8.3f\\n\",x0+dx,y0+dy,z0+dz);}" > gmx_tmp_mdrun_br_right.d
    head -n -1 gmx_tmp_mdrun.gro | sed -n -e "3,\$p" | cut -c1-20 > gmx_tmp_mdrun_br_left.d
    head -n 2 gmx_tmp_mdrun.gro > gmx_tmp_mdrun_br.gro
    paste --delimiters="" gmx_tmp_mdrun_br_left.d gmx_tmp_mdrun_br_right.d >> gmx_tmp_mdrun_br.gro
    echo $LX1 $LX1 $LX1 | awk "{printf(\"%10.5f%10.5f%10.5f\",\$1,\$2,\$3);}" >> gmx_tmp_mdrun_br.gro
    mv gmx_tmp_mdrun.gro gmx_tmp_mdrun.gro.bak
    mv gmx_tmp_mdrun_br.gro gmx_tmp_mdrun.gro
  fi
fi
cd ..
set +v
echo "*************************************************"
echo "***                GROMACS END                ***"
echo "*************************************************"
set -v
exit 0
