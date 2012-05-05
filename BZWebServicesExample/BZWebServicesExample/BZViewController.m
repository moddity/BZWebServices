//
//  BZViewController.m
//  BZWebServicesExample
//
//  Created by Jaume Cornadó on 05/05/12.
//  Copyright (c) 2012 Bazinga Systems. All rights reserved.
//

#import "BZViewController.h"

#import "BZWebServices.h"

@interface BZViewController ()

@end

@implementation BZViewController
@synthesize textView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //Minimal configuration
    [[BZWebServices sharedInstance] setProgressView:self.view];
    [[BZWebServices sharedInstance] setAPIURL:@"https://api.twitter.com/"];
    [[BZWebServices sharedInstance] setRequestType:kTypeGet];
    
    //Define the request parameters
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"count", @"3", @"include_entities",@"true", nil];
    
    //Do the call
    [[BZWebServices sharedInstance] webServiceCall:@"/1/statuses/public_timeline.json" 
                                    withParameters:parameters
                                      showProgress:YES 
                                  withProgressText:@"BZWebServices Test"
                                    withParseBlock:^(NSString *response) {
                                        //Handle response
                                        textView.text = response;
                                    }];
    
}

- (void)viewDidUnload
{
    [self setTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
