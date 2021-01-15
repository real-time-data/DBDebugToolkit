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

#import "DBLocationTableViewController.h"
#import "NSBundle+DBDebugToolkit.h"
#import "DBCustomLocationViewController.h"

static NSString *const DBLocationTableViewControllerSelectedCustomCellIdentifier = @"DBDebugToolkit_selectedCustomCell";
static NSString *const DBLocationTableViewControllerSimpleCellIdentifier = @"DBDebugToolkit_simpleCell";

@interface DBLocationTableViewController () <DBCustomLocationViewControllerDelegate>

@property (nonatomic, strong) NSNumber *selectedIndex;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *resetButton;

@end

@implementation DBLocationTableViewController
NSInteger selectedSection = 0;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.resetButton.enabled = self.locationToolkit.simulatedLocation != nil;
}

- (IBAction)resetButtonAction:(id)sender {
    self.locationToolkit.simulatedLocation = nil;
    self.selectedIndex = @-1;
    self.resetButton.enabled = NO;
    [self.tableView reloadData];
}

- (NSNumber *)selectedIndex {
    if (!_selectedIndex) {
        DBPresetLocation *presetLocation = [self.locationToolkit.simulatedLocation firstObject];
        CLLocation *simulatedLocation = [[CLLocation alloc] initWithLatitude:presetLocation.latitude longitude:presetLocation.longitude];
        if (simulatedLocation == nil) {
            _selectedIndex = @-1;
        } else {
            for (int i = 0; i < self.locationToolkit.presetLocations.count; i++) {
                
                NSMutableArray *locations = self.locationToolkit.presetLocations[i];
                DBPresetLocation *presetLocation = [locations firstObject];
                if (ABS(presetLocation.latitude - simulatedLocation.coordinate.latitude) < DBL_EPSILON
                    && ABS(presetLocation.longitude - simulatedLocation.coordinate.longitude) < DBL_EPSILON) {
                    _selectedIndex = @(i + 1);
                }
            }
            if (!_selectedIndex) {
                _selectedIndex = @0;
            }
        }
    }
    
    return _selectedIndex;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 13;
    } else if (section == 1) {
        return self.locationToolkit.presetLocations.count - 12;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Simulated location";
    } else if (section == 1){
    return @"GPX Files";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        if (self.selectedIndex.integerValue == 0 && indexPath.row == 0 && selectedSection == indexPath.section) {
            return [self selectedCustomCell];
        } else {
            return [self simpleCellForIndexPath:indexPath];
        }
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DBLocationTableViewControllerSimpleCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:DBLocationTableViewControllerSimpleCellIdentifier];
        }
        BOOL isSelected = false;//= self.selectedIndex.integerValue == indexPath.row;
        if(indexPath.row == self.selectedIndex.integerValue && selectedSection == indexPath.section){
            isSelected = true;
        } else {
            isSelected = false;
        }
        cell.textLabel.textColor = isSelected ? cell.tintColor : [UIColor blackColor];
        cell.textLabel.text = [self.locationToolkit.presetLocations[indexPath.row + 12] firstObject].title;
        cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark :
        UITableViewCellAccessoryNone;
        return cell;
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedSection = indexPath.section;
    
    if (indexPath.section == 0) {
        if (indexPath.row > 0)
        {
            self.selectedIndex = @(indexPath.row);
            NSMutableArray *presetLocations = self.locationToolkit.presetLocations[indexPath.row - 1];
            DBPresetLocation *presetLocation;
            
            if (indexPath.row == 14)
            {
                presetLocation = [presetLocations lastObject];
                NSLog(@"%@",presetLocations);
            } else {
                presetLocation = [presetLocations firstObject];
            }
            self.locationToolkit.simulatedLocation = presetLocations;//[[CLLocation alloc] initWithLatitude:presetLocation.latitude
            //longitude:presetLocation.longitude];
            self.resetButton.enabled = YES;
            [self.tableView reloadData];
        } else {
            NSBundle *bundle = [NSBundle debugToolkitBundle];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DBCustomLocationViewController" bundle:bundle];
            DBCustomLocationViewController *customLocationViewController = [storyboard instantiateInitialViewController];
            customLocationViewController.delegate = self;
            customLocationViewController.selectedLocation = self.locationToolkit.simulatedLocation;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:customLocationViewController];
            [self.navigationController presentViewController:navigationController animated:YES completion:nil];
        }
        } else if (indexPath.section == 1) {
            self.selectedIndex = @(indexPath.row);
            NSMutableArray *presetLocations = self.locationToolkit.presetLocations[indexPath.row + 12];
            DBPresetLocation *presetLocation;
            self.locationToolkit.simulatedLocation = presetLocations;//[[CLLocation alloc] initWithLatitude:presetLocation.latitude
            //longitude:presetLocation.longitude];
            self.resetButton.enabled = YES;
            [self.tableView reloadData];

    }
}

