//
//  BZWebServices.m
//  BZWebServices
//
//  Created by Oriol Vilaró on 06/07/11.
//  Copyright 2011 Bazinga Systems. All rights reserved.
//

#import "BZWebServices.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "MBProgressHUD.h"
#import "Reachability.h"

@implementation BZWebServices

@synthesize APIURL, fixedParameters, delegate, showProgress, progressView,requestType;

-(id)init {
	self = [super init];
	if (self != nil) {
		//init the main command queue
        queue = [[ASINetworkQueue alloc] init];
        [queue setDelegate:self];
        [queue setQueueDidFinishSelector:@selector(queueFinished:)];
        [queue setMaxConcurrentOperationCount:1];
        
        //by default we send the request with post parameters
        requestType = kTypePost;
        
        fixedParameters = [[NSMutableDictionary alloc] init];
	}
    
	return self;
}

////////////// QUEUE MANAGEMENT //////////////////
-(void) queueDidFinishSelector {
    [self hideProgress];
}

- (void)queueFinished:(ASINetworkQueue *)queue {
    [self hideProgress];
}


-(void) webServiceCall:(NSString*) method 
        withParameters: (NSDictionary*) parameters 
        withParseBlock:(APIParseBlock)parseBlock {
    
    [self webServiceCall:method withParameters:parameters 
            showProgress:self.showProgress 
          withParseBlock:parseBlock];
}

-(void) webServiceCall:(NSString*) method 
        withParameters: (NSDictionary*) parameters 
          showProgress:(BOOL)willShowProgress
        withParseBlock:(APIParseBlock)parseBlock {
    [self webServiceCall:method 
          withParameters:parameters 
            showProgress:willShowProgress
        withProgressText:nil
          withParseBlock:parseBlock];
}

-(void) webServiceCall:(NSString*) method 
        withParameters: (NSDictionary*) parameters 
          showProgress:(BOOL)willShowProgress
      withProgressText:(NSString *)progressText
        withParseBlock:(APIParseBlock)parseBlock {
    [self webServiceCall:method 
          withParameters: parameters
            showProgress:willShowProgress 
        withProgressText:progressText 
               withFiles:nil 
          withParseBlock:parseBlock];
}

-(void) webServiceCall: (NSString*) method
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
      withProgressText: (NSString*) progressText
             withFiles: (NSDictionary*) fileNames
        withParseBlock: (APIParseBlock) parseBlock {
    
    [self webServiceCall:method 
          withParameters: parameters
            showProgress:willShowProgress 
        withProgressText:progressText 
               withFiles:fileNames 
          withParseBlock:parseBlock
          withErrorTitle:nil
           withErrorText:nil];
    
}


-(void) webServiceCall: (NSString*) method 
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
      withProgressText: (NSString*) progressText
             withFiles: (NSDictionary*) fileNames
        withParseBlock: (APIParseBlock) parseBlock
        withErrorTitle: (NSString*)errorTitle
         withErrorText: (NSString*)errorText{
    
    [self webServiceCall:method 
          withParameters: parameters
            showProgress:willShowProgress 
        withProgressText:progressText 
               withFiles:fileNames 
          withParseBlock:parseBlock
          withErrorAlert:YES 
          withErrorTitle:errorTitle
           withErrorText:errorText];
    
    
    
}

-(void) webServiceCall: (NSString*) method 
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
      withProgressText: (NSString*) progressText
             withFiles: (NSDictionary*) fileNames
        withParseBlock: (APIParseBlock) parseBlock
        withErrorAlert: (BOOL)showAlertError
        withErrorTitle: (NSString*)errorTitle
         withErrorText: (NSString*)errorText{
    
    [self webServiceCall:method
             requestType:self.requestType
          withParameters:parameters
            showProgress:willShowProgress 
        withProgressText:progressText 
               withFiles:fileNames 
          withParseBlock:parseBlock
          withErrorAlert:showAlertError 
          withErrorTitle:errorTitle 
           withErrorText:errorText];
    
}


