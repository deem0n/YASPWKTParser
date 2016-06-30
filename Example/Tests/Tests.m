//
//  YASPWKTParserTests.m
//  YASPWKTParserTests
//
//  Created by Dmitry Dorofeev on 05/22/2016.
//  Copyright (c) 2016 Dmitry Dorofeev. All rights reserved.
//



@import XCTest;

#import <MapKit/MapKit.h>
#import <YASPWKTParser/YASPWKTParser.h>

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPolygon
{
    NSString * p = @"POLYGON ((30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0))";
    NSError * error;
    
    MKPolygon * parsedPolygon = [YASPWKTParser parsePolygon: p error:&error];
    
    
    XCTAssertNotNil(parsedPolygon);
    
    p = @"POLYGON ((30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0), (20.0 30.0, 35.0 35.0, 30.0 20.0, 20.0 30.0))";
    MKPolygon * parsedPolygonWithHoles = [YASPWKTParser parsePolygon: p error: &error];
    
    XCTAssertNotNil(parsedPolygonWithHoles);
    XCTAssertNotNil(parsedPolygonWithHoles.interiorPolygons);
    XCTAssertTrue(parsedPolygonWithHoles.interiorPolygons.count == 1);
    
}

- (void)testMultiPolygon
{
    NSString * p = @"MULTIPOLYGON (((30 20, 45 40, 10 40, 30 20)),  ((15 5, 40 10, 10 20, 5 10, 15 5)))";
    NSError * error;
    
    NSArray * parsedMultiPolygon = [YASPWKTParser parseMultiPolygon: p error: &error];
    
    XCTAssertNotNil(parsedMultiPolygon);
    XCTAssertTrue(parsedMultiPolygon.count == 2);
    
    p = @"MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))";
    NSArray * parsedMultiPolygonWithHoles = [YASPWKTParser parseMultiPolygon: p error: &error];
    
    
    XCTAssertNotNil(parsedMultiPolygonWithHoles);
    XCTAssertTrue(parsedMultiPolygonWithHoles.count == 2);
    
    MKPolygon * holesPolygon = parsedMultiPolygonWithHoles[1];
    
    XCTAssertNotNil(holesPolygon.interiorPolygons);
    XCTAssertTrue(holesPolygon.interiorPolygons.count == 1);
}

- (void)testBigMultiPolygon
{
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"multipolygon1" ofType:@"wkt"];
    
    NSString* wkt = [NSString stringWithContentsOfFile:path
                                              encoding:NSUTF8StringEncoding
                                                 error:NULL];
    
    NSError * error;
    NSArray * parsedMultiPolygonWithHoles = [YASPWKTParser parseMultiPolygon: wkt error: &error];
    
    XCTAssertNotNil(parsedMultiPolygonWithHoles);
    XCTAssertTrue(parsedMultiPolygonWithHoles.count == 7);
    
    MKPolygon * holesPolygon = parsedMultiPolygonWithHoles[1];
    
    XCTAssertNotNil(holesPolygon.interiorPolygons);
    XCTAssertTrue(holesPolygon.interiorPolygons.count == 1);
    
    holesPolygon = parsedMultiPolygonWithHoles[4];
    
    XCTAssertNotNil(holesPolygon.interiorPolygons);
    XCTAssertTrue(holesPolygon.interiorPolygons.count == 4);
}

-(void) testAnyPolygon
{
    NSString * p = @"POLYGON ((30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0), (20.0 30.0, 35.0 35.0, 30.0 20.0, 20.0 30.0))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNotNil(result);
    XCTAssertTrue(result.count == 1);
    
    MKPolygon * parsedPolygonWithHoles = [result firstObject];
    
    XCTAssertNotNil(parsedPolygonWithHoles);
    XCTAssertNotNil(parsedPolygonWithHoles.interiorPolygons);
    XCTAssertTrue(parsedPolygonWithHoles.interiorPolygons.count == 1);
    
    p = @"MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))";
    NSArray * parsedMultiPolygonWithHoles = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNotNil(parsedMultiPolygonWithHoles);
    XCTAssertTrue(parsedMultiPolygonWithHoles.count == 2);
    
    MKPolygon * holesPolygon = parsedMultiPolygonWithHoles[1];
    
    XCTAssertNotNil(holesPolygon.interiorPolygons);
    XCTAssertTrue(holesPolygon.interiorPolygons.count == 1);
    
}

-(void) testFailedWrongSRID
{
    NSString * p = @"SRID=POLYGON ((30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0), (20.0 30.0, 35.0 35.0, 30.0 20.0, 20.0 30.0))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}

-(void) testFailedNoPolygonKeyword
{
    NSString * p = @"SRID=123; POLYGO ((30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0), (20.0 30.0, 35.0 35.0, 30.0 20.0, 20.0 30.0))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}


-(void) testFailedNoBracketAfterPolygon
{
    NSString * p = @"SRID=123; POLYGON 30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0), (20.0 30.0, 35.0 35.0, 30.0 20.0, 20.0 30.0))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}

-(void) testFailedNoBracketAfterMultiPolygon
{
    NSString * p = @"MULTIPOLYGON 40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}

-(void) testFailedNoBracketAfterMultiPolygon1
{
    NSString * p = @"MULTIPOLYGON (40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}


-(void) testFailedNoBracketAfterMultiPolygon2
{
    NSString * p = @"MULTIPOLYGON ((40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}

-(void) testFailedNoBracketAfterMultiPolygon3
{
    NSString * p = @"MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), (20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}

-(void) testFailedNoBracketBeforePolygon1
{
    NSString * p = @"MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), 20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}

-(void) testFailedNoBracketBeforePolygon2
{
    NSString * p = @"MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), 30 20, 20 15, 20 25, 30 20)))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}

-(void) testFailedNoClosingBracketMultipolygon
{
    NSString * p = @"MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20))";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}

-(void) testFailedNoClosingBracketPolygon
{
    NSString * p = @"POLYGON ((30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0), (20.0 30.0, 35.0 35.0, 30.0 20.0, 20.0 30.0)";
    NSError * error;
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: p error: &error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    //NSLog(@"%@", error);
    NSError * uErr = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(uErr);
    NSLog(@"%@", [uErr localizedDescription]);
}

/* YASP      10000 MacBook =  96 seconds
   WKTParser 10000 MacBook = 384 seconds
   4 times faster !!!
*/

-(void) testBigMultiPolygon_Bench
{
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"multipolygon1" ofType:@"wkt"];
    
    NSString* wkt = [NSString stringWithContentsOfFile:path
                                              encoding:NSUTF8StringEncoding
                                                 error:NULL];
    
    NSError * error;
    
    for (int i = 0; i < 10000; i++) {
        @autoreleasepool {
            NSArray * parsedMultiPolygonWithHoles = [YASPWKTParser parseMultiPolygon: wkt error: &error];
            parsedMultiPolygonWithHoles = nil;
        }
    }
    
}

@end

