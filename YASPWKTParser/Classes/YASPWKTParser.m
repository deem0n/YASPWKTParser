//
//  YASPWKTParser.m
//  Pods
//
//  Created by Дмитрий Дорофеев on 22/05/16.
//
//

#import "YASPWKTParser.h"

#define POINTS_ARRAY_SIZE 256

struct YASPWKTParsedCoordinatesStruct {
    CLLocationCoordinate2D *points;
    int point_count;
    int array_size;
};
typedef struct YASPWKTParsedCoordinatesStruct YASPWKTParsedCoordinates;


static NSString * YASPWKTunderlyingErrorDomain = @"YASPWKTTextScanner";
static NSString * YASPWKTerrorDomain = @"YASPWKTParser";

@implementation YASPWKTParser

+ (MKPolygon * _Nullable)parsePolygon:(NSString * _Nonnull)wkt error:(NSError * _Nullable * _Nullable)error {
    // Polygon has exterior and possibly one or more "holes" in it.
    NSScanner * scanner = [[NSScanner alloc] initWithString:wkt];
    
    if (nil == [self parseSRIDWith: scanner error:error]) {
        return nil;
    }
    
    if ( [scanner scanString:@"POLYGON" intoString:NULL] == NO) {
        NSLog(@"NOT A WKT format!!! No POLYGON keyword");
        return nil;
    }
    
    
    return [self parsePolygonCoordinatesWith:scanner error:error];

}

+ (NSArray<MKPolygon *> * _Nullable)parseMultiPolygon:(NSString * _Nonnull)wkt error:(NSError * _Nullable * _Nullable)error {
    NSScanner * scanner = [[NSScanner alloc] initWithString:wkt];
    
    if (nil == [self parseSRIDWith: scanner error:error]) {
        return nil;
    }
    
    if ( ![scanner scanString:@"MULTIPOLYGON" intoString:NULL] ) {
        NSLog(@"NOT A WKT format!!! No MULTIPOLYGON keyword");
        return nil;
    }
    
    return [self continueMultiPolygonParsingWith:scanner wkt:wkt error:error];
    
}

+ (NSArray<MKPolygon *> * _Nullable)parseAnyPolygon:(NSString * _Nonnull)wkt error:(NSError * _Nullable * _Nullable)error {
    NSScanner * scanner = [[NSScanner alloc] initWithString:wkt];
    
    if (nil == [self parseSRIDWith: scanner error:error]) {
        return nil;
    }
    
    if ( [scanner scanString:@"MULTIPOLYGON" intoString:NULL] ) {
        return [self continueMultiPolygonParsingWith:scanner wkt:wkt error:error];
    } else if ([scanner scanString:@"POLYGON" intoString:NULL]) {
        MKPolygon * polygon = [self parsePolygonCoordinatesWith:scanner error:error];
        if (nil != polygon) {
            return @[polygon];
        } else {
            return nil;
        }
    } else {
        *error = [self errorWithCode:3 message:@"Not a WKT format! Missed POLYGON/MULTIPOLYGON keyword" scanner:scanner];
        return nil;
    }

}

+ (NSArray<MKPolygon *>*)continueMultiPolygonParsingWith: (NSScanner*)scanner wkt:(NSString *)wkt error:(NSError * _Nullable *)error {
 
    if ( ![scanner scanString:@"(" intoString:NULL] ) {
        *error = [self errorWithCode:4 message:@"NOT A WKT format!!! No ( after MULTIPOLYGON" scanner: scanner];
        return nil;
    };
    
    NSMutableArray * polygons = [[NSMutableArray alloc] initWithCapacity:16];
    MKPolygon * polygon;
    while (nil != (polygon = [self parsePolygonCoordinatesWith:scanner error:error])) {
        [polygons addObject:polygon];
        if ( ![scanner scanString:@"," intoString:NULL] ) {
            break;
        }
    };
    
    if (nil == *error) {
        if ( ![scanner scanString:@")" intoString:NULL] ) {
            *error = [self errorWithCode:15 message:@"NOT A WKT format!!! MULTIPLOLYGON do not end with )" scanner: scanner];
            return nil;
        };
        return [polygons copy];
    } else {
        return nil;
    }
}


+ (MKPolygon*) parsePolygonCoordinatesWith: (NSScanner*)scanner error:(NSError * _Nullable * _Nullable)error {
    // beware: dynamically allocated C array here!
    
    if ( ![scanner scanString:@"(" intoString:NULL] ) {
        *error = [self errorWithCode:5 message:@"NOT A WKT format!!! Polygon coordinates do not start with (" scanner: scanner];
        return nil;
    };
    
    int arraySize = POINTS_ARRAY_SIZE;
    CLLocationCoordinate2D *points = malloc( arraySize * sizeof( CLLocationCoordinate2D ) );
    
    // beware: may return pointer to the different array !!!
    YASPWKTParsedCoordinates pointsStruct = {points, 0, arraySize};
    
    pointsStruct = [self parseWKTPointsWith: scanner usingStruct: pointsStruct error: error];
    
    if (pointsStruct.array_size == 0) {
        NSLog(@"Can not parse coordinates for the WKT polygon.");
        free(pointsStruct.points);
        return nil;
    }
    
    NSMutableArray * holes = [[NSMutableArray alloc] initWithCapacity:4];
    
    while ([scanner scanString:@"," intoString:NULL]) {
        // we should try and parse any HOLES for the polygon...
        CLLocationCoordinate2D *holePoints = malloc( arraySize * sizeof( CLLocationCoordinate2D ) );
        
        // beware: may return pointer to the different array !!!
        YASPWKTParsedCoordinates holePointsStruct = {holePoints, 0, arraySize};
        
        holePointsStruct = [self parseWKTPointsWith: scanner usingStruct: holePointsStruct error: error];
        
        if (holePointsStruct.array_size == 0) {
            NSLog(@"Can not parse coordinates for the hole WKT polygon.");
            free(pointsStruct.points);
            free(holePointsStruct.points);
            return nil;
        }
        
        MKPolygon * hole = [MKPolygon polygonWithCoordinates:holePointsStruct.points count: holePointsStruct.point_count];
        
        free(holePointsStruct.points);
        
        [holes addObject:hole];
    }
    
    MKPolygon * polygon;
    polygon = [MKPolygon polygonWithCoordinates:pointsStruct.points count: pointsStruct.point_count interiorPolygons: holes];
    free(pointsStruct.points);
    
    if ( ![scanner scanString:@")" intoString:NULL] ) {
        *error = [self errorWithCode:10 message:@"NOT A WKT format!!! Polygon coordinates do not end with )" scanner: scanner];
        return nil;
    };
    
    return polygon;
}

