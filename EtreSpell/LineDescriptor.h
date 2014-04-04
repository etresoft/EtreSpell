/***********************************************************************
 ** Etresoft
 ** John W. Daniel
 ** Copyright (c) 2007
 **********************************************************************/

#import <Cocoa/Cocoa.h>

// A class to describe a particular line in a file.
@interface LineDescriptor : NSObject
  {
  @private
    
    // The line number.
    NSUInteger myNumber;
    
    // The character range in the string for this line.
    NSRange myRange;
  }
  
// Get the line number.
- (NSUInteger) number;

// Get the range.
- (NSRange) range;

// See if this line contains a given range.
- (BOOL) containsRange: (NSRange) range;

// Update the number and range.
- (void) update: (NSRange) range;

@end
