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
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
    MKPolygon * parsedPolygon = [YASPWKTParser parsePolygon: @"POLYGON ((30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0))"];
    
    
    XCTAssertNotNil(parsedPolygon);
    
    MKPolygon * parsedPolygonWithHoles = [YASPWKTParser parsePolygon: @"POLYGON ((30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0), (20.0 30.0, 35.0 35.0, 30.0 20.0, 20.0 30.0))"];
    
    XCTAssertNotNil(parsedPolygonWithHoles);
    XCTAssertNotNil(parsedPolygonWithHoles.interiorPolygons);
    XCTAssertTrue(parsedPolygonWithHoles.interiorPolygons.count == 1);
}

- (void)testMultiPolygon
{
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
    NSArray * parsedMultiPolygon = [YASPWKTParser parseMultiPolygon: @"MULTIPOLYGON (((30 20, 45 40, 10 40, 30 20)),  ((15 5, 40 10, 10 20, 5 10, 15 5)))"];
    
    XCTAssertNotNil(parsedMultiPolygon);
    XCTAssertTrue(parsedMultiPolygon.count == 2);
    
    NSArray * parsedMultiPolygonWithHoles = [YASPWKTParser parseMultiPolygon: @"MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))"];
    
    
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
    
    NSArray * parsedMultiPolygonWithHoles = [YASPWKTParser parseMultiPolygon: wkt];
    
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
    
    NSArray * result = [YASPWKTParser parseAnyPolygon: @"POLYGON ((30.0 10.0, 40.0 40.0, 20.0 40.0, 10.0 20.0, 30.0 10.0), (20.0 30.0, 35.0 35.0, 30.0 20.0, 20.0 30.0))"];
    
    XCTAssertNotNil(result);
    XCTAssertTrue(result.count == 1);
    
    MKPolygon * parsedPolygonWithHoles = [result firstObject];
    
    XCTAssertNotNil(parsedPolygonWithHoles);
    XCTAssertNotNil(parsedPolygonWithHoles.interiorPolygons);
    XCTAssertTrue(parsedPolygonWithHoles.interiorPolygons.count == 1);
    
    
    NSArray * parsedMultiPolygonWithHoles = [YASPWKTParser parseAnyPolygon: @"MULTIPOLYGON (((40 40, 20 45, 45 30, 40 40)), ((20 35, 10 30, 10 10, 30 5, 45 20, 20 35), (30 20, 20 15, 20 25, 30 20)))"];
    
    
    XCTAssertNotNil(parsedMultiPolygonWithHoles);
    XCTAssertTrue(parsedMultiPolygonWithHoles.count == 2);
    
    MKPolygon * holesPolygon = parsedMultiPolygonWithHoles[1];
    
    XCTAssertNotNil(holesPolygon.interiorPolygons);
    XCTAssertTrue(holesPolygon.interiorPolygons.count == 1);
    
}


@end

