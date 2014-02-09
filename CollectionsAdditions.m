//
//  CollectionsAdditions.m
//
//
//  Copyright (c) 2010-2013 Nicolas Bouilleaud.
//  http://bou.io/FilteringNSArrayWithKeyValueCoding
//

#import "CollectionsAdditions.h"
#import "objc/message.h"
#import "objc/runtime.h"

// Helpers

// We're going to implement all the NSArray/NSSet/NSOrderedSet methods all at once in an NSObject category.
// To do this, we have to convince the compiler that NSObject implements all these base methods.
@protocol Collecting_helpers
- (id) col_emptyMutableContainer;	// return a mutable, empty collection of the same type
- (id) col_immutableCopy;			// return a non-mutable copy of self
- (id) col_one;						// return one object from the receiver
@end
@interface NSObject (Collecting_helpers) <Collecting_helpers, NSFastEnumeration>
@end

@interface NSObject (MutableCollecting_helpers)
- (void) removeObject:(id)object_;	// remove one object from the receiver
@end

@implementation NSArray (Collecting_helpers)
- (id) col_emptyMutableContainer { return [NSMutableArray new]; }
- (id) col_immutableCopy { return [[self class] arrayWithArray:self]; }
- (id) col_one { return [self firstObject]; }
@end

@implementation NSSet (Collecting_helpers)
- (id) col_emptyMutableContainer { return [NSMutableSet new]; }
- (id) col_immutableCopy { return [[self class] setWithSet:self]; }
- (id) col_one { return [self anyObject]; }
@end

@implementation NSOrderedSet (Collecting_helpers)
- (id) col_emptyMutableContainer { return [NSMutableOrderedSet new]; }
- (id) col_immutableCopy { return [[self class] orderedSetWithOrderedSet:self]; }
- (id) col_one { return [self firstObject]; }
@end

// Block-based enumeration

@implementation NSObject (BlockCollecting)
- (instancetype) block_map:(id(^)(id obj))block
{
    id values = [self col_emptyMutableContainer];
    for (id object in self) {
        id value = block(object);
        if (value) {
            [values addObject:value];
        }
    }
    return [values col_immutableCopy];
}
- (instancetype) block_filteredCollectionWithTest:(BOOL (^)(id))block
{
    id objects = [self col_emptyMutableContainer];
    for (id obj in self) {
        if (block(obj)) {
            [objects addObject:obj];
        }
    }
    return [objects col_immutableCopy];
}
- (id) block_oneObjectPassingTest:(BOOL (^)(id))block
{
    for (id obj in self) {
        if (block(obj)) {
            return obj;
        }
    }
    return nil;
}
- (void) block_filterWithTest:(BOOL (^)(id))block
{
    for (id obj in [self copy]) {
        if (!block(obj)) {
            [self removeObject:obj];
        }
    }
}
@end

// Key-Value Coding

@implementation NSObject (KVCCollecting_implementation)
- (instancetype) kvc_filteredCollectionWithValue:(id)value forKeyPath:(NSString*)key
{
	id objects = [self col_emptyMutableContainer];
	
	for (id object in self) {
		if( [[object valueForKeyPath:key] isEqual:value] ) {
			[objects addObject:object];
        }
	}
	
	return [objects col_immutableCopy];
}
- (id) kvc_oneObjectWithValue:(id)value forKeyPath:(NSString*)key
{
	for (id object in self) {
		if( [[object valueForKeyPath:key] isEqual:value] )
			return object;
	}
	return nil;
}
- (void) kvc_filterWithValue:(id)value forKeyPath:(NSString*)key
{
	for (id object in [self copy]) {
		if( ![[object valueForKeyPath:key] isEqual:value] ) {
			[self removeObject:object];
        }
	}
}
@end

// NSInvocation

