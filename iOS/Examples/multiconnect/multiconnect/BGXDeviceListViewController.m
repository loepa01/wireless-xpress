/*
 * Copyright 2018-2019 Silicon Labs
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * {{ http://www.apache.org/licenses/LICENSE-2.0}}
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "BGXDeviceListViewController.h"
#import "BGXDeviceTableViewCell.h"
#import "DeviceDetailsViewController.h"

@interface BGXDeviceListViewController ()

@property (nonatomic, strong) NSArray * devices;

@end

@implementation BGXDeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _scanner = [[BGXpressScanner alloc] init];
    _scanner.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [_scanner startScan];
}

- (void)viewWillDisappear:(BOOL)animated
{
    BOOL result = [_scanner stopScan];
    if (!result) {
        NSLog(@"stopScan failed.");
    }
}


- (void)bluetoothStateChanged:(CBManagerState)state
{
    if (CBManagerStatePoweredOn == state) {
        [_scanner startScan];
    }
}

- (void)deviceDiscovered:(BGXDevice *)device
{
    NSMutableArray * ma = [_scanner.devicesDiscovered mutableCopy];
    
    [ma sortUsingComparator:^NSComparisonResult(id obj1, id obj2){
        BGXDevice * d1 = SafeType(obj1, [BGXDevice class]);
        BGXDevice * d2 = SafeType(obj2, [BGXDevice class]);
        NSAssert(d1 != d2, @"Fail.");
        
        return [d2.rssi compare:d1.rssi];
    }];

    self.devices = [ma copy];

    
    [self.tableView reloadData];
}

- (void)scanStateChanged:(ScanState)scanState
{
    NSString * strScanState = nil;
    switch (scanState) {
        case CantScan:
            strScanState = @"CantScan";
            break;
        case Idle:
            strScanState = @"Idle";
            break;
        case Scanning:
            strScanState = @"Scanning";
            break;
        default:
            strScanState = @"?";
            break;
    }
    NSLog(@"scanStateChanged: %@", strScanState);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    assert(0 == indexPath.section);
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"BGXDeviceCell"];
    BGXDeviceTableViewCell * deviceCell = SafeType(cell, [BGXDeviceTableViewCell class]);
    
    // setup the device cell.
    BGXDevice * bgxDevice = SafeType([self.devices objectAtIndex:indexPath.row], [BGXDevice class]);
    [deviceCell setBGXDevice: bgxDevice];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    BGXDeviceTableViewCell * cell = SafeType(sender, [BGXDeviceTableViewCell class]);
    if (cell) {
        if ( Connected == cell.device.deviceState ) {
            NSLog(@"shouldPerformSegue: YES");
            return YES;
        }
    }
    
    NSLog(@"shouldPerformSegue: NO");
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    BGXDeviceTableViewCell * cell = SafeType(sender, [BGXDeviceTableViewCell class]);
    if (cell) {
        DeviceDetailsViewController * ddvc = SafeType(segue.destinationViewController, [DeviceDetailsViewController class]);
        ddvc.device = cell.device;
        
    }
}

@end
