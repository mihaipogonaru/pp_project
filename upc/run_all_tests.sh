NR_PROCS=(4 8 10 16 20 24 32)
FIXED_PROCS=(10 16 20)
RUN_TYPE=("" "_th")
NET=("mpi" "smp")
extra_name=""

for net in "${NET[@]}"; do
make clean
make P_NUM=20 NET=$net # P_NUM doesn't matter

for proc in "${NR_PROCS[@]}"; do
    for run_type in "${RUN_TYPE[@]}"; do
        rt="run$run_type"
        rm -rf "${net}_${rt}_${proc}${extra_name}.er" 
        collect -o "${net}_${rt}_${proc}${extra_name}.er"  make $rt P_NUM=$proc
    done 
done

for proc in "${FIXED_PROCS[@]}"; do
    make clean
    make P_NUM=$proc NET=$net   

    rm -rf "${net}_run_fixed_${proc}${extra_name}.er" 
    collect -o "${net}_run_fixed_${proc}${extra_name}.er" make run_fixed P_NUM=$proc
    rm -rf "${net}_run_fixed_th_${proc}${extra_name}.er" 
    collect -o "${net}_run_fixed_th_${proc}${extra_name}.er" make run_fixed_th P_NUM=$proc
done
done
