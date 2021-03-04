
/home/lain/R/bin/Rscript \
  /home/lain/Desktop/inrae/fixed_camera_process/camera_annotate/CAMERA_annotateDiffreport.r \
  image /home/lain/Desktop/inrae/fixed_camera_process/data/test.rdata \
  singlefile_galaxyPath \
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_blk_01.mzML,\
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_blk_05.mzML,\
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_mixACs_04.mzML,\
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_QCmacroDijon_03.mzML,\
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_QCmacroICM_02.mzML \
  singlefile_sampleName \
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_blk_01,\
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_blk_05,\
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_mixACs_04,\
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_QCmacroDijon_03,\
    /home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_QCmacroICM_02 \
  convertRTMinute FALSE \
  numDigitsMZ 4 \
  numDigitsRT 0 \
  intval into \
  ppm 3 \
  mzabs 0.0005 \
  maxcharge 1 \
  maxiso 8 \
  minfrac 0.5 \
  sigma 6 \
  perfwhm 0.6 \
  quick FALSE \
  cor_eic_th 0.75 \
  graphMethod hcs \
  pval 0.05 \
  calcCiS TRUE \
  calcIso TRUE \
  calcCaS FALSE \
  polarity negative \
  max_peaks 100 \
  multiplier 3 \
  nSlaves 4
