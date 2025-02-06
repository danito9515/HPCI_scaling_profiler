#!/bin/bash

# Tsubame specific-------------
module load cuda/12.3.2 intel-mpi/2021.11  intel/2024.0.2
module load openmpi/5.0.2-gcc fftw/3.3.10-gcc
GMX_PATH="@@@@@@@@/gmx_serial"
# Tsubame specific-------------

# --- Function Definitions ---

Create_UnitCell(){
cat > conf.gro << EOF
Ar FCC unit cell
    4
    1Ar    Ar    1   0.000   0.000   0.000
    2Ar    Ar    1   0.750   0.750   0.000
    3Ar    Ar    1   0.750   0.000   0.750
    4Ar    Ar    1   0.000   0.750   0.750
  1.50000 1.50000 1.50000
EOF
}

Create_FF(){
cat > ff_lj_ar.itp << EOF
[ defaults ]
; nbfunc comb-rule gen-pairs fudgeLJ fudgeQQ
1 1 yes 0.5 0.5

[ atomtypes ]
; name   mass     charge  ptype   sigma(nm)   epsilon(kJ/mol)
Ar       39.948   0.000   A       0.34        0.997

[ moleculetype ]
; Name    nrexcl
Ar        1

[ atoms ]
; id    type    resnr   residu    atom    cgnr    charge    mass
1       Ar      1       Ar        Ar      1       0.0       39.948
EOF
}

Create_Topology(){
  local num="$1"
  cat > topol.top <<EOF

[ system ]
Lennard-Jones Fluid

[ molecules ]
Ar ${num}
EOF
}

Create_Calinput(){
cat > minim.mdp << EOF
integrator  = steep
emtol       = 0.001 ;100.0
emstep      = 0.01
nsteps      = 5000

nstlist     = 10
cutoff-scheme = Verlet
ns_type     = grid
rlist       = 1.0
vdwtype     = cut-off
rvdw        = 1.0
pbc         = xyz
EOF
}

# --- Main Script ---

# 1. Generate initial files (conf.gro, force field, mdp)
Create_UnitCell
Create_FF
Create_Calinput

# 2. Generate coordinate files using genconf
${GMX_PATH} genconf -f conf.gro -nbox 20 20 20 -o Ar32000.gro
${GMX_PATH} genconf -f conf.gro -nbox 40 20 20 -o Ar64000.gro
${GMX_PATH} genconf -f conf.gro -nbox 40 40 20 -o Ar128000.gro
${GMX_PATH} genconf -f conf.gro -nbox 40 40 40 -o Ar256000.gro

# 3. For each generated .gro file, create topology and run simulation
for file in Ar*.gro; do
   # sedで2行目（原子数）を抽出
   ATOM_num=$(sed -n '2p' "$file")
   # トポロジーファイルの作成。引数 ${ATOM_num} により [ molecules ] セクションに反映される。
   Create_Topology "${ATOM_num}"
   # トポロジーファイル名を変更（例：Ar32000.top, Ar64000.top, ...）
   #mv topol.top "./${file%.gro}_min.top"
   cat ff_lj_ar.itp topol.top > "./${file%.gro}_min.top"
   # tprファイルの作成
   ${GMX_PATH} grompp -f minim.mdp -c "$file" -p "./${file%.gro}_min.top" -o "./${file%.gro}_min.tpr"
   # MD計算の実行
   ${GMX_PATH} mdrun -v -deffnm "${file%.gro}_min"
done

