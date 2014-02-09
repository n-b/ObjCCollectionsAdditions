//
//  CollectionsAdditions-Tests.m
//
//
//  Copyright (c) 2010-2013 Nicolas Bouilleaud.
//  http://bou.io/FilteringNSArrayWithKeyValueCoding
//

#import "CollectionsAdditions.h"
@import XCTest;


// Test model and data
@interface Hero : NSObject
@property NSString * name;
@end

@implementation Hero
+(instancetype) heroWithName:(NSString*)name_
{
    Hero * hero = [self new];
    hero.name = name_;
    return hero;
}
@end

@interface HeroesTests : XCTestCase
@end

@implementation HeroesTests
{
    @protected
    Hero * batman;
    Hero * catwoman;
    Hero * spiderman;
    Hero * hulk;
    
    NSArray * _heroesArray;
    NSSet * _heroesSet;
    NSOrderedSet * _heroesOrderedSet;

    NSMutableArray * _heroesMutableArray;
    NSMutableSet * _heroesMutableSet;
    NSMutableOrderedSet * _heroesMutableOrderedSet;
}

- (void)setUp
{
    [super setUp];
    
    batman = [Hero heroWithName:@"Bruce Wayne"];
    catwoman = [Hero heroWithName:@"Selina Kyle"];
    spiderman = [Hero heroWithName:@"Peter Parker"];
    hulk = [Hero heroWithName:@"Bruce Banner"];

    _heroesArray = @[batman, catwoman, spiderman, hulk];
    _heroesSet = [NSSet setWithArray:_heroesArray];
    _heroesOrderedSet = [NSOrderedSet orderedSetWithArray:_heroesArray];
    
    _heroesMutableArray = [_heroesArray mutableCopy];
    _heroesMutableSet = [_heroesSet mutableCopy];
    _heroesMutableOrderedSet = [_heroesOrderedSet mutableCopy];
}
@end


// BlockCollecting Tests

@interface BlockCollecting_Tests : HeroesTests
@end

@implementation BlockCollecting_Tests

- (void) test_block_map
{
    id (^getFirstName)(Hero* hero) = ^id(Hero * hero) {
        return [[hero.name componentsSeparatedByString:@" "] firstObject];
    };
    
    XCTAssertEqualObjects([_heroesArray block_map:getFirstName], (@[@"Bruce", @"Selina", @"Peter", @"Bruce"]));
    XCTAssertEqualObjects([_heroesSet block_map:getFirstName], ([NSSet setWithObjects:@"Bruce", @"Selina", @"Peter",nil]));
    XCTAssertEqualObjects([_heroesOrderedSet block_map:getFirstName], ([NSOrderedSet orderedSetWithObjects:@"Bruce", @"Selina", @"Peter",nil]));
}

- (void) test_block_filter
{
    BOOL (^isBruce)(Hero* hero) = ^BOOL(Hero * hero) {
        return [hero.name rangeOfString:@"Bruce"].location != NSNotFound;
    };

    XCTAssertEqualObjects([_heroesArray block_filteredCollectionWithTest:isBruce], (@[batman, hulk]));
    XCTAssertEqualObjects([_heroesSet block_filteredCollectionWithTest:isBruce], ([NSSet setWithObjects:batman, hulk, nil]));
    XCTAssertEqualObjects([_heroesOrderedSet block_filteredCollectionWithTest:isBruce], ([NSOrderedSet orderedSetWithObjects:batman, hulk, nil]));
}

- (void) test_block_filter_mutable
{
    BOOL (^isBruce)(Hero* hero) = ^BOOL(Hero * hero) {
        return [hero.name rangeOfString:@"Bruce"].location != NSNotFound;
    };

    [_heroesMutableArray block_filterWithTest:isBruce];
    [_heroesMutableSet block_filterWithTest:isBruce];
    [_heroesMutableOrderedSet block_filterWithTest:isBruce];
    
    XCTAssertEqualObjects(_heroesMutableArray, (@[batman, hulk]));
    XCTAssertEqualObjects(_heroesMutableSet, ([NSSet setWithObjects:batman, hulk, nil]));
    XCTAssertEqualObjects(_heroesMutableOrderedSet, ([NSOrderedSet orderedSetWithObjects:batman, hulk, nil]));
}

- (void) test_block_one
{
    BOOL (^isBruce)(Hero* hero) = ^BOOL(Hero * hero) {
        return [hero.name rangeOfString:@"Bruce"].location != NSNotFound;
    };
    
    XCTAssertEqualObjects([_heroesArray block_oneObjectPassingTest:isBruce], batman);
    Hero * oneObjectFromSet = [_heroesSet block_oneObjectPassingTest:isBruce];
    XCTAssert(oneObjectFromSet==batman||oneObjectFromSet==hulk);
    XCTAssertEqualObjects([_heroesOrderedSet block_oneObjectPassingTest:isBruce], batman);
}

