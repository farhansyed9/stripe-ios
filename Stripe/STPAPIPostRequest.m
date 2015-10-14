//
//  STPAPIPostRequest.m
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPAPIPostRequest.h"
#import "STPAPIClient.h"
#import "STPAPIClient+Private.h"
#import "StripeError.h"

@implementation STPAPIPostRequest

+ (void)startWithAPIClient:(STPAPIClient *)apiClient
                  endpoint:(NSString *)endpoint
                  postData:(NSData *)postData
                serializer:(id<STPAPIResponseDecodable>)serializer
                completion:(void (^)(id<STPAPIResponseDecodable>, NSError *))completion {
    
    NSURL *url = [apiClient.apiURL URLByAppendingPathComponent:endpoint];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postData;
    
    [[apiClient.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable body, __unused NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *jsonDictionary = body ? [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL] : nil;
        id<STPAPIResponseDecodable> responseObject = [[serializer class] decodedObjectFromAPIResponse:jsonDictionary];
        NSError *returnedError = [STPError errorFromStripeResponse:jsonDictionary] ?: error;
        if (!responseObject && !returnedError) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: STPUnexpectedError,
                                       STPErrorMessageKey: @"The response from Stripe failed to get parsed into valid JSON."
                                       };
            returnedError = [[NSError alloc] initWithDomain:StripeDomain code:STPAPIError userInfo:userInfo];
        }
        if (returnedError) {
            [apiClient.operationQueue addOperationWithBlock:^{
                completion(nil, returnedError);
            }];
            return;
        }
        [apiClient.operationQueue addOperationWithBlock:^{
            completion(responseObject, nil);
        }];
    }] resume];
    
}

@end
