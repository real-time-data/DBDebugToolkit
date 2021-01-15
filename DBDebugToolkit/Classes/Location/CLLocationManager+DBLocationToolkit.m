// The MIT License
//
// Copyright (c) 2016 Dariusz Bukowski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "CLLocationManager+DBLocationToolkit.h"
#import "DBLocationToolkit.h"
#import "NSObject+DBDebugToolkit.h"
#import <objc/runtime.h>

static NSString *const CLLocationManagerLocationsKey = @"Locations";
NSTimer *timer;
NSInteger tripLocationCounter = 0;
//NSMutableArray *arr;
@implementation CLLocationManager (DBLocationToolkit)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Making sure to minimize the risk of rejecting app because of the private API.
        NSString *key = [[NSString alloc] initWithData:[NSData dataWithBytes:(unsigned char []){0x6f, 0x6e, 0x43, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x45, 0x76, 0x65, 0x6e, 0x74, 0x4c, 0x6f, 0x63, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x3a} length:22] encoding:NSASCIIStringEncoding];
        [self exchangeInstanceMethodsWithOriginalSelector:NSSelectorFromString(key)
                                      andSwizzledSelector:@selector(db_onClientEventLocation:)];
        // Making sure to minimize the risk of rejecting app because of the private API.
        key = [[NSString alloc] initWithData:[NSData dataWithBytes:(unsigned char []){0x6f, 0x6e, 0x43, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x45, 0x76, 0x65, 0x6e, 0x74, 0x4c, 0x6f, 0x63, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x3a, 0x66, 0x6f, 0x72, 0x63, 0x65, 0x4d, 0x61, 0x70, 0x4d, 0x61, 0x74, 0x63, 0x68, 0x69, 0x6e, 0x67, 0x3a, 0x74, 0x79, 0x70, 0x65, 0x3a} length:44] encoding:NSASCIIStringEncoding];
        [self exchangeInstanceMethodsWithOriginalSelector:NSSelectorFromString(key)
                                      andSwizzledSelector:@selector(db_onClientEventLocation:forceMapMatching:type:)];
    });
}

- (void)db_onClientEventLocation:(NSDictionary *)dictionary {
    if ([DBLocationToolkit sharedInstance].simulatedLocation == nil) {
        [self db_onClientEventLocation:dictionary];
    }else{
        NSMutableArray *clLocations = [[NSMutableArray alloc]init];
        [[DBLocationToolkit sharedInstance].simulatedLocation enumerateObjectsUsingBlock:^(DBPresetLocation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:obj.latitude longitude:obj.longitude];
            [clLocations addObject: location];
        }];
        [self.delegate locationManager:self didUpdateLocations:clLocations];
        
    }
}
#pragma mark -  location trip code

-(void)addLocationObserver {
    [self removeLocationObserver];
    [[NSNotificationCenter defaultCenter] addObserverForName:CLLocationUpdate
                                                      object:nil queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self performSelector:@selector(startLocationUpdates)];
                                                  }];
}

-(void)removeLocationObserver {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)startLocationUpdates{
   if(timer != nil) {
       [timer invalidate];
       timer = nil;
   }
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateLocation) userInfo:nil repeats:YES];
    tripLocationCounter = 0;
    
}

-(void)updateLocation {
    NSArray *points = [[DBLocationToolkit sharedInstance] simulatedLocation];
    if (tripLocationCounter >= points.count) {
        tripLocationCounter = 0;
    }
    
    DBPresetLocation *nextLocation = [points objectAtIndex:tripLocationCounter++];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:nextLocation.latitude longitude:nextLocation.longitude];
    
    [self.delegate locationManager:self didUpdateLocations:[NSArray arrayWithObject:location]];
}

-(void)stopTrip {
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    self.clLocations = nil;
}

- (void)db_onClientEventLocation:(NSDictionary *)dictionary forceMapMatching:(BOOL)forceMapMatching type:(id)type {
    
    [self startLocationUpdates];// not calling observer. trying to call directly
    
    
//    if ([DBLocationToolkit sharedInstance].simulatedLocation == nil) {
//        [self db_onClientEventLocation:dictionary forceMapMatching:forceMapMatching type:type];
//    } else {
//        self.clLocations = [[NSMutableArray alloc]init];
//        [[DBLocationToolkit sharedInstance].simulatedLocation enumerateObjectsUsingBlock:^(DBPresetLocation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            CLLocation *location = [[CLLocation alloc] initWithLatitude:obj.latitude longitude:obj.longitude];
//            [self.clLocations addObject: location];
//        }];
//        //[self.delegate locationManager:self didUpdateLocations:clLocations];
//    }
}

- (NSString *)clLocations{
    return objc_getAssociatedObject(self, @selector(text));
}

- (void)setClLocations:(NSMutableArray *)locations{
    objc_setAssociatedObject(self, @selector(clLocations), locations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
