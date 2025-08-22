//
//  DlibLandmarkLocations.m
//  
//
//  Created by Jakub Dolejs on 21/08/2025.
//

#import "DlibLandmarkLocations.h"

@implementation DlibLandmarkLocations

- (instancetype)initWithLeftEyeOuter:(CGPoint)leftOuter
                        leftEyeInner:(CGPoint)leftInner
                       rightEyeOuter:(CGPoint)rightOuter
                       rightEyeInner:(CGPoint)rightInner
                         philtrumTop:(CGPoint)philtrum
{
    if ((self = [super init])) {
        _leftEyeOuterCorner  = leftOuter;
        _leftEyeInnerCorner  = leftInner;
        _rightEyeOuterCorner = rightOuter;
        _rightEyeInnerCorner = rightInner;
        _philtrumTop         = philtrum;
    }
    return self;
}

+ (instancetype)templateForSize:(NSInteger)size
{
    // Base template for 150×150 chips (approximate; swap with your exact dlib template if desired)
    const CGPoint baseLeftOuter  = {38.0, 55.0};
    const CGPoint baseLeftInner  = {66.0, 55.0};
    const CGPoint baseRightOuter = {112.0, 55.0}; // note: our naming is symmetric; see mapping below
    const CGPoint baseRightInner = {84.0, 55.0};
    const CGPoint basePhiltrum   = {75.0, 95.0};
    
    const CGFloat s = (CGFloat)size / 150.0f;
    return [[self alloc] initWithLeftEyeOuter:(CGPoint){baseLeftOuter.x*s,  baseLeftOuter.y*s}
                                 leftEyeInner:(CGPoint){baseLeftInner.x*s,  baseLeftInner.y*s}
                                rightEyeOuter:(CGPoint){baseRightOuter.x*s, baseRightOuter.y*s}
                                rightEyeInner:(CGPoint){baseRightInner.x*s, baseRightInner.y*s}
                                  philtrumTop:(CGPoint){basePhiltrum.x*s,   basePhiltrum.y*s}];
}

@end
