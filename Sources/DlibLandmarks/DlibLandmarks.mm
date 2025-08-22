//
//  DlibLandmarks.m
//  
//
//  Created by Jakub Dolejs on 21/08/2025.
//

#import "DlibLandmarks.h"
#import <dlib/image_processing/shape_predictor.h>
#import <dlib/image_processing.h>
#import <dlib/image_transforms.h>
#import <dlib/array2d.h>
#import <dlib/pixel.h>
#import <dlib/geometry/rectangle.h>
#import <dlib/serialize.h>

using namespace dlib;

@interface DlibLandmarks () {
    shape_predictor predictor;
    bool predictorLoaded;
}
@end

@implementation DlibLandmarks

- (instancetype)initWithModelAtPath:(NSString *)path {
    if (self = [super init]) {
        predictorLoaded = false;
        try {
            deserialize([path UTF8String]) >> predictor;
            predictorLoaded = true;
        } catch (std::exception &e) {
            NSLog(@"Failed to load predictor: %s", e.what());
        }
    }
    return self;
}

using namespace dlib;

static NSString * const DlibLandmarksErrorDomain = @"DlibLandmarksError";

typedef NS_ENUM(NSInteger, DlibLandmarksErrorCode) {
    DlibLandmarksErrorNotLoaded   = 1,
    DlibLandmarksErrorBadArgs     = 2,
    DlibLandmarksErrorBadRect     = 3,
    DlibLandmarksErrorPredictFail = 4,
    DlibLandmarksErrorNoParts     = 5,
};

- (NSArray<NSNumber *> *)faceChipTransformForGrayscaleImage:(const uint8_t *)image
                                                      width:(int)width
                                                     height:(int)height
                                                   faceRect:(CGRect)faceRect
                                                       size:(int)size
                                                    padding:(double)padding
                                                      error:(NSError * _Nullable * _Nullable)error
{
    auto makeErr = ^NSArray<NSNumber *> * (NSInteger code, NSString *msg) {
        if (error) *error = [NSError errorWithDomain:@"DlibLandmarksError" code:code
                                            userInfo:@{NSLocalizedDescriptionKey: msg}];
        return nil;
    };
    
    if (!predictorLoaded) return makeErr(1, @"Shape predictor not loaded.");
    if (!image || width <= 1 || height <= 1) return makeErr(2, @"Invalid image.");
    
    dlib::array2d<unsigned char> img; img.set_size(height, width);
    std::memcpy(&img[0][0], image, (size_t)width * (size_t)height);
    
    auto clamp = [&](double v, double lo, double hi)->long {
        if (v < lo) v = lo; if (v > hi) v = hi; return (long)llround(v);
    };
    long L = clamp(faceRect.origin.x, 0, width-1);
    long T = clamp(faceRect.origin.y, 0, height-1);
    long R = clamp(faceRect.origin.x + faceRect.size.width  - 1, 0, width-1);
    long B = clamp(faceRect.origin.y + faceRect.size.height - 1, 0, height-1);
    if (R <= L || B <= T) return makeErr(3, @"Face rectangle out of bounds.");
    
    dlib::full_object_detection shape;
    try { shape = predictor(img, dlib::rectangle(L,T,R,B)); }
    catch (const std::exception& e) { return makeErr(4, [NSString stringWithFormat:@"predictor: %s", e.what()]); }
    if (shape.num_parts() != 5) return makeErr(5, @"Predictor did not return 5 points.");
    
    dlib::chip_details cd = dlib::get_face_chip_details(shape, size, padding);
    // cd.get_transform() gives dlib::matrix<double,2,3> mapping source->chip (y-down)
    point_transform_affine xform = get_mapping_to_chip(cd);
    
    // Row-major [a,b,tx,c,d,ty]
    matrix<double,2,2> M = xform.get_m();
    dlib::vector<double,2> B2 = xform.get_b();
    
    // If you need to hand the 2×3 to Swift:
    NSArray<NSNumber*> *affine = @[@(M(0,0)), @(M(0,1)), @(B2(0)),
                                   @(M(1,0)), @(M(1,1)), @(B2(1))];
    return affine;
}


@end
