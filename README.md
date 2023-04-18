# Light Field Toolbox for MATLAB

Copyright (c) 2013-2020 Donald G. Dansereau

This is a toolbox for working with light field imagery in MATLAB. Features include loading, visualizing, and filtering light fields, and decoding, calibration, and rectification of lenslet-based imagery.

The most recent release and development versions are here: [https://github.com/doda42/LFToolbox](https://github.com/doda42/LFToolbox).

The complementary LiFF light field feature toolbox is here: [http://dgd.vision/Tools/LiFF](http://dgd.vision/Tools/LiFF)

## Installation and Sample Data
Please refer to LFToolbox.pdf for installation and usage instructions.

Sample data:

* [LFToolbox v0.5 Sample Pack](http://www-personal.acfr.usyd.edu.au/donald/LFToolbox0.5_Samples.zip)
* [Small Sample Calibration](http://www-personal.acfr.usyd.edu.au/ddan1654/PlenCalSmallExample.zip)
* Additional datasets and community links at [dgd.vision](http://dgd.vision/Tools/LFToolbox)

## What's New / Development Plan
v0.5.3: bug fixes, see CHANGELOG.txt
v0.5.2: bug fixes, see CHANGELOG.txt

v0.5.1: bug fixes, documentation improvements, see CHANGELOG.txt

v0.5 introduces new features, bug fixes, and performance improvements. Highlights:
* Linear refocus super-resolution using LFFiltShiftSum.
* New display functions LFDispLawnmower, LFDispTiles, LFDispTilesSubfigs, LFDispProj, LFDispProjSubfigs
* LFReadESLF, LFWriteESLF
* Improved decode performance and speed
* Improved calibration accuracy
* LFDisp* functions are better behaved, now display in the active figure window

For a complete list, see CHANGELOG.txt.

Future plans include more significant changes to lenslet-based decode and calibration, and support for a broader range of cameras.

## Compatibility

**Reverse-compatibility**: Changes to interfaces have been minimised, LFDispVidCirc is the main exception, with a new parameter structure.

Previously generated calibration files should be re-generated, and to benefit from performance improvements to decoding, white images should be re-generated. See LFToolbox.pdf for details.

**Matlab**: LFToolbox 0.5 was written in MATLAB 2020a, but should be compatible with earlier versions.

**File Formats**: The toolbox can load gantry / array-style folders of images, ESLF files, and raw lenslet-based images.

**Plenoptic 1.0** cameras are supported through decoding, calibration, and rectification of imagery. Functions are most easily applied to Lytro imagery. The toolbox can also be applied to other lenslet-based Plenoptic 1.0 cameras, but this is not yet well documented. Calibration of Lytro Illum cameras is experimental.

**Plenoptic 2.0** cameras are not well supported. Use with some cameras is possible but not well documented. Multi-focal lenslet-based cameras are not well supported.

**Lytro Software**: The toolbox is compatible with files generated using Lytro Desktop 4 and 3, and will load ESLF files generated using the Lytro Power Tools.

## Contributing / Feedback
Suggestions, bug reports, code improvements and new functionality are welcome -- email Donald.Dansereau+LFToolbox {at} gmail dot com.

## Branch Structure
* tags: keep track of each release
* master: always the most recent release
* develop<version #>: developing new functionality for specific release
* develop: experimental functionality
* release<version #>: soon-to-be-released branch, to be merged into master

Code in the develop branches is incomplete, unstable, undocumented, and unsupported. Use at your own risk. Functions named LFX* are new/experimental.

## Acknowledgements
Parts of the code were taken with permission from the Camera Calibration Toolbox for MATLAB by Jean-Yves Bouguet, with contributions from Pietro Perona and others; and from the JSONlab Toolbox by Qianqian Fang and others. LFFigure was originally by Daniel Eaton. The LFP reader is based in part on Nirav Patel and Doug Kelley's LFP readers. Thanks to Michael Tao for help and samples for decoding Illum imagery.

## Citing
The appropriate citations for decoding, calibration and rectification and the volumetric focus (hyperfan) filter are:

<pre>@inproceedings{dansereau2013decoding,
 title={Decoding, Calibration and Rectification for lenselet-Based Plenoptic Cameras},
 author={Donald G. Dansereau and Oscar Pizarro and Stefan B. Williams},
 booktitle={Computer Vision and Pattern Recognition (CVPR), IEEE Conference on},
 year={2013},
 month={Jun},
 organization={IEEE}
}</pre>

<pre>@article{dansereau2015linear, 
 title={Linear Volumetric Focus for Light Field Cameras},
 author={Donald G. Dansereau and Oscar Pizarro and Stefan B. Williams},
 journal={ACM Transactions on Graphics (TOG)},
 volume={34},
 number={2},
 month={Feb.},
 year={2015}
}</pre>

