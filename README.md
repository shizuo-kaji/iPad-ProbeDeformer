ProbeDeformer for iOS
=============
A simple 2D image deforming system using Dual Complex Numbers.

- LICENSE: the MIT License
- Requirements: Eigen (https://eigen.tuxfamily.org), iOS 13.0 and above, Swift 5.0+
- version: 0.20 (Swift Migration)
- date:  Aug. 2025
- author: Shizuo KAJI

## Background 
Please look at the following paper for details:
* "Anti-commutative Dual Complex Numbers and 2D Rigid Transformation" by G.Matsuda, S.Kaji, H.Ochiai.
Mathematical Progress in Expressive Image Synthesis I, pp. 131--138, Springer-Japan, 2014.
http://link.springer.com/book/10.1007/978-4-431-55007-5

An updated version is available at http://arxiv.org/abs/1601.01754

![Video](https://github.com/KyushuUniversityMathematics/iPad-ProbeDeformer/blob/master/DCN-ouchi.gif?raw=true)

## Swift Migration (v0.20)

This version has been migrated from Objective-C to Swift while maintaining all original functionality:

### Migrated to Swift:
- **AppDelegate**: Now uses modern Swift patterns with @main attribute
- **ViewController**: Full Swift conversion with proper type safety and modern iOS APIs
- **FileViewController**: Swift implementation with improved error handling

### Retained as Objective-C:
- **Probe**: Kept as Objective-C due to heavy C++ (DCN, Eigen) dependencies
- **ImageVertices**: Kept as Objective-C for C++ mathematical library integration
- **DCN Library**: Core mathematical operations remain in C++

### Improvements:
- Modern iOS 13.0+ deployment target
- Swift 5.0+ compatibility
- Improved memory management with ARC
- Better type safety and error handling
- Maintained full backward compatibility with existing functionality

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
