# 2x2_truth_studies

## Building and using the containers/software
For anybody comfortable with building and using containers, this section can largely be skipped.

### Singularity

Instructions for installing singularity on Linux can be found here: https://sylabs.io/guides/3.10/admin-guide/installation.html

I tested the build recipes on Ubuntu 22.04 with singularity version 3.10.2, although any version newer than 3.6.3 should be fine, and it shouldn't depend on the Linux OS.

There are instructions on how to run singularity on Mac/Windows, with the added hassle of doing it through a VM. Alternatively, there are docker images with the same contents available (see "Obtaining ready-made containers"). Note, however, that no instructions for running docker containers with the docker runtime environment will be provided... life is far too short. But in principle you should be able to run the same commands in the docker container once you deal with any directory mounting/X11 issues.

#### Building singularity containers
Singularity containers are built with a command like:
```
sudo singularity build images/<container.sif> <recipe.def>
```
Strictly speaking, the images directory isn't necessary. Note that you need to have root privileges and internet access when building (but not running) the containers.

Note that there are two .def files, the first containers ROOT and some other basics, the second builds from the first and adds in GENIE, edep-sim, GEANT4, etc etc:
* root_v6.14.06_pythia6.def
* 2x2_sim_prod.def

If you want to, you can also just take the commands in the .def files as a basis for building software locally. Or port it to a different container build system.

#### Obtaining ready-made containers
The simplest way to obtain the containers is through NERSC, you can download the (4GB) final container with:
```
wget https://portal.nersc.gov/project/dune/data/2x2/images/2x2_sim_prod.sif
```
(The intermediate ROOT container is in the same directory)

Alternatively, if you want to use docker containers, you can pull them down from dockerhub: wilkinsonnu/nuisance_project:2x2_sim_prod

You could even, if you were so inclined, pull from the dockerhub repo and run commands through the singularity runtime environment:
```
singularity exec docker://wilkinsonnu/nuisance_project:2x2_sim_prod <your command>
```
(It will cache the image so only the first such command would download the large file)


#### Running singularity containers
Singularity is pretty easy to use, if you want to run something in the container, you can simply run it like:
```
singularity exec </path/to/my_container.sif> <The same command you would have given locally>
```
Additionally, you can open up the container and poke around in it with:
```
singularity shell </path/to/my_container.sif>
```
This will open a new shell inside the container. Note that you cannot modify the contents of the container, **but** you can modify your host system!

## Generating/obtaining simulation files
This section describes how to generate events in a complex geometry using GENIE and simulating their energy deposition using GEANT4 wrapped in edep-sim. Both GENIE and edep-sim have extensive documentation of their own and anything not covered in this "quickstart guide" can probably be found there.

Note that this step is also unnecessary, and a large number of files made in the same way as the example provided here are provided at: https://portal.nersc.gov/project/dune/data/2x2/simulation/edepsim/

E.g., to get a single FHC file, generated in the same way as described in the example script:
```
wget https://portal.nersc.gov/project/dune/data/2x2/simulation/edepsim/NuMI_FHC_CHERRY/Merged2x2MINERvA_noRock_NuMI_FHC_CHERRY_5E17_000_EDEPSIM.root	
```
200 files are provided in both FHC and RHC, corresponding to 1E20 (equivalent to ~1 month of NuMI running)

## Analyzing the edep-sim output files

As a first step, it can be useful to visualize what is going on in an event. For just such a purpose, edep-sim provides an event display which can be used to view an edep-sim output file:
```
singularity exec images/2x2_sim_prod.sif edep-disp -s volLArActive -s DetectorlvTower -s volCryostatInnerBath_OuterTubTorusInnerTub <input_file>
```
The slightly cryptic -s arguments tell edep-sim which parts of the detector geometry to show. To keep rendering times short, only the larger volumes are shown, to provide a basic sketch of the detector layout with respect to the hits. Note that hits in all volumes are drawn. Basic event display functions are pretty self-explanatory, but for further details on what you can do with it, look at the edep-sim documentation.
