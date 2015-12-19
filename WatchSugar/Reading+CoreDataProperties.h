//
//  Reading+CoreDataProperties.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/19/15.
//  Copyright © 2015 Flairify. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Reading.h"

NS_ASSUME_NONNULL_BEGIN

@interface Reading (CoreDataProperties)

@property (nonatomic) int64_t timestamp;
@property (nonatomic) int32_t trend;
@property (nonatomic) int32_t value;

@end

NS_ASSUME_NONNULL_END
