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

+ (MKPolygon * _Nullable)parsePolygon:(NSString * _Nonnull)wkt error:(NSError * _Nullable * _Nullable)error;
+ (NSArray<MKPolygon *> * _Nullable)parseMultiPolygon:(NSString * _Nonnull)wkt error:(NSError * _Nullable * _Nullable)error;
+ (NSArray<MKPolygon *> * _Nullable)parseAnyPolygon:(NSString * _Nonnull)wkt error:(NSError * _Nullable * _Nullable)error;

@end
