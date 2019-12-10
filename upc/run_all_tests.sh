NR_PROCS=(4 8 16 24 32)
RUN_TYPE=("" "_th")

for proc in "${NR_PROCS[@]}"; do
    for run_type in "${RUN_TYPE[@]}"; do
        rt="run$run_type"
        rm -rf "${rt}_${proc}.er" 
        collect -o "${rt}_${proc}.er"  make $rt P_NUM=$proc
    done 
done

FIXED_PROC=16
rm -rf "run_fixed.er" 
collect -o "run_fixed.er" make run_fixed P_NUM=$FIXED_PROC
rm -rf "run_fixed_th.er" 
collect -o "run_fixed_th.er" make run_fixed_th P_NUM=$FIXED_PROC
