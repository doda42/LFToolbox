% Light Field Toolbox
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% 
% Setup
%   LFMatlabPathSetup         - convenience function to add the light field toolbox to matlab's path
% 
% Decoding
%   LFUtilProcessWhiteImages  - process a folder/tree of white images by fitting a grid model to each
%   LFUtilDecodeLytroFolder   - decode and optionally colour correct and rectify Lytro light fields
%   LFLytroDecodeImage        - decode a Lytro light field from a raw lenslet image, called by LFUtilDecodeLytroFolder
% 
% Display
%   LFDisp                    - Convenience function to display a 2D slice of a light field using imagesc
%   LFDispMousePan            - visualize a 4D light field using the mouse to pan through two dimensions
%   LFDispVidCirc             - visualize a 4D light field animating a circular path through two dimensions
%   LFDispLawnmower           - visualize a 4D light field animating a lawnmower path through two dimensions
%   LFDispProj                - Project a 4D light field onto a plane, and optionally display it to the screen
%   LFDispProjSubfigs         - Build six subfigures dispaying projections of the LF onto pairs dimensions
%   LFDispTiles               - Tile a 4D light field into a 2D array of 2D slices, optionally display to the screen
%   LFDispTilesSubfigs        - Build six subfigures dispaying 2D x 2D tilings of the LF
%   LFFigure                  - Create a figure window without stealing focus
% 
% File IO
%   LFReadESLF                - Read ESLF-encoded light fields
%   LFWriteESLF               - LFWriteESLF.m - Write ESLF-encoded light fields
%   LFReadGantryArray         - load gantry-style light field, e.g. the Stanford light fields at lightfield.stanford.edu
%   LFUtilExtractLFPThumbs    - extract thumbnails from LFP files and write to disk
%   LFReadMetadata            - reads the metadata files in the JSON file format, from a file or a char buffer
%   LFWriteMetadata           - saves variables to a file in JSON format
%   LFUtilUnpackLytroArchive  - extract white images and other files from a multi-volume Lytro archive
%   LFFindFilesRecursive      - Recursively searches a folder for files matching one or more patterns
%   LFReadLFP                 - Load a lytro LFP / LFR file
%   LFReadRaw                 - Reads 8, 10, 12 and 16-bit raw image files
% 
% Calibration and Rectification
%   LFUtilCalLensletCam       - calibrate a lenslet-based light field camera
%   LFUtilProcessCalibrations - process a folder/tree of camera calibrations
%   LFCalRectifyLF            - rectify a light field using a calibrated camera model, called as part of LFUtilDecodeLytroFolder
%   LFCalDispRectIntrinsics   - Visualize sampling pattern resulting from a prescribed intrinsic matrix
%   LFRecenterIntrinsics      - Recenter a light field intrinsic matrix
%   LFCalDispEstPoses         - Visualize pose estimates associated with a calibration info file
% 
% Building Filters
%   LFBuild2DFreqFan          - construct a 2D fan passband filter in the frequency domain
%   LFBuild2DFreqLine         - construct a 2D line passband filter in the frequency domain
%   LFBuild4DFreqDualFan      - construct a 4D dual-fan passband filter in the frequency domain
%   LFBuild4DFreqHypercone    - construct a 4D hypercone passband filter in the frequency domain
%   LFBuild4DFreqHyperfan     - construct a 4D hyperfan passband filter in the frequency domain
%   LFBuild4DFreqPlane        - construct a 4D planar passband filter in the frequency domain
% 
% Applying Filters and Enhancements
%   LFFilt2DFFT               - Apply a 2D frequency-domain filter to a 4D light field using the FFT
%   LFFilt4DFFT               - Applies a 4D frequency-domain filter using the FFT
%   LFFiltShiftSum            - A spatial-domain depth-selective filter with optional refocus super-resolution
%   LFColourCorrect           - applies a colour correction matrix, balance vector, and gamma, called by LFUtilDecodeLytroFolder
%   LFHistEqualize            - histogram-based contrast adjustment
% 
% Demos
%   LFDemoBasicFiltGantry     - demonstrate basic filters on stanford-style gantry light fields
%   LFDemoBasicFiltIllum      - demonstrate basic filters on illum-captured imagery
%   LFDemoBasicFiltLytroF01   - demonstrate basic filters on Lytro-F01-captured imagery
%   LFDemoRefocusSuperres     - Demonstrate super-resolution using LFFiltShiftSum's UpsampRate parameter
 
