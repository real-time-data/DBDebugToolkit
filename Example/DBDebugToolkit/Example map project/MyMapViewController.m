//
//  MyMapViewController.m
//  DBDebugToolkit_Example
//
//  Created by gurleen singh on 14/8/18.
//  Copyright © 2018 Dariusz Bukowski. All rights reserved.
//

#import "MyMapViewController.h"
#import "GPX.h"
#import "GPXParser.h"

@interface MyMapViewController ()
{
    NSMutableArray *array;
    NSTimer *timer;
    int counter;
    NSArray *arrayLocations;
    CLLocationManager *locationManager;
}

@end

@implementation MyMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    [_mapView setShowsUserLocation:true];
    
    
//    NSString *str=[[NSBundle mainBundle] pathForResource:@"Trip" ofType:@"gpx"];
//    NSData *fileData = [NSData dataWithContentsOfFile:str];
//
//    GPXRoot *gpx = [GPXParser parseGPXWithData:fileData];
//    arrayLocations = [gpx waypoints];
//
//    array = [NSMutableArray new];
//    for (GPXWaypoint *point in arrayLocations){
//        MKUserLocation *loc = [MKUserLocation new];
//        CLLocationCoordinate2D coordinate;
//        coordinate.latitude = point.latitude;
//        coordinate.longitude = point.longitude;
//        loc.coordinate = coordinate;
//        [array addObject:loc];
//    }
//    self.mapView.delegate = self;
//    counter  = 0;
//    timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(coutnerCalled) userInfo:nil repeats:YES];
//    NSLog(@"Something To Print");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

}

- (void)coutnerCalled {
    if (counter>=[array count]) {
        counter = 0;
    }
    MKUserLocation *loc = [MKUserLocation new];
    loc = [array objectAtIndex:counter++];
    NSLog(@"%@",loc);
    [self mapView:self.mapView didUpdateUserLocation:loc];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    CLLocation *location = locations.lastObject;
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       CLPlacemark *placemark = placemarks.firstObject;
                       NSMutableArray *placemarkDescriptions = [NSMutableArray array];
                       if (placemark.country) {
                           [placemarkDescriptions addObject:placemark.country];
                       }
                       if (placemark.administrativeArea) {
                           [placemarkDescriptions addObject:placemark.administrativeArea];
                       }
                       if (placemark.locality) {
                           [placemarkDescriptions addObject:placemark.locality];
                       }
                   }];
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 1000, 1000);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = userLocation.coordinate;
    point.title = userLocation.title;
    [self.mapView addAnnotation:point];
}

@end
