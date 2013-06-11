//
//  BZWebServices.h
//  BZWebServices
//
//  Created by Oriol Vilaró on 06/07/11.
//  Copyright 2011 Bazinga Systems. All rights reserved.
//

#define kTIMEOUT 200.0

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ASINetworkQueue;

#ifndef APIParseBlock
typedef void (^APIParseBlock)(NSString* response);
#endif

typedef enum { kTypePost, kTypeGet, kTypeDelete, kTypePut } kRequestType;

@protocol BZWebServicesDelegate <NSObject>

@optional
    -(void) webServiceError: (NSError*) error;
@end

@interface BZWebServices : NSObject {
    
    id<BZWebServicesDelegate> delegate;
    /* Main command queue */
    ASINetworkQueue *queue;
    
    //Main WebService values
    NSString *APIURL;
    NSMutableDictionary *fixedParameters;
    //Configuration
    kRequestType requestType;
    
    
}

@property (assign) id<BZWebServicesDelegate> delegate;
@property (nonatomic, retain) NSString *APIURL;
@property (nonatomic, retain) NSMutableDictionary *fixedParameters;
//Configuration
@property (assign) kRequestType requestType;

/* Executes the call to the webService */

-(void) webServiceCall: (NSString*) method 
           requestType: (kRequestType) reqType
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
      withProgressText: (NSString*) progressText
             withFiles: (NSDictionary*) fileNames
        withParseBlock: (APIParseBlock) parseBlock
        withErrorAlert: (BOOL)showAlertError
        withErrorTitle: (NSString*)errorTitle
         withErrorText: (NSString*)errorText;

-(void) webServiceCall: (NSString*) method 
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
      withProgressText: (NSString*) progressText
             withFiles: (NSDictionary*) fileNames
        withParseBlock: (APIParseBlock) parseBlock
        withErrorAlert: (BOOL)showAlertError
        withErrorTitle: (NSString*)errorTitle
         withErrorText: (NSString*)errorText;

-(void) webServiceCall: (NSString*) method 
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
      withProgressText: (NSString*) progressText
             withFiles: (NSDictionary*) fileNames
        withParseBlock: (APIParseBlock) parseBlock
        withErrorTitle: (NSString*)errorTitle
         withErrorText: (NSString*)errorText;

-(void) webServiceCall: (NSString*) method 
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
      withProgressText: (NSString*) progressText
             withFiles: (NSDictionary*) fileNames
        withParseBlock: (APIParseBlock) parseBlock;

-(void) webServiceCall: (NSString*) method 
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
      withProgressText: (NSString*) progressText
        withParseBlock: (APIParseBlock) parseBlock;

-(void) webServiceCall: (NSString*) method 
        withParameters: (NSDictionary*) parameters
          showProgress: (BOOL) willShowProgress
        withParseBlock: (APIParseBlock) parseBlock;

-(void) webServiceCall: (NSString*) method 
        withParameters: (NSDictionary*) parameters
        withParseBlock: (APIParseBlock) parseBlock;

-(void) webServiceCall: (NSString*) method
          withPostBody: (NSMutableData*) postBody
           contentType: (NSString*) contentType
        withParseBlock: (APIParseBlock) parseBlock;


+(NSString*) quoteString: (NSString*) originalString;
+(NSString*) queryString: (NSDictionary*) fixedParameters withParams:(NSDictionary*) params;

+(BOOL)isHostReachable:(NSString*)host;

+(BOOL)isInternetReachable;

@end