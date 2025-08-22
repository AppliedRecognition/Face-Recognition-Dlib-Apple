//
//  DlibLandmarks.h
//  
//
//  Created by Jakub Dolejs on 21/08/2025.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "DlibLandmarkLocations.h"

NS_ASSUME_NONNULL_BEGIN

/// Landmark detector wrapper around dlib's shape_predictor
@interface DlibLandmarks : NSObject

/// Load predictor from a `.dat` file inside your bundle/resources
- (instancetype)initWithModelAtPath:(NSString *)path;

/// Returns the 2x3 affine (row-major [a,b,tx,c,d,ty]) used by get_face_chip_details.
/// Coordinates are in pixels, y-down.
- (nullable NSArray<NSNumber *> *)faceChipTransformForGrayscaleImage:(const uint8_t *)image
                                                               width:(int)width
                                                              height:(int)height
                                                            faceRect:(CGRect)faceRect
                                                                size:(int)size
                                                             padding:(double)padding
                                                               error:(NSError * _Nullable * _Nullable)error
NS_SWIFT_NAME(faceChipTransform(forGrayscale:width:height:faceRect:size:padding:));


@end

NS_ASSUME_NONNULL_END
