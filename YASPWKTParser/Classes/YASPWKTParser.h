//
//  YASPWKTParser.h
//  Pods
//
//  Created by Дмитрий Дорофеев on 22/05/16.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface YASPWKTParser : NSObject

+ (MKPolygon *)parsePolygon:(NSString *)wkt;
+ (NSArray<MKPolygon *>*)parseMultiPolygon:(NSString *)wkt;
+ (NSArray<MKPolygon *>*)parseAnyPolygon:(NSString *)wkt;

@end
