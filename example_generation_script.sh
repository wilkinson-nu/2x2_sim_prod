#!/bin/bash

## This tells GENIE where to find inputs it needs to define the configuration
GXMLPATH=${PWD}/inputs

## The GENIE "tune" to use (if changed, a new spline file is needed)
TUNE=G18_10a_02_11a
SPLINE_FILE=${TUNE}_FNALsmall.xml

## The geometry to simulate with
GEOM=inputs/Merged2x2MINERvA_noRock.gdml

## The DK2NU file describes the neutrino flux, other options are possible, see the GENIE docs
## This is just an example file, for simulating a large number of events, more files should be used to adequately explore the space
DK2NUFILE=inputs/g4numiv6_minervame_me000z200i_0_0001.dk2nu

## This is defined in "GNuMIFlux.xml", and GENIE finds it with the GXMLPATH
## It tells GENIE where the geometry is in relation to the flxu simulation, and defines an area of interest
EXP=ProtoDUNE-ND

## This is just used to set names below
OUTFILEPREFIX=example_2x2MINERvA

## The precalculated path of maximum integrated density for this geometry 
## Note that if the geometry file changes, this must also be recalculated
MAXPATH_FILE=${GEOM_FILE/.gdml/_maxpath.xml}

## Recalculate if it doesn't exist
if [ ! -f "${GEOM_FILE/.gdml/_maxpath.xml}" ]; then

    ## These determine how many points to test around the geometry, and how many test vectors to try at each
    NPOINTS=10000
    NRAYS=1000
    
    gmxpl -f ${GEOM_FILE} \
	  -L cm -D g_cm3 \
	  -o ${GEOM_FILE/.gdml/_maxpath.xml} \
	  -n ${NPOINTS} \
	  -r ${NRAYS} \
	  --seed 0
fi

## Actually run GENIE
gevgen_fnal \
    -e ${EXP} \
    -f ${DK2NUFILE},${DET_LOCATION} \
    -g ${THIS_GEOM} \
    -m ${MAXPATH_FILE} \
    -L cm -D g_cm3 \
    --cross-sections ${TUNE}_FNALsmall.xml \
    --tune ${TUNE} \
    --seed 0

## Make the filename more meaningful
mv gntp.0.ghep.root ${OUTFILEPREFIX}_GHEP.root

## Convert to rootracker format (edep-sim's expected input)
gntpc -i ${OUTFILEPREFIX}_GHEP.root -f rootracker -o ${OUTFILEPREFIX}_ROO.root

## Now cherrypick events which have vertices in the 2x2 active volume
## This is entirely optional, but the POT should be reduced by a factor of 10 if it is skipped
python3 cherrypicker.py -i  ${OUTFILEPREFIX}_ROO.root -o ${OUTFILEPREFIX}_ROO_CHERRY.root

## Get the number of events for edepsim (I know, I know...)
NEVENTS=$(echo "TTree* tree = (TTree*)_file0->Get(\"gRooTracker\"); std::cout << tree->GetEntries() << std::endl;" | \
	      root -l -b ${OUTFILEPREFIX}_ROO_CHERRY.root | tail -1)
echo "Processed ${NEVENTS}, now convert..."

## The mac file defines the behaviour of edep-sim and G4
cp inputs/2x2_beam.mac this_edep_example.mac
sed -i "s/__GENIE_FILE__/${OUTFILEPREFIX}_ROO_CHERRY.root/g" this_edep_example.mac

## Run edep-sim
edep-sim -C -g ${THIS_GEOM} \
	 -o ${OUTFILEPREFIX}_EDEPSIM.root \
	 this_edep_example.mac \
	 -e ${NEVENTS}
