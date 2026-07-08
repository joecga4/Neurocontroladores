#!/bin/bash
cd /home/joecga4/Documents/MATLAB/Neurocontroladores
MAT=/home/joecga4/.local/bin/matlab
for N in 1 2 3; do
  echo "==================== ETAPA $N : inicio $(date +%T) ===================="
  $MAT -batch "carro_e${N}" 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then echo "ETAPA $N FALLO (rc=$rc) — abortando currículo"; exit $rc; fi
  cp redcarro11.mat redcarro11_etapa${N}.mat
  echo "==================== ETAPA $N : fin $(date +%T)  (snapshot redcarro11_etapa${N}.mat) ===================="
done
echo "CURRICULO COMPLETO $(date +%T)"
rm -f carro_e1.m carro_e2.m carro_e3.m
