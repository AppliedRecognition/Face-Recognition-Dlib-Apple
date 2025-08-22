//
//  DlibLandmarkLocations.h
//  
//
//  Created by Jakub Dolejs on 21/08/2025.
//

#ifndef DlibLandmarkLocations_h
#define DlibLandmarkLocations_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/// Five canonical facial landmarks (dlib 5-point model)
@interface DlibLandmarkLocations : NSObject

@property (nonatomic, readonly) CGPoint leftEyeOuterCorner;
@property (nonatomic, readonly) CGPoint leftEyeInnerCorner;
@property (nonatomic, readonly) CGPoint rightEyeOuterCorner;
@property (nonatomic, readonly) CGPoint rightEyeInnerCorner;
@property (nonatomic, readonly) CGPoint philtrumTop;

/// Designated initializer
- (instancetype)initWithLeftEyeOuter:(CGPoint)leftOuter
                        leftEyeInner:(CGPoint)leftInner
                       rightEyeOuter:(CGPoint)rightOuter
                       rightEyeInner:(CGPoint)rightInner
                         philtrumTop:(CGPoint)philtrum NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Canonical chip-space template scaled to `size` (defaults mirror dlib’s 150×150 chip)
+ (instancetype)templateForSize:(NSInteger)size
NS_SWIFT_NAME(template(forSize:));

@end

NS_ASSUME_NONNULL_END


#endif /* DlibLandmarkLocations_h */
