#!/bin/bash

# GMXの node内の並列は一般的に高くないので、ここでは、OPENMPは使わない
jobscript=jobscript_GMX_template
GMX_input_array=(Ar128000_min Ar256000_min Ar32000_min Ar64000_min)
process_per_node=(1 4 8 24 48 96 160 192 )  

extension_GMX=(top gro)
# cpu_node_type=("cpu_4" "cpu_8" "cpu_16" "cpu_40" "cpu_80" "cpu_160")
gpu_node_type=("gpu_h" "gpu_1" "node_o" "node_q" "node_h" "node_f")

node_type=("${cpu_node_type[@]}" "${gpu_node_type[@]}")
number_nodes=(1 2)

# job_command=$(qsub -g tga-tateyama)

# temporary arguments
# AAAAAA -> ${node_type[@]}+${number_nodes[@]} : node_type, number_nodes
# BBBBBB -> C+${num_cores}+G+${num_gpu} : jobname
# CCCCCC -> ${GMX_input_array[@]} : GMX_input
# DDDDDD -> ${processes} : process_number
# EEEEEE -> $((num_cores * $num)) : total_process
# FFFFFF -> $num_gpu

# Create directories once before loop
mkdir -p gpu_performance_test
mkdir -p cpu_performance_test

for type_node in "${node_type[@]}"; do
    for num_node in "${number_nodes[@]}"; do
        # Initialize variables
        num_gpu=0
        num_cores=0

        # Set num_gpu and num_cores based on node_type
        case "$type_node" in

            "cpu_4")
                num_gpu=0
                num_cores=$((4 * num_node))
                ;;
            "cpu_8")
                num_gpu=0
                num_cores=$((8 * num_node))
                ;;
            "cpu_16")
                num_gpu=0
                num_cores=$((16 * num_node))
                ;;
            "cpu_40")
                num_gpu=0
                num_cores=$((40 * num_node))
                ;;
            "cpu_80")
                num_gpu=0
                num_cores=$((80 * num_node))
                ;;
            "cpu_160")
                num_gpu=0
                num_cores=$((160 * num_node))
                ;;
            "gpu_h")
                num_gpu=$(echo "1 * $num_node" | bc)
                num_cores=$((4 * num_node))
                ;;
            "gpu_1")
                num_gpu=$((1 * num_node))
                num_cores=$((8 * num_node))
                ;;
            "node_o")
                # num_gpu=$(echo "0.5 * $num_node" | bc)
                num_gpu=$(echo "1 * $num_node" | bc)
                num_cores=$((24 * num_node))
                ;;
            "node_q")
                num_gpu=$((1 * num_node))
                num_cores=$((48 * num_node))
                ;;
            "node_h")
                num_gpu=$((2 * num_node))
                num_cores=$((96 * num_node))
                ;;
            "node_f")
                num_gpu=$((4 * num_node))
                num_cores=$((192 * num_node))
                ;;
        esac

        # Ensure num_gpu is an integer
        num_gpu=$(echo "scale=0; $num_gpu / 1" | bc)
        
        # Only proceed if num_gpu > 0.5 (for GPU)
        if (( $(echo "$num_gpu > 0.5" | bc -l) )); then
            target_dir="gpu_performance_test"
        else
            target_dir="cpu_performance_test"
        fi

        # Create the output files in the appropriate directory
        cd "$target_dir"
        cp ../"$jobscript".sh ./
        for extension in "${extension_GMX[@]}"
	do
		cp ../*.${extension} ./
        done
	
        for GMX_input in "${GMX_input_array[@]}" 
        do
            for processes in "${process_per_node[@]}"
            do    
                # Perform the replacements using sed
                if [[ $num_cores -gt $((processes * num_node)) ]]; then
                    sed -e "s/AAAAAA/${type_node}=${num_node}/g" \
                        -e "s/BBBBBB/np${processes}cpu${num_cores}gpu${num_gpu}_${GMX_input}/g" \
                        -e "s/CCCCCC/${GMX_input}/g" \
                        -e "s/DDDDDD/${processes}/g" \
                        -e "s/EEEEEE/$((processes * num_node))/g" \
                        -e "s/FFFFFF/${num_gpu}/g" \
                        "$jobscript".sh > "GMXjob_${processes}np_${num_cores}cpu_${num_gpu}gpu_${GMX_input}.sh"
                fi
            done
        done

        cd ../
    done
done
