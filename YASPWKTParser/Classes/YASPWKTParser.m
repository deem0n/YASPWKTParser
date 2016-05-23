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


@implementation YASPWKTParser

+ (MKPolygon *)parsePolygon:(NSString *)wkt {
    // Polygon has exterior and possibly one or more "holes" in it.
    NSScanner * scanner = [[NSScanner alloc] initWithString:wkt];
    
    // SRID=4326;MULTIPOLYGON(((136.695770298061 -15.7398658176533,136.663834263341 -15.7785714658004,
    // MULTIPOLYGON ( ((10 10, 10 20, 20 20, 20 15, 10 10)), ((60 60, 70 70, 80 60, 60 60 )) )
    
    if (nil == [self parseSRIDWith: scanner]) {
        return nil;
    }
    
    if ( ![scanner scanString:@"POLYGON" intoString:NULL] ) {
        NSLog(@"NOT A WKT format!!! No POLYGON keyword");
        return nil;
    }
    
    
    MKPolygon * polygon = [self parsePolygonCoordinatesWith: scanner];
    
    return polygon;

}

+ (NSArray<MKPolygon *>*)parseMultiPolygon:(NSString *)wkt {
    NSScanner * scanner = [[NSScanner alloc] initWithString:wkt];
    
    if (nil == [self parseSRIDWith: scanner]) {
        return nil;
    }
    
    if ( ![scanner scanString:@"MULTIPOLYGON" intoString:NULL] ) {
        NSLog(@"NOT A WKT format!!! No MULTIPOLYGON keyword");
        return nil;
    }
    
    if ( ![scanner scanString:@"(" intoString:NULL] ) {
        NSLog(@"NOT A WKT format!!! No ( after MULTIPOLYGON");
        return nil;
    };
    
    NSMutableArray * polygons = [[NSMutableArray alloc] initWithCapacity: 16];
    MKPolygon * polygon;
    while (nil != (polygon = [self parsePolygonCoordinatesWith:scanner])) {
        [polygons addObject:polygon];
        if ( ![scanner scanString:@"," intoString:NULL] ) {
            break;
        }
    };
    
    return [polygons copy];
}

+ (NSArray<MKPolygon *>*)parseAnyPolygon:(NSString *)wkt {
    NSScanner * scanner = [[NSScanner alloc] initWithString:wkt];
    
    if (nil == [self parseSRIDWith: scanner]) {
        return nil;
    }
    
    if ( [scanner scanString:@"MULTIPOLYGON" intoString:NULL] ) {
        return [self parseMultiPolygon:wkt];
    } else if ([scanner scanString:@"POLYGON" intoString:NULL]) {
        MKPolygon * polygon = [self parsePolygon:wkt];
        if (nil == polygon) {
            return nil;
        } else {
            return @[polygon];
        }
    }

}

+ (MKPolygon*) parsePolygonCoordinatesWith: (NSScanner*) scanner {
    // beware: dynamically allocated C array here!
    
    if ( ![scanner scanString:@"(" intoString:NULL] ) {
        NSLog(@"NOT A WKT format!!! Polygon coordinates do not start with (");
        return nil;
    };
    
    int arraySize = POINTS_ARRAY_SIZE;
    CLLocationCoordinate2D *points = malloc( arraySize * sizeof( CLLocationCoordinate2D ) );
    
    // beware: may return pointer to the different array !!!
    YASPWKTParsedCoordinates pointsStruct = {points, 0, arraySize};
    
    pointsStruct = [self parseWKTPointsWith: scanner usingStruct: pointsStruct];
    
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
        
        holePointsStruct = [self parseWKTPointsWith: scanner usingStruct: holePointsStruct];
        
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
        NSLog(@"NOT A WKT format!!! Polygon coordinates do not end with )");
        return nil;
    };
    
    return polygon;
}

+ (NSNumber*) parseSRIDWith: (NSScanner*) scanner {
    if ( [scanner scanString:@"SRID=" intoString:NULL] ) {
        NSUInteger srid;
        if ( ![scanner scanInteger: &srid] ) {
            NSLog(@"NOT A WKT format!!! NO SRID Value");
            return nil;
        } else {
            NSLog(@"SRID: %d", srid);
            if ( ![scanner scanString:@";" intoString:NULL] ) {
                NSLog(@"NOT A WKT format!!! SRID Value not terminated with ;");
                return nil;
            }
        }
        return [NSNumber numberWithInteger:srid];
    }
    return @0; // means no SRID part
}

+ (YASPWKTParsedCoordinates) parseWKTPointsWith: (NSScanner*) scanner usingStruct: (YASPWKTParsedCoordinates) pointsArray {
    
    
    if (![scanner scanString:@"(" intoString:NULL]) {
        pointsArray.point_count = pointsArray.array_size = 0; // means error !!!
        NSLog(@"POLYGON coordinates do not start with (");
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
                NSLog(@"POLYGON can not parse longitude value");
                return pointsArray;
            }
        }
        if( ![scanner scanFloat:&lat] ) {
            if ( [scanner scanInt:&tmp] ) {
                lat = (float)tmp;
            } else {
                pointsArray.point_count = pointsArray.array_size = 0; // means error !!!
                NSLog(@"POLYGON can not parse latitude value");
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
        NSLog(@"POLYGON coordinates do not end with )");
        return pointsArray;
    }
    
    pointsArray.point_count = i;
    return pointsArray;
}

@end
