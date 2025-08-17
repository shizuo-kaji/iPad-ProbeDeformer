# Swift Migration Tasks

## Overview
Modernize the iPad-ProbeDeformer app by migrating from Objective-C to Swift while maintaining all existing functionality and improving iOS compatibility.

## Core Migration Tasks

### Language Migration
- [x] Convert AppDelegate from Objective-C to Swift
- [x] Migrate ViewController.m/h to Swift
- [x] Convert FileViewController to Swift
- [x] Keep Probe.m/h as Objective-C (due to heavy C++ dependencies)
- [x] Keep ImageVertices.m/h as Objective-C (due to heavy C++ dependencies)
- [x] Remove main.m (using @main attribute in AppDelegate)

### iOS Compatibility Updates
- [x] Update deployment target to iOS 13.0+ (current minimum supported)
- [x] Replace deprecated UIKit APIs with modern equivalents
- [ ] Update storyboard constraints for latest screen sizes
- [ ] Test on iPad Air, iPad Pro, and iPad mini form factors
- [ ] Ensure iPhone compatibility (if desired)

### Build System Updates
- [x] Update Xcode project settings for Swift compilation
- [x] Configure Swift-Objective-C bridging header
- [x] Add Eigen as Git submodule for dependency management
- [x] Update build phases and link frameworks
- [x] Configure Eigen C++ library integration with Swift
- [x] Update Eigen header paths in all source files
- [x] Fix C++17 standard requirement for Eigen compilation
- [x] Fix bridging header C++ compilation issues
- [x] Fix DCN.h standard library compatibility for iOS

### Testing & Validation
- [ ] Verify dual complex number mathematics remain accurate
- [ ] Test image deformation functionality
- [ ] Validate touch interactions and probe placement
- [ ] Performance testing on various iPad models
- [ ] Memory usage optimization

### Documentation
- [x] Update README.md with Swift version requirements
- [ ] Document any API changes
- [ ] Update build instructions