#pragma mark - DBCustomLocationViewControllerDelegate

- (void)customLocationViewController:(DBCustomLocationViewController *)customLocationViewController didSelectLocation:(CLLocation *)location {
    //self.locationToolkit.simulatedLocation = location;
    self.resetButton.enabled = YES;
    self.selectedIndex = @0;
    [self.tableView reloadData];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)customLocationViewControllerDidTapCancelButton:(DBCustomLocationViewController *)customLocationViewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private methods

- (UITableViewCell *)selectedCustomCell {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DBLocationTableViewControllerSelectedCustomCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:DBLocationTableViewControllerSelectedCustomCellIdentifier];
        cell.textLabel.textColor = cell.tintColor;
        cell.detailTextLabel.textColor = cell.tintColor;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    cell.textLabel.text = @"Custom";
    DBPresetLocation *location = self.locationToolkit.simulatedLocation.firstObject;
    cell.detailTextLabel.text = [self coordinateStringWithCoordinate:CLLocationCoordinate2DMake(location.latitude, location.longitude)];
    return cell;
}

- (UITableViewCell *)simpleCellForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DBLocationTableViewControllerSimpleCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:DBLocationTableViewControllerSimpleCellIdentifier];
    }
    BOOL isSelected = false;//= self.selectedIndex.integerValue == indexPath.row;
    if(indexPath.row == self.selectedIndex.integerValue && selectedSection == indexPath.section){
        isSelected = true;
    } else {
        isSelected = false;
    }
    cell.textLabel.textColor = isSelected ? cell.tintColor : [UIColor blackColor];
    
    cell.textLabel.text = indexPath.row == 0 ? @"Custom..." : [self.locationToolkit.presetLocations[indexPath.row - 1] firstObject].title;
    cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark :
    UITableViewCellAccessoryNone;
    return cell;
}

- (NSString *)coordinateStringWithCoordinate:(CLLocationCoordinate2D)coordinate {
    NSString *latitudeDegreesMinutesSeconds = [self degreesMinutesSecondsWithCoordinate:coordinate.latitude];
    NSString *latitudeDirectionLetter = coordinate.latitude >= 0 ? @"N" : @"S";
    NSString *longitudeDegreesMinutesSeconds = [self degreesMinutesSecondsWithCoordinate:coordinate.longitude];
    NSString *longitudeDirectionLetter = coordinate.longitude >= 0 ? @"E" : @"W";
    
    return [NSString stringWithFormat:@"%@%@, %@%@", latitudeDegreesMinutesSeconds,
                                                     latitudeDirectionLetter,
                                                     longitudeDegreesMinutesSeconds,
                                                     longitudeDirectionLetter];
}

- (NSString *)degreesMinutesSecondsWithCoordinate:(CLLocationDegrees)coordinate {
    NSInteger seconds = coordinate * 3600;
    NSInteger degrees = seconds / 3600;
    seconds = ABS(seconds % 3600);
    NSInteger minutes = seconds / 60;
    seconds %= 60;
    return [NSString stringWithFormat:@"%ld°%ld'%ld\"", ABS((long)degrees), (long)minutes, (long)seconds];
}

@end