@end


// KVCCollecting Tests

@interface KVCCollecting_Tests : HeroesTests
@end

@implementation Hero (KVCCollecting_Helper)
- (NSString*) firstName
{
    return [[self.name componentsSeparatedByString:@" "] firstObject];
}
@end

@implementation KVCCollecting_Tests

- (void) test_kvc_map
{
    XCTAssertEqualObjects([_heroesArray valueForKeyPath:@"firstName"], (@[@"Bruce", @"Selina", @"Peter", @"Bruce"]));
    XCTAssertEqualObjects([_heroesSet valueForKeyPath:@"firstName"], ([NSSet setWithObjects:@"Bruce", @"Selina", @"Peter",nil]));
    XCTAssertEqualObjects([_heroesOrderedSet valueForKeyPath:@"firstName"], ([NSOrderedSet orderedSetWithObjects:@"Bruce", @"Selina", @"Peter",nil]));
}

- (void) test_kvc_filter
{
    XCTAssertEqualObjects([_heroesArray kvc_filteredCollectionWithValue:@"Bruce" forKeyPath:@"firstName"], (@[batman, hulk]));
    XCTAssertEqualObjects([_heroesSet kvc_filteredCollectionWithValue:@"Bruce" forKeyPath:@"firstName"], ([NSSet setWithObjects:batman, hulk,nil]));
    XCTAssertEqualObjects([_heroesOrderedSet kvc_filteredCollectionWithValue:@"Bruce" forKeyPath:@"firstName"], ([NSOrderedSet orderedSetWithObjects:batman, hulk,nil]));
}

- (void) test_kvc_filter_mutable
{
    [_heroesMutableArray kvc_filterWithValue:@"Bruce" forKeyPath:@"firstName"];
    [_heroesMutableSet kvc_filterWithValue:@"Bruce" forKeyPath:@"firstName"];
    [_heroesMutableOrderedSet kvc_filterWithValue:@"Bruce" forKeyPath:@"firstName"];
    
    XCTAssertEqualObjects(_heroesMutableArray, (@[batman, hulk]));
    XCTAssertEqualObjects(_heroesMutableSet, ([NSSet setWithObjects:batman, hulk, nil]));
    XCTAssertEqualObjects(_heroesMutableOrderedSet, ([NSOrderedSet orderedSetWithObjects:batman, hulk, nil]));
}

- (void) test_kvc_one
{
    XCTAssertEqualObjects([_heroesArray kvc_oneObjectWithValue:@"Bruce" forKeyPath:@"firstName"], batman);
    Hero * oneObjectFromSet = [_heroesSet kvc_oneObjectWithValue:@"Bruce" forKeyPath:@"firstName"];
    XCTAssert(oneObjectFromSet==batman||oneObjectFromSet==hulk);
    XCTAssertEqualObjects([_heroesOrderedSet kvc_oneObjectWithValue:@"Bruce" forKeyPath:@"firstName"], batman);
}

@end


// InvocationCollecting Tests

@implementation Hero (InvocationCollecting_Helper)
- (BOOL) isNamed:(NSString*)searchedName
{
    return [self.name rangeOfString:searchedName].location != NSNotFound;;
}
@end

@interface InvocationCollecting_Tests : HeroesTests
@end

@implementation InvocationCollecting_Tests

- (void) test_invocation_map
{
    NSInvocation * getFirstName = [NSInvocation invocationWithMethodSignature:[Hero instanceMethodSignatureForSelector:@selector(firstName)]];
    getFirstName.selector = @selector(firstName);
    
    XCTAssertEqualObjects([_heroesArray invoke_map:getFirstName], (@[@"Bruce", @"Selina", @"Peter", @"Bruce"]));
    XCTAssertEqualObjects([_heroesSet invoke_map:getFirstName], ([NSSet setWithObjects:@"Bruce", @"Selina", @"Peter",nil]));
    XCTAssertEqualObjects([_heroesOrderedSet invoke_map:getFirstName], ([NSOrderedSet orderedSetWithObjects:@"Bruce", @"Selina", @"Peter",nil]));
}

- (void) test_invocation_filter
{
    NSInvocation * isBruce = [NSInvocation invocationWithMethodSignature:[Hero instanceMethodSignatureForSelector:@selector(isNamed:)]];
    isBruce.selector = @selector(isNamed:);
    NSString * searchedName = @"Bruce";
    [isBruce setArgument:&searchedName atIndex:2];

    XCTAssertEqualObjects([_heroesArray invoke_filteredCollectionWithTest:isBruce], (@[batman, hulk]));
    XCTAssertEqualObjects([_heroesSet invoke_filteredCollectionWithTest:isBruce], ([NSSet setWithObjects:batman, hulk,nil]));
    XCTAssertEqualObjects([_heroesOrderedSet invoke_filteredCollectionWithTest:isBruce], ([NSOrderedSet orderedSetWithObjects:batman, hulk,nil]));
}

