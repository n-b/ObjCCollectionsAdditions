Map and filter algorithms for all the Foundation collection classes, using different techniques.

Algorithms
----------
* map: perform the same operation on each item of the collection and collect the results.
* filter: collect the items from the collection that pass a test.
* one: obtain one item from the collection that passes a test. If the collection is ordered, the returned item is the first matching item.

Collections
-----------
NSArray, NSSet and NSOrdered are supported.  
The "map", "filter" and "one" algorithms are declared in protocols, which are then adopted by NSArray, NSSet and NSOrderedSet.  
Additionaly, an in-place `filter` method is added to the *Mutable* variants of the collections.  

Implementations variants
------------------------
Several coding styles are implemented
* Block-based enumeration
* Key-Value Coding
* NSInvocation-based enumeration
* Higher-Order Messaging

Note: Foundation classes already have some support for functional collection programming:
* -[NSArray valueForKey:]
* -[NSArray makeObjectsPerformSelector:<withObject:>]
* -[NSArray enumerateObjectsUsingBlock:]
* -[NSArray indexesOfObjectsPassingTest:]
* ... and some more in NSSet/ NSOrderedSet.

We propose a uniform interface for all Foundation collections (NSArray, NSSet and NSOrderedSet).

Implementation notes
--------------------
Althought the methods are declared as categories on the collections classes,
the implementations are directly on NSObject, to avoid duplicating code.

---

### Block-based enumeration
This is the most flexible (and modern) method, but not always the most concise or clear.

````
id heroes = @[batman, catwoman];
[heroes block_map:^id(id hero){ return [[hero.name componentsSeparatedByString:@" "] firstObject]; }];
[heroes block_filteredCollectionWithTest:^BOOL(id hero){ return [hero.name rangeOfString:@"Bruce Wayne"].location != NSNotFound; }];
````

---

### NSInvocation
Pass an NSInvocation to each item of the collection.

````
id heroes = @[batman, catwoman];
[heroes invoke_map:getFirstName]; // getFirstName is an NSInvocation of [Hero firstName]. "firstName" has to be added to the "Hero" class.
[heroes invoke_filteredCollectionWithTest:isBruce]; // isBruce is an NSInvocation of [Hero isNamed:@"Bruce"]. "isNamed" has to be added to the "Hero" class.
````

---

### Key-Value Coding
KVC performs automatic NSValue boxing of integral return types

````
id heroes = @[batman, catwoman];
[heroes valueForKeyPath:@"firstName"]; // "firstName" has to be added to the "Hero" class.
[heroes kvc_filteredCollectionWithValue:@"Bruce" forKey:@"firstName"]; // can't search a substring when using Key-Value coding
````

---

### Higher-order messaging
The hom_* methods return a trampoline object that forwards any sent message to its items.
Internally uses InvocationEnumeration.

````
id heroes = @[batman, catwoman];
[[heroes hom_map] firstName]; // firstName has to be added to the "Hero" class. The result has to be casted to id since the compiler thinks it returns NSString.
[[heroes hom_filteredCollectionInto:&result] isNamed:@"Bruce"]; // "isNamed" has to be added to the "Hero" class. We can't use the result as the compiler thinks it returns BOOL.
````