-(void) webServiceCall: (NSString*) method 
           requestType: (kRequestType) reqType
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
      withProgressText: (NSString*) progressText
             withFiles: (NSDictionary*) fileNames
        withParseBlock: (APIParseBlock) parseBlock
        withErrorAlert: (BOOL)showAlertError
        withErrorTitle: (NSString*)errorTitle
         withErrorText: (NSString*)errorText{
    
    if (self.requestType!=reqType) {
        self.requestType=reqType;
    }
    
    
    NSAssert(APIURL != nil, @"La APIURL es nula");
    
    //Setup the progress
    self.showProgress = willShowProgress;
    
    [self displayProgress];
    
    
    
    NSURL *methodUrl = nil;
    
    
    switch (requestType) {
        case kTypePut:
        case kTypeDelete:
        case kTypeGet:
            methodUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@",APIURL, method, [BZWebServices queryString:fixedParameters withParams:parameters]]];
            
            NSAssert(fileNames == nil, @"Can't send files with GET");
            
            break;
        case kTypePost:
            methodUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",APIURL, method]];
            break;
    }
    
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:methodUrl];
    
    
    DLog(@"FIXED PARAMS: %@", fixedParameters);
    
    for(NSString *param in fixedParameters) {
        
        if(requestType == kTypePost) {
            [request setPostValue:[fixedParameters objectForKey:param] forKey:param];
            DLog(@"BZWebServices: FIXED POST PARAMETER -> %@ => %@", param, [fixedParameters objectForKey:param]);                
        } else if(requestType == kTypeGet) {
            DLog(@"BZWebServices: FIXED GET PARAMETER -> %@ => %@", param, [fixedParameters objectForKey:param]);
        }
    }
    
    for(NSString *key in parameters) {
        if(requestType == kTypePost) {
            [request setPostValue:[parameters objectForKey:key] forKey:key];
            DLog(@"BZWebServices: POST PARAMETER -> %@ => %@", key, [parameters objectForKey:key]);
        } else if(requestType == kTypeGet) {
            DLog(@"BZWebServices: GET PARAMETER -> %@ => %@", key, [parameters objectForKey:key]);
        }
    }
    
    
    //Add files on post
    if(requestType == kTypePost && fileNames != nil && [[fileNames allKeys] count] > 0) {
        
        [request setPostFormat:ASIMultipartFormDataPostFormat];
        
        [fileNames enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [request setData:[fileNames objectForKey:key] withFileName:@"image.jpg" andContentType:@"image/jpeg" forKey:key];
        }];
        
    }
    
    switch (requestType) {
        case kTypeGet:
            request.requestMethod = @"GET";
            break;
            
        case kTypePost:
            request.requestMethod = @"POST";
            break;
            
        case kTypeDelete:
            request.requestMethod = @"DELETE";
            break;
            
        case kTypePut:
            request.requestMethod = @"PUT";            
            break;
            
        default:
            break;
    }
    
    

    DLog(@"BZWebServices: CALL URL -> %@", [request url]);
    
    request.accessibilityLabel = progressText;
    
    [request setDelegate:self];
    
    [request setDidStartSelector:@selector(requestStarted:)];
    
    [request setTimeOutSeconds:kTIMEOUT];
    
    DLog(@"BZWebServices: kTIMEOUT = %f",request.timeOutSeconds);
    
    __block BZWebServices *blockSelf = self;

    __block ASIFormDataRequest *blockRequest = request;
    
    [request setCompletionBlock:^{
        parseBlock([blockRequest responseString]);
    }];
    
    [request setFailedBlock:^{
        
        NSError *error = [blockRequest error];
        
        [blockSelf.delegate webServiceError:error];
        
        if (showAlertError) {
            
            NSString *errorTitleString = (errorTitle==nil ) ? @"Service Error" : errorTitle;
            
            NSString *errorString = (errorString==nil) ? [error localizedDescription] : errorText;
            
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitleString
                                                            message:errorString
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        
    }];
    DLog(@"BZWebServices: Call Start");
    [queue addOperation:request];
    [queue go];
}



-(void) webServiceCall:(NSString *)method withPostBody:(NSMutableData *)postBody contentType: (NSString*) contentType withParseBlock:(APIParseBlock)parseBlock {
    NSAssert(APIURL != nil, @"APIURL is null");
    
    //Setup the progress
    self.showProgress = YES;
    
    [self displayProgress];
    NSURL *methodUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",APIURL, method]];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:methodUrl];
    
    [request addRequestHeader:@"Content-Type" value:contentType];
    
    [request setPostBody:postBody];
    
    DLog(@"BZWebServices: CALL URL -> %@", [request url]);
    
    [request setDelegate:self];
    
    [request setDidStartSelector:@selector(requestStarted:)];
    
    [request setTimeOutSeconds:kTIMEOUT];

    DLog(@"BZWebServices: kTIMEOUT = %f",request.timeOutSeconds);

    [request setCompletionBlock:^{
        parseBlock([request responseString]);
    }];
    
    [request setFailedBlock:^{
        
        NSError *error = [request error];
        
        [delegate webServiceError:error];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Service Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        
    }];
    
    DLog(@"BZWebServices: Call Start");

    [queue addOperation:request];
    
    [queue go];
}



-(void) displayProgress {
    if(self.showProgress && progress == nil) {
        NSAssert(self.progressView != nil, @"Progress enabled and no view defined to contain it");
        progress = [[MBProgressHUD showHUDAddedTo:progressView animated:YES] retain];
        progress.yOffset = kPROGRESS_OFFSET;
    }
}

-(void) hideProgress {
    if(progress != nil) {
        //[progress hide:YES afterDelay:0.5];
        [progress hide:YES];
        progress = nil;
    }
}

-(void) requestStarted: (ASIFormDataRequest*) request {
    NSString *progressText = request.accessibilityLabel;
    progress.labelText = progressText;
}

+(NSString*) queryString: (NSDictionary*) fixedParameters withParams:(NSDictionary*) params {
    NSMutableString *queryString = [[NSMutableString alloc] init];
    
    if((fixedParameters != nil || params != nil) &&
       ([fixedParameters count] > 0 || [params count] > 0)) {
        
        [queryString appendString:@"?"];
        
        int total_params = [fixedParameters count] + [params count];
        int paramCount = 0;
        for(NSString *field in fixedParameters) {
            NSString *fieldValue = [fixedParameters objectForKey:field];
            [queryString appendFormat:@"%@=%@", field, [BZWebServices quoteString:fieldValue]];
            paramCount++;
            if(paramCount < total_params)
                [queryString appendString:@"&"];
        }
        
        for(NSString *field in params) {
            NSString *fieldValue = [params objectForKey:field];
            DLog(@"PARAM: %@", field);
            [queryString appendFormat:@"%@=%@", field, [BZWebServices quoteString:fieldValue]];
            paramCount++;
            if(paramCount < total_params)
                [queryString appendString:@"&"];
        }
        
        return [queryString autorelease];
        
    } else{
        [queryString release];
        return @"";
    }
    return nil;
}

+(NSString*) quoteString: (NSString*) originalString {
    
    
    if([originalString isKindOfClass:[NSNumber class]])
    {
        DLog(@"Is a nsnumber: %@",originalString);
        return originalString;   
    }
    
    
    DLog(@"ORS: %@", originalString);
    NSMutableString *escaped = [[NSMutableString alloc] initWithString:[originalString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [escaped replaceOccurrencesOfString:@"$" withString:@"%24" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"à" withString:@"%C3%A0" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"á" withString:@"%C3%A1" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"è" withString:@"%C3%A8" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"é" withString:@"%C3%A9" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"ì" withString:@"%C3%AC" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"í" withString:@"%C3%AD" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"ò" withString:@"%C3%B2" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"ó" withString:@"%C3%B3" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"ù" withString:@"%C3%B9" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"ú" withString:@"%C3%BA" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];    
    [escaped replaceOccurrencesOfString:@"ñ" withString:@"%C3%B1" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"·" withString:@"%C2%B7" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"ç" withString:@"%C3%A7" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    
    
    return escaped;
}

+(BOOL)isHostReachable:(NSString*)host{
    
    Reachability *netReach = [Reachability reachabilityWithHostName:host];
    
    NetworkStatus netStatus = [netReach currentReachabilityStatus];
    
    if ((netStatus==ReachableViaWiFi) || (netStatus==ReachableViaWWAN)) {
        return YES;
    }
    
    return NO;
}

+(BOOL)isInternetReachable{
    
    Reachability *internetReachable = [Reachability reachabilityForInternetConnection];
    
    NetworkStatus netStatus = [internetReachable currentReachabilityStatus];
    
    if ((netStatus==ReachableViaWiFi) || (netStatus==ReachableViaWWAN)) {
        return YES;
    }
    
    return NO;
}



@end