- (void) test_invocation_filter_mutable
{
    NSInvocation * isBruce = [NSInvocation invocationWithMethodSignature:[Hero instanceMethodSignatureForSelector:@selector(isNamed:)]];
    isBruce.selector = @selector(isNamed:);
    NSString * searchedName = @"Bruce";
    [isBruce setArgument:&searchedName atIndex:2];
    
    [_heroesMutableArray invoke_filterWithTest:isBruce];
    [_heroesMutableSet invoke_filterWithTest:isBruce];
    [_heroesMutableOrderedSet invoke_filterWithTest:isBruce];
    
    XCTAssertEqualObjects(_heroesMutableArray, (@[batman, hulk]));
    XCTAssertEqualObjects(_heroesMutableSet, ([NSSet setWithObjects:batman, hulk, nil]));
    XCTAssertEqualObjects(_heroesMutableOrderedSet, ([NSOrderedSet orderedSetWithObjects:batman, hulk, nil]));
}

- (void) test_invocation_one
{
    NSInvocation * isBruce = [NSInvocation invocationWithMethodSignature:[Hero instanceMethodSignatureForSelector:@selector(isNamed:)]];
    isBruce.selector = @selector(isNamed:);
    NSString * searchedName = @"Bruce";
    [isBruce setArgument:&searchedName atIndex:2];

    XCTAssertEqualObjects([_heroesArray invoke_oneObjectPassingTest:isBruce], batman);
    Hero * oneObjectFromSet = [_heroesSet invoke_oneObjectPassingTest:isBruce];
    XCTAssert(oneObjectFromSet==batman||oneObjectFromSet==hulk);
    XCTAssertEqualObjects([_heroesOrderedSet invoke_oneObjectPassingTest:isBruce], batman);
}

@end

// Higher-order messaging Tests

@interface HOMCollecting_Tests : HeroesTests
@end

@implementation HOMCollecting_Tests

- (void) test_hom_map
{
    XCTAssertEqualObjects([[_heroesArray hom_map] firstName], (@[@"Bruce", @"Selina", @"Peter", @"Bruce"]));
    XCTAssertEqualObjects([[_heroesSet hom_map] firstName], ([NSSet setWithObjects:@"Bruce", @"Selina", @"Peter",nil]));
    XCTAssertEqualObjects([[_heroesOrderedSet hom_map] firstName], ([NSOrderedSet orderedSetWithObjects:@"Bruce", @"Selina", @"Peter",nil]));
}

- (void) test_hom_filter
{
    __autoreleasing id result;
    XCTAssertEqualObjects(([[_heroesArray hom_filteredCollectionInto:&result] isNamed:@"Bruce"], result), (@[batman, hulk]));
    XCTAssertEqualObjects(([[_heroesSet hom_filteredCollectionInto:&result] isNamed:@"Bruce"], result), ([NSSet setWithObjects:batman, hulk,nil]));
    XCTAssertEqualObjects(([[_heroesOrderedSet hom_filteredCollectionInto:&result] isNamed:@"Bruce"], result), ([NSOrderedSet orderedSetWithObjects:batman, hulk,nil]));
}

- (void) test_hom_filter_mutable
{
    [[_heroesMutableArray hom_filter] isNamed:@"Bruce"];
    [[_heroesMutableSet hom_filter] isNamed:@"Bruce"];
    [[_heroesMutableOrderedSet hom_filter] isNamed:@"Bruce"];
    
    XCTAssertEqualObjects(_heroesMutableArray, (@[batman, hulk]));
    XCTAssertEqualObjects(_heroesMutableSet, ([NSSet setWithObjects:batman, hulk, nil]));
    XCTAssertEqualObjects(_heroesMutableOrderedSet, ([NSOrderedSet orderedSetWithObjects:batman, hulk, nil]));
}

- (void) test_hom_one
{
    __autoreleasing id result;

    [[_heroesArray hom_oneObjectInto:&result] isNamed:@"Bruce"];
    XCTAssertEqualObjects(result, batman);
    [[_heroesSet hom_oneObjectInto:&result] isNamed:@"Bruce"];
    XCTAssert(result==batman||result==hulk);
    [[_heroesOrderedSet hom_oneObjectInto:&result] isNamed:@"Bruce"];
    XCTAssertEqualObjects(result, batman);
}

@end

