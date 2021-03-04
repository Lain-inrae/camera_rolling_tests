
Configure CAMERA
================

 * vi CAMERA/inst/unitTests/Makefile
 * Change the R path

Teh Data!
=========

Copy your rdata to process in data/ and rename it "original.rdata", case matters.  
Copy your mzml files into the "data" directory.  
Attention!  
It is possible that the CAMERA process crashes "the file blabla.mzml cant be found"  
In this case, just copy your data.  
For example, my datasets were named "/home/lain/Desktop/inrae/fixed_camera_process/data/70k_POS__X20201203_ImjXseeker_70K_blk_01.mzML"  
And CAMERA complained that "/home/lain/Desktop/inrae/fixed_camera_process/data/X20201203_ImjXseeker_70K_blk_01.mzML" can't be found.  
(notice the missing "70k_POS__" at the begining of the file)  
In this case:
 * **copy** your file, so you have "70k_POS__X20201203_ImjXseeker_70K_blk_01.mzML" **and** "X20201203_ImjXseeker_70K_blk_01.mzML" in your data directory ;
 * change the "begin_with" in the file "all.sh" to use a string that matches **only** the begining of the files that CAMERA missed.
   * For example, I wrote "begin_with X20201203" because all files missed by CAMERA began with "X20201203".  
   Other began with "70k_POS__", so these were excluded. That's what we want.

I don't know why it happens. I suppose galaxy modified the files names in the process, and it does weird things.

Teh Zorkflow
============

 * Change CAMERA / modify its code
 * Recompile CAMERA: ./recompile.sh  ~ 1min
 * run ./all.sh ~ 40min:
   * \~10 secs for the "recreate_full.r",
   * \~10 min for CAMERA annotateDiffreport,
   * \~10 secs again for recreate_full.r,
   * and then \~30min for XSeekerPreparator.R .

