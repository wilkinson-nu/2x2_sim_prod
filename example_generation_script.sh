#!/bin/bash

## Make a logfile for all of the shouty outputs...
LOG=example_generation_script.log
date > ${LOG}

## This tells GENIE where to find inputs it needs to define the configuration
GXMLPATH=${PWD}/inputs

## The GENIE "tune" to use (if changed, a new spline file is needed)
TUNE=G18_10a_02_11a
SPLINE_FILE=${TUNE}_FNALsmall.xml

## The file is too large for github, so pull it from NERSC (but only if it doesn't already exist)
if [ ! -f "inputs/$SPLINE_FILE" ]; then
    echo "Pulling ${SPLINE_FILE} from NERSC!"
    wget https://portal.nersc.gov/project/dune/data/2x2/inputs/${TUNE}_FNALsmall.xml
    mv ${TUNE}_FNALsmall.xml inputs/.
fi

## The geometry to simulate with
GEOM=inputs/Merged2x2MINERvA_noRock.gdml

## The DK2NU file describes the neutrino flux, other options are possible, see the GENIE docs
## This is just an example file, for simulating a large number of events, more files should be used to adequately explore the space
DK2NUFILE=inputs/g4numiv6_minervame_me000z200i_0_0001.dk2nu

## The file is also too large for github, so pull it from NERSC (but only if it doesn't already exist)
if [ ! -f "$DK2NUFILE" ]; then
    echo "Pulling ${DK2NUFILE} from NERSC!"
    wget https://portal.nersc.gov/project/dune/data/2x2/inputs/g4numiv6_minervame_me000z200i_0_0001.dk2nu
    mv g4numiv6_minervame_me000z200i_0_0001.dk2nu inputs/.
fi

## This is defined in "GNuMIFlux.xml", and GENIE finds it with the GXMLPATH
## It tells GENIE where the geometry is in relation to the flxu simulation, and defines an area of interest
DET=ProtoDUNE-ND

## The POT to generate in this file
EXP=1E15

## This is just used to set names below
OUTFILEPREFIX=example_2x2MINERvA_${EXP}

## The precalculated path of maximum integrated density for this geometry 
## Note that if the geometry file changes, this must also be recalculated
MAXPATH_FILE=${GEOM/.gdml/_maxpath.xml}

## Recalculate if it doesn't exist
if [ ! -f "${GEOM/.gdml/_maxpath.xml}" ]; then

    ## These determine how many points to test around the geometry, and how many test vectors to try at each
    NPOINTS=10000
    NRAYS=1000

    echo "Generating the GENIE max path file..."
    gmxpl -f ${GEOM} \
	  -L cm -D g_cm3 \
	  -o ${GEOM/.gdml/_maxpath.xml} \
	  -n ${NPOINTS} \
	  -r ${NRAYS} \
	  --seed 0 &>> $LOG
fi

## Actually run GENIE
echo "Running GENIE event generation..."
gevgen_fnal \
    -e ${EXP} \
    -f ${DK2NUFILE},${DET} \
    -g ${GEOM} \
    -m ${MAXPATH_FILE} \
    -L cm -D g_cm3 \
    --cross-sections ${TUNE}_FNALsmall.xml \
    --tune ${TUNE} \
    --seed 0 &>> $LOG

## Make the filename more meaningful
mv gntp.0.ghep.root ${OUTFILEPREFIX}_GHEP.root

## Convert to rootracker format (edep-sim's expected input)
echo "Converting GENIE output to RooTracker format..."
gntpc -i ${OUTFILEPREFIX}_GHEP.root -f rootracker -o ${OUTFILEPREFIX}_ROO.root &>> $LOG

## Now cherrypick events which have vertices in the 2x2 active volume
## This is entirely optional, but the POT should be reduced by a factor of 10 if it is skipped
echo "Running cherrypicker.py..."
python3 inputs/cherrypicker.py -i  ${OUTFILEPREFIX}_ROO.root -o ${OUTFILEPREFIX}_ROO_CHERRY.root

## Get the number of events for edepsim (I know, I know...)
NEVENTS=$(echo "TTree* tree = (TTree*)_file0->Get(\"gRooTracker\"); std::cout << tree->GetEntries() << std::endl;" | \
	      root -l -b ${OUTFILEPREFIX}_ROO_CHERRY.root | tail -1)

## The mac file defines the behaviour of edep-sim and G4
cp inputs/2x2_beam.mac this_edep_example.mac
sed -i "s/__GENIE_FILE__/${OUTFILEPREFIX}_ROO_CHERRY.root/g" this_edep_example.mac

## Run edep-sim
echo "Running edep-sim on ${NEVENTS} events..."
edep-sim -C -g ${GEOM} \
	 -o ${OUTFILEPREFIX}_EDEPSIM.root \
	 this_edep_example.mac \
	 -e ${NEVENTS} &>> $LOG

## Clean up this temporary file
rm this_edep_example.mac
echo "Finished!"
