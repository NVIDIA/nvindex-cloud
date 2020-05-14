# Sample Dataset Information

This document contains sizing information about the sample datasets. This is
useful for sizing when launching the NVIDIA IndeX Kubernetes Application.

## Dataset Sizing

| Dataset           | Size (GB) | Required GPUs | Recommended GPUs  |
|:------------------|:----------|:--------------|:------------------|
|Supernova          | 0.3       | 1 x T4        | 1 x T4            |
|Big Brain          | 52        | 4 x T4        | 8 x V100          |
|Parihaka - Clipped | 33        | 1 x T4        | 1 x V100          |
|Parihaka - Full    | 33        | 3 x T4        | 4 x V100          |
|Parihaka - Slices  | 33        | 1 x T4        | 1 x V100          |
|Cholla             | 85        | 6 x T4        | 8 x V100          |
|Fly Brain          | 20        | 2 x T4        | 2 x V100          |

## Details

## Core-Collapse Supernova

![supernova_preview](https://nvindex-data-samples.storage.googleapis.com/scenes/00-supernova_ncsa_small/scene/supernova.jpg)

Core-collapse supernovae are the birth places of neutron stars and black holes.
They liberate the ashes of stellar evolution, seeding the interstellar gas with
the elements from which planets form and life is made. Despite their importance
for much of astrophysics, our understanding of the supernova explosion
mechanism, and its dependence on progenitor star properties, is still
incomplete. The present dataset represents a short sequence of a core-collapse
simulations. Such simulations produce terabytes of output posing challenges
regarding the effective analysis of the physical processes. NVIDIA IndeX gives
researchers and scientists essential visual insights into such massive supernova
simulations and lets them expore the involved astrophysics processesvisualize.
Please also review the
[paper](https://sc18.supercomputing.org/proceedings/sci_viz/sci_viz_files/svs102s2-file1.pdf).

Credits: Phillip Moesta, Christian D. Ott, Roland Haas. Simulations done on NSF
/ NCSA Blue Waters Supercomputer. Simulation data kindly provided by Christian
Ott.

## Big Brain

![bigbrain_preview](https://nvindex-data-samples.storage.googleapis.com/scenes/01-brain/scene/brain.jpg)

The brain dataset is a ultrahigh-resolution scan of a human brain at nearly
cellular resolution of 20 micrometers, based on the reconstruction of 7404
histological sections. This dataset contains the reconstituted sections in the
coronal dimension. It shows aligned sections in the axial and sagittal
dimension, and histological volumes in histological space. The NVIDIA IndeX
Accelerated Computing technology ([XAC API](https://todo.com)) is the powerful
tool that enables researchers to carve out and identify different features of
particular interest inside the visualizations.

Credits: Prof. Dr. med. Katrin Amunts and the Structural and Functional
Organization of the Brain lab at the Institute of Neuroscience and Medicine,
Research Centre Jülich.

## Parihaka - Seismic Data - Clipped

![parihaka_small_preview](https://nvindex-data-samples.storage.googleapis.com/scenes/020-parihaka-small/scene/preview.jpg)

[Taranaki Basin](https://en.wikipedia.org/wiki/Taranaki_Basin) is an
onshore-offshore rift basin on the West Coast of New Zealand approx. 400 km west
of the Pacific-Australian plate boundary. The seismic data of the Parihaka
survey is located towards the northern part of the Basin and was acquired 2004
by New Zealand Petroleum and Minerals. The survey covers an area of 1,7 sq.km
and the seismic data volume consists of 1132 inlines and 2904 cross-lines.
NVIDIA IndeX is commonly used in the seismic interpretation systems for
scalable, high-fidelity and realtime visualization of seismic data. The clipped
volumes illustrates how the NVIDIA IndeX Accelerated Computing (XAC) technology
can be used to implement effective visualizations providing valuable cues and
thus generates better insights into the subsurface structures for efficient data
interpretation.

Credits: Special thanks to Crown Minerals and the New Zealand Ministry of
Economic Development for allowing us to display this Taranaki Basin dataset.
Crown Minerals manages the New Zealand Government’s oil, gas, mineral and coal
resources. More information is available at: [http://www.crownminerals.govt.nz]

## Parihaka - Seismic Data - Full Volume

![parihaka_full_preview](https://nvindex-data-samples.storage.googleapis.com/scenes/021-parihaka-large/scene/preview.jpg)

[Taranaki Basin](https://en.wikipedia.org/wiki/Taranaki_Basin)  is an
onshore-offshore rift basin on the West Coast of New Zealand approx. 400 km west
of the Pacific-Australian plate boundary. The seismic data of the Parihaka
survey is located towards the northern part of the Basin and was acquired 2004
by New Zealand Petroleum and Minerals. The survey covers an area of 1,7 sq.km
and the seismic data volume consists of 1132 inlines and 2904 cross-lines.
NVIDIA IndeX is commonly used in the seismic interpretation systems for
scalable, high-fidelity and realtime visualization of seismic data. The
visualization of the entire Parihaka survey demonstrates that NVIDIA IndeX can
utilize multiple GPUs for interacive exploarion of seismic data ultimately at
any scale for efficient data interpretation.

Credits: Special thanks to Crown Minerals and the New Zealand Ministry of
Economic Development for allowing us to display this Taranaki Basin dataset.
Crown Minerals manages the New Zealand Government’s oil, gas, mineral and coal
resources. More information is available at: [http://www.crownminerals.govt.nz]

## Parihaka - Seismic Data - Slices

![parihaka_slices_preview](https://nvindex-data-samples.storage.googleapis.com/scenes/022-parihaka-planes/scene/preview.jpg)

[Taranaki Basin](https://en.wikipedia.org/wiki/Taranaki_Basin)  is an
onshore-offshore rift basin on the West Coast of New Zealand approx. 400 km west
of the Pacific-Australian plate boundary. The seismic data of the Parihaka
survey is located towards the northern part of the Basin and was acquired 2004
by New Zealand Petroleum and Minerals. The survey covers an area of 1,7 sq.km
and the seismic data volume consists of 1132 inlines and 2904 cross-lines.
NVIDIA IndeX is commonly used in the seismic interpretation systems for
scalable, high-fidelity and realtime visualization of seismic data. The
visualization of the entire Parihaka seismic volume with embedded slices
highlights that NVIDIA IndeX with its XAC technology can boost conventional
seismic interpretations workflows.

Credits: Special thanks to Crown Minerals and the New Zealand Ministry of
Economic Development for allowing us to display this Taranaki Basin dataset.
Crown Minerals manages the New Zealand Government’s oil, gas, mineral and coal
resources. More information is available at: [http://www.crownminerals.govt.nz]

## Cholla

![cholla_preview](https://nvindex-data-samples.storage.googleapis.com/scenes/03-cholla/scene/preview.jpg)


Galactic winds are outflows of gas driven out of galaxies by the combined
effects of thousands of supernovae and are a crucial feature of galaxy
evolution. By removing gas from galaxies, they regulate future star formation,
and distribute the dust and heavy elements formed in stars throughout the
Universe. Despite their importance, a complete theoretical picture of these
winds has been elusive. Simulating the complicated interaction between the hot,
high pressure gas created by supernovae and the cooler, high density gas in the
galaxy disk requires massive computational resources and highly sophisticated
software producing terabytes of simulation data. NVIDIA IndeX allows researchers
and scientist to create specialized visualizations technique (see [XAC
API](www.todo.com)) that helps to answer specific analysis questions regarding
large-scale galactic flow phenomena. Please also review the
[paper](https://sc19.supercomputing.org/proceedings/sci_viz/sci_viz_files/svs101s2-file1.pdf)
.

Credits: [Cholla](https://evaneschneider.org/cholla), Evan Schneider, Princeton
University, es26@astro.princeton.edu, Brant Robertson, Associate Professor,
University of California Santa Cruz, brant@ucsc.edu, Simulations done on the
ORNL Titan supercomputer.

## Fly Brain - Microscopy

![flybrain_preview](https://nvindex-data-samples.storage.googleapis.com/scenes/04-microscopy-exllsm/scene/preview.jpg)

The dataset represents a nanoscale imaging of the brain of a fly. The core of
the work is the combination of expansion microscopy and lattice light-sheet
microscopy (ExLLSM) to capture large super-resolution image volumes of neural
circuits using high-speed, nano-scale molecular microscopy. The XYZ GB of
multi-channel ExLLSM data show the 3D spatial relationships between essential
proteins responsible for many functions in the brain including neural
connectivity and signal regulation. The NVIDIA IndeX Accelerate Computing
technology (see  [XAC API](www.todo.com)) allows researchers to visualize each
channel individually or in combination to derive additional knowledge from the
large data in real time. Please also review Cortical column and whole-brain
imaging with molecular contrast and nanoscale resolution
[paper](https://science.sciencemag.org/content/363/6424/eaau8302).

Credits: Eric Bezig, Gokul Upadhyayula, and researchers from MIT, Harvard,
University of California, Berkeley.
