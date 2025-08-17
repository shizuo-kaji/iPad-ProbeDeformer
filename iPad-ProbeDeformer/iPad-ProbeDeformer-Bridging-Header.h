//
//  iPad-ProbeDeformer-Bridging-Header.h
//  iPad-ProbeDeformer
//
//  Use this file to import Objective-C headers that you want to expose to Swift.
//

// Import necessary iOS frameworks
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/gltypes.h>

// Import the original Objective-C classes that we still need
// We'll keep the core mathematical classes as Objective-C for now
// due to their heavy C++ dependencies

#import "Probe.h"
#import "ImageVertices.h"
#import "DCN.h"