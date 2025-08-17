ProbeDeformer for iOS
=============
A simple 2D image deforming system using Dual Complex Numbers.

- LICENSE: the MIT License
- Requirements: Eigen (https://eigen.tuxfamily.org), iOS 13.0 and above, Swift 5.0+
- date:  Aug. 2025
- author: Shizuo KAJI

## Background
Please look at the following paper for details:
* "Anti-commutative Dual Complex Numbers and 2D Rigid Transformation" by G.Matsuda, S.Kaji, H.Ochiai.
Mathematical Progress in Expressive Image Synthesis I, pp. 131--138, Springer-Japan, 2014.
http://link.springer.com/book/10.1007/978-4-431-55007-5

An updated version is available at http://arxiv.org/abs/1601.01754

![Video](https://github.com/shizuo-kaji/iPad-ProbeDeformer/blob/master/DCN-ouchi.gif?raw=true)

## Features
- Dual Complex Numbers (DCN) based smooth 2D deformation
- Multiple falloff weights: Euclidean inverse-square, Harmonic, Bi-harmonic
- Multiple deformation models: DCN (recommended), MLS Rigid, MLS Similarity
- Symmetry mode, presets, and adjustable control-point size
- Image and live camera input switching
- Saves analysis data (CSV/TSV) alongside rendered images

### Build Requirements:
- Xcode 12.0 or later
- iOS 13.0 or later
- Swift 5.0 or later
- Eigen C++ library (included as Git submodule)

### Getting Started:
After cloning the repository, initialize the Eigen submodule:
```bash
git submodule update --init --recursive
```

Open `iPad-ProbeDeformer.xcodeproj` in Xcode and build for iOS 13+.

## Usage

Top bar
- Image: Load an image from the photo library
- Clear: Remove all control points and reset the state

Bottom bar
- Help: Shows a simple help screen
- Img|Cam: Toggle between photo input and live camera input
- Euc|Har|BiH: Select weighting (Euc: Euclidean inverse-square, Har: Harmonic, BiH: bi-harmonic)
- DCN|MLS_RIGID|MLS_SIM: Select deformation model
- Undo: Undo the last operation (may be unstable in rare cases)
- Save: Save the current image to the photo library and persist control/analysis data
- Load: Load previously saved control-point data
- Preset: Cycle through preset images
- rem: Remove all control points while keeping the current deformation
- Symmetry switch: Apply right-half deformation to the left half (mirror mode)
- Slider: Adjust the apparent size of control points (leftmost to hide)

Gestures
- Double-tap: Add or remove a control point
- Drag: Move a control point
- Pinch: Change the influence radius (strength) of a control point
- Two-finger rotate: Rotate a control point

Tip: Performing drag/pinch where no control point exists applies the action to all points at once.

## Data Export (Analysis)
- Use Finder’s File Sharing to access saved CSV/TSV files.
- Files contain initial and deformed positions of control points and related metadata.
- Filenames are auto-generated from the save timestamp.

## Documentation
- Japanese README: see `README-jp.md` for a detailed guide in Japanese.
