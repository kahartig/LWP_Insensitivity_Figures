#! /bin/tcsh -f

# csh script to create and evaluate the output which results from varying
# the settings involved with the creation of a SOM map
# (From Mark Seefeldt and Joel Finnis)
#
# 2014-05-29
# -modified to make the script easier to follow and edit
# -included the calculation and logging of a twisted index from Justin Glisan
# -set the radium limit to that of ny_node
# -established subdirectories for:  sam, ps, and cod files
# 2014-06-05
# -added a filename.log with the filename corresponding to each trial
# -added the NCL program: eval_som_trials.ncl to create a ranked list of trials

# Number of nodes:
set nx_node = 4
set ny_node = 3

# Set the variable to be processed
set var = 'psl_anom'

# Initial input data
set input_data = '/data/khartig/alaskan_som/input_data/ERA5_AlaskaNSA-large_psl_anom_500m_Nov-Mar_2000-2024.txt'

# create the linit file (only needs to be created once)
set create_init = 1

# Set the NCL directory
set ncl_dir = '/home/seefeldm/ncl'

# Include labels in the logs (1 = yes, 0 = no)
set labels = 0

# Rank the trials after creating all of the SOMs
set rank_trials = 1

######################################################################
# all of the lines below do not need to be edited
######################################################################

# Name of map initialization
set init_data = {$var}-{$nx_node}x{$ny_node}.ini

# Directory to store files:
#set sub_dir = {$nx_node}'x'{$ny_node}
set sub_dir = './'

# set the arrays for the variables to be used with vsom
set alpha = ('0.005' '0.01' '0.02' '0.03' '0.04' '0.05')
set am_b = 1
set am_e = 6
set am_rng = `expr $am_e - $am_b + 1`
set rlen = ('10000' '50000' '100000' '250000' '500000' '1000000')
set lm_b = 1
set lm_e = 6
set lm_rng = `expr $lm_e - $lm_b + 1`
set radius = ('1' '2' '3' '4' '5' '6' '7' '8' '9' '10' '11' '12')
set rm_b = 1
set rm_e = $ny_node
#set rm_e = `expr $ny_node - 1`
set rm_rng = `expr $rm_e - $rm_b + 1`

# If filename.log, qerror.log, and/or twist.log exists, remove
if -f filename.log then
  rm filename.log
endif
if -f qerror.log then
  rm qerror.log
endif
if -f twist.log then
  rm twist.log
endif

# create the sub_dir, cod, ps, and sam directories, if not already present
if ! -d ${sub_dir} then
  mkdir ${sub_dir}
endif
if ! -d ${sub_dir}/cod then
  mkdir ${sub_dir}/cod
endif
if ! -d ${sub_dir}/ps then
  mkdir ${sub_dir}/ps
endif
if ! -d ${sub_dir}/sam then
  mkdir ${sub_dir}/sam
endif

#set echo on

# Perform the linear initialization
if ($create_init == 1) then
  echo 'linit'
  echo ' file input: '$input_data
  echo ' file linit: '$init_data
  lininit -xdim $nx_node -ydim $ny_node -din $input_data -cout $init_data  \
          -neigh bubble -topol hexa
  echo ''
endif

# initialize the filename.log with header information
echo 'var_dims: '$am_rng' '$lm_rng' '$rm_rng > filename.log
echo 'alpha: '${alpha[$am_b-$am_e]} >> filename.log
echo 'rlen: '${rlen[$lm_b-$lm_e]} >> filename.log
echo 'radius: '${radius[$rm_b-$rm_e]} >> filename.log
echo 'nx_ny: '$nx_node' '$ny_node >> filename.log
echo 'variable: '$var >> filename.log
echo '' >> filename.log

# Loop through the alpha values
set a = $am_b
while ($a <= $am_e)

  # Loop through the rlen values
  set l = $lm_b
  while ($l <= $lm_e)

    # Loop through the radius values
    set r = $rm_b
    while ($r <= $rm_e)

      # Set the value for the file_root
      set file_root = {$var}-a${alpha[$a]}_rlen${rlen[$l]}_r${radius[$r]}

      # Output the file_root to filename.tmp2
      echo $file_root >> filename.tmp2

      # Output header information to terminal
      echo $file_root
      echo alpha =  ${alpha[$a]}
      echo rlen = ${rlen[$l]}
      echo radius = ${radius[$r]}

      # Run the training program
      vsom -din $input_data -cin $init_data  \
           -cout ${sub_dir}/cod/${file_root}.cod        \
           -alpha ${alpha[$a]} -rlen ${rlen[$l]} -radius ${radius[$r]}    \

      # Determine the qerror
      qerror -din $input_data  \
             -cin ${sub_dir}/cod/${file_root}.cod > qerror.tmp

      # Take the 9th column of the qerror output (qerror value)
      awk < qerror.tmp '{ print $9}' >> qerror.tmp2

      # Create the sammon map
      sammon -cin ${sub_dir}/cod/${file_root}.cod   \
             -cout ${sub_dir}/sam/${file_root}.sam -rlen 10000 -ps 1

      # Move the postscript file to the ps directory
      mv ${sub_dir}/sam/${file_root}_sa.ps ${sub_dir}/ps/.

    # Continue through the loops

    @ r ++
    end

    # add a blank line to qerror every time n is incremented (rlen changes)
    echo '' >> filename.tmp2
    echo '' >> qerror.tmp2

    # add lables to the log files, if selected
    if ( $labels == 1 ) then
      echo a=$alpha[$a], l=$rlen[$l] >> filename.log
      echo a=$alpha[$a], l=$rlen[$l] >> qerror.log
    endif

    # Paste entries surrounded by blank lines to a single line
    awk '{if(NF)x=x" "$0;else{print substr(x,2);x=""}}' filename.tmp2 >>filename.log
    awk '{if(NF)x=x" "$0;else{print substr(x,2);x=""}}' qerror.tmp2 >>qerror.log

    # Erase temporary file
    rm filename.tmp2
    rm qerror.tmp2

  @ l ++
  end
  echo '' >> filename.log
  echo '' >> qerror.log

@ a ++
end

#--- Destroy the evidence ---#
rm qerror.tmp

# run the NCL program to rank the trials and create annotated sammon maps
if ($rank_trials == 1) then
  # create the rank directory, if not present
  if ! -d ${sub_dir}/rank then
    mkdir ${sub_dir}/rank
  endif
  # run the NCL program:  eval_som_trials.ncl
  ncl 'path_som="'${sub_dir}/'"' ${ncl_dir}/eval_som_trials.ncl
  #ncl 'path_som="'./'"' ${ncl_dir}/eval_som_trials.ncl

endif
