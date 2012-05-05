BZWebServices
=============

A simple lib to query a REST WebService using blocks.

Framework Dependency
====================
* CFNetwork.framework
* SystemConfiguration.framework
* libxml2.dylib
* libz.dylib
* MobileCoreServices.framework

How to use it
=============

You can take a look to Example Project, but the usage is very simple

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