@implementation NSObject (InvocationCollecting_implementation)
- (instancetype) invoke_map:(NSInvocation*)invocation_
{
    NSParameterAssert(0==strcmp([[invocation_ methodSignature] methodReturnType],@encode(id)) ||
                      0==strcmp([[invocation_ methodSignature] methodReturnType],@encode(void)));
    
    BOOL returnsVoid = 0==strcmp([[invocation_ methodSignature] methodReturnType],@encode(void));
    id values = [self col_emptyMutableContainer];
    for (id obj in self) {
        [invocation_ invokeWithTarget:obj];
        if (!returnsVoid) {
            __unsafe_unretained id value;
            [invocation_ getReturnValue:&value];
            [values addObject:value];
        }
    }
    if (!returnsVoid) {
        values = [values col_immutableCopy];
        return values;
    }
    return nil;
}
- (instancetype) invoke_filteredCollectionWithTest:(NSInvocation*)invocation_
{
    NSParameterAssert(0==strcmp([[invocation_ methodSignature] methodReturnType],@encode(BOOL)));
    id objects = [self col_emptyMutableContainer];
    for (id obj in self) {
        [invocation_ invokeWithTarget:obj];
        BOOL value;
        [invocation_ getReturnValue:&value];
        if(value) {
            [objects addObject:obj];
        }
    }
    return objects;
}
- (id) invoke_oneObjectPassingTest:(NSInvocation*)invocation_
{
    NSParameterAssert(0==strcmp([[invocation_ methodSignature] methodReturnType],@encode(BOOL)));
    for (id obj in self) {
        [invocation_ invokeWithTarget:obj];
        BOOL value;
        [invocation_ getReturnValue:&value];
        if(value) {
            return obj;
        }
    }
    return nil;
}
- (void) invoke_filterWithTest:(NSInvocation*)invocation_
{
    NSParameterAssert(0==strcmp([[invocation_ methodSignature] methodReturnType],@encode(BOOL)));
    for (id obj in [self copy]) {
        [invocation_ invokeWithTarget:obj];
        BOOL value;
        [invocation_ getReturnValue:&value];
        if(!value) {
            [self removeObject:obj];
        }
    }
}
@end

// Higher-order messaging

@interface HOMCollectionTrampoline : NSProxy
@end
typedef NS_ENUM(NSInteger, HOMTrampolineMode) {
    HOMTrampolineMap,
    HOMTrampolineFiltered,
    HOMTrampolineOne,
    HOMTrampolineFilter,
};
@implementation HOMCollectionTrampoline {
    id _collection;
    HOMTrampolineMode _mode;
    __autoreleasing id * _result;
}
- (id) initWithCollection:(id)collection_ mode:(int)mode_ result:(id*)result_
{
    _collection = collection_;
    _mode = mode_;
    _result = result_;
    return self;
}
- (id)methodSignatureForSelector:(SEL)sel_
{
    return [[_collection col_one] methodSignatureForSelector:sel_];
}
- (void)forwardInvocation:(NSInvocation*)invocation_
{
    switch (_mode) {
        case HOMTrampolineMap: {
            id res = [_collection invoke_map:invocation_];
            if (res) {
                [invocation_ setReturnValue:&res];
            }
            return;
        }
        case HOMTrampolineFiltered:
            * _result = [_collection invoke_filteredCollectionWithTest:invocation_];
            return;
        case HOMTrampolineOne:
            * _result = [_collection invoke_oneObjectPassingTest:invocation_];
            return;
        case HOMTrampolineFilter:
            [_collection invoke_filterWithTest:invocation_];
            return;
            
    }
}
@end

@implementation NSObject (HOMCollecting_implementation)
- (id) hom_map
{
    return [[HOMCollectionTrampoline alloc] initWithCollection:self mode:HOMTrampolineMap result:NULL];
}
- (id) hom_filteredCollectionInto:(id*)result_
{
    return [[HOMCollectionTrampoline alloc] initWithCollection:self mode:HOMTrampolineFiltered result:result_];
}
- (id) hom_oneObjectInto:(id*)result_
{
    return [[HOMCollectionTrampoline alloc] initWithCollection:self mode:HOMTrampolineOne result:result_];
}
- (id) hom_filter
{
    return [[HOMCollectionTrampoline alloc] initWithCollection:self mode:HOMTrampolineFilter result:NULL];
}
@end