+ (NSNumber*) parseSRIDWith:(NSScanner*) scanner error:(NSError * _Nullable * _Nullable)error {
    if ( [scanner scanString:@"SRID=" intoString:NULL] ) {
        NSUInteger srid;
        if ( [scanner scanInteger: &srid] == NO ) {
            *error = [self errorWithCode:1 message:@"Not a WKT format! NO SRID Value" scanner: scanner];
            return nil;
        } else {
            if ( [scanner scanString:@";" intoString:NULL] == NO ) {
                *error = [self errorWithCode:2 message:@"Not a WKT format! SRID Value not terminated with ;" scanner: scanner];
                return nil;
            }
        }
        return [NSNumber numberWithInteger:srid];
    }
    return @0; // means no SRID part
}

+ (YASPWKTParsedCoordinates) parseWKTPointsWith: (NSScanner*) scanner usingStruct: (YASPWKTParsedCoordinates) pointsArray error:(NSError * _Nullable * _Nullable)error{
    
    
    if (![scanner scanString:@"(" intoString:NULL]) {
        pointsArray.point_count = pointsArray.array_size = 0; // means error !!!
        *error = [self errorWithCode:6 message:@"POLYGON coordinates do not start with (" scanner: scanner];
        return pointsArray;
    }
    
    int i = 0;
    do {
        float lat, lon;
        int tmp;
        // FIXME = better error handling !!!
        if( ![scanner scanFloat:&lon] ) {
            if ( [scanner scanInt:&tmp] ) {
                lon = (float)tmp;
            } else {
                pointsArray.point_count = pointsArray.array_size = 0; // means error !!!
                *error = [self errorWithCode:7 message:@"POLYGON can not parse longitude value" scanner: scanner];
                return pointsArray;
            }
        }
        if( ![scanner scanFloat:&lat] ) {
            if ( [scanner scanInt:&tmp] ) {
                lat = (float)tmp;
            } else {
                pointsArray.point_count = pointsArray.array_size = 0; // means error !!!
                *error = [self errorWithCode:8 message:@"POLYGON can not parse latitude value" scanner: scanner];
                return pointsArray;
            }
        }
        
        if ( (i+1) == pointsArray.array_size) {
            // we need more space for our data
            pointsArray.array_size *= 2;
            pointsArray.points = realloc(pointsArray.points, pointsArray.array_size * sizeof( CLLocationCoordinate2D ));
        }
        pointsArray.points[i++] = CLLocationCoordinate2DMake(lat, lon);
        
    } while ([scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@","] intoString:NULL]);
    
    if ( ![scanner scanString:@")" intoString:NULL] ) {
        pointsArray.point_count = pointsArray.array_size = 0; // means error !!!
        *error = [self errorWithCode:9 message:@"POLYGON coordinates do not end with )" scanner: scanner];
        return pointsArray;
    }
    
    pointsArray.point_count = i;
    return pointsArray;
}

+ (NSError*) errorWithCode:(NSInteger)code message:(NSString *)message scanner:(NSScanner *)scanner {
    // generate underlying error with scanner...
    NSUInteger start,end;
    start = end = scanner.scanLocation;
    if (start < 40) {
        start = 0;
    } else {
        start-=40;
    }
    
    if ( scanner.string.length - end > 40 ) {
        end += 40;
    } else {
        end = scanner.string.length;
    }
    
    NSString * wktPart = [scanner.string substringWithRange: NSMakeRange(start, end-start)];
    NSString * scannerPositionPointer = [@"" stringByPaddingToLength:(scanner.scanLocation - start)
                                                          withString:@"∿"
                                                     startingAtIndex:0];
    
    NSString * parserError = [NSString stringWithFormat:
                              @"Parse error in WKT at symbol %d\n"
                              @"%@\n"
                              @"%@💣",
                              1+scanner.scanLocation,
                              wktPart,
                              scannerPositionPointer
                              ];
    
    NSError * underlyingError = [NSError errorWithDomain:YASPWKTunderlyingErrorDomain
                                                    code:code
                                                userInfo:@{
                                                           NSLocalizedDescriptionKey : parserError
                                                           }
                                 ];
    
    return [NSError errorWithDomain:YASPWKTerrorDomain
                               code:code
                           userInfo:@{
                                      NSLocalizedDescriptionKey : message,
                                      NSUnderlyingErrorKey : underlyingError
                                      }
            ];
}

@end
