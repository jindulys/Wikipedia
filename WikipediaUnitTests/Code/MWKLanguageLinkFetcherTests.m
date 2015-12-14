//
//  MWKLanguageLinkFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFAsyncTestCase.h"
#import "MWKLanguageLinkFetcher.h"
#import "WMFNetworkUtilities.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

#define MOCKITO_SHORTHAND 1
#import "OCMockito.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKLanguageLinkFetcherTests : WMFAsyncTestCase
@property (nonatomic, strong) AFHTTPRequestOperationManager* mockManager;
@property (nonatomic, strong) id<FetchFinishedDelegate> mockDelegate;
@property (nonatomic, strong) MWKLanguageLinkFetcher* fetcher;
@end

@implementation MWKLanguageLinkFetcherTests

- (void)setUp {
    self.mockDelegate = mockProtocol(@protocol(FetchFinishedDelegate));
    self.mockManager  = MKTMock([AFHTTPRequestOperationManager class]);
    self.fetcher      = [[MWKLanguageLinkFetcher alloc] initWithManager:self.mockManager
                                                               delegate:self.mockDelegate];
    [super setUp];
}

- (void)testFetchingNilTitle {
    PushExpectation();
    [self.fetcher fetchLanguageLinksForTitle:nil success:^(NSArray* langLinks) {
        XCTFail(@"Expected nil title to result in failure.");
    } failure:^(NSError* error) {
        XCTAssertEqual(error.code, WMFNetworkingError_InvalidParameters);
        [self popExpectationAfter:nil];
    }];
    WaitForExpectations();
    [[MKTVerify(self.mockDelegate) withMatcher:equalTo(@(FETCH_FINAL_STATUS_FAILED))
                                   forArgument:2]
     fetchFinished:self.fetcher
       fetchedData:nil
            status:0
             error:[NSError errorWithDomain:WMFNetworkingErrorDomain code:WMFNetworkingError_InvalidParameters userInfo:nil]];
}

- (void)testFetchingEmptyTitle {
    MWKTitle* mockTitle = MKTMock([MWKTitle class]);
    [MKTGiven([mockTitle text]) willReturn:@""];

    PushExpectation();
    [self.fetcher fetchLanguageLinksForTitle:mockTitle success:^(NSArray* langLinks) {
        XCTFail(@"Expected empty title to result in failure.");
    } failure:^(NSError* error) {
        XCTAssertEqual(error.code, WMFNetworkingError_InvalidParameters);
        [self popExpectationAfter:nil];
    }];
    WaitForExpectations();
    [[MKTVerify(self.mockDelegate) withMatcher:equalTo(@(FETCH_FINAL_STATUS_FAILED))
                                   forArgument:2]
     fetchFinished:self.fetcher
       fetchedData:nil
            status:0
             error:[NSError errorWithDomain:WMFNetworkingErrorDomain code:WMFNetworkingError_InvalidParameters userInfo:nil]];
}

@end
