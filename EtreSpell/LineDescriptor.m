/***********************************************************************
 ** Etresoft
 ** John W. Daniel
 ** Copyright (c) 2007
 **********************************************************************/

#import "LineDescriptor.h"

@implementation LineDescriptor

// Get the line number.
- (NSUInteger) number
  {
  return myNumber;
  }
  
// Get the range.
- (NSRange) range
  {
  return myRange;
  }

// See if this line contains a given range.
- (BOOL) containsRange: (NSRange) range
  {
  return (((myRange.location) <= range.location)
    && ((myRange.location + myRange.length) >= 
      (range.location + range.length)));
  }
  
// Update the number and range.
- (void) update: (NSRange) range
  {
  ++myNumber;
  
  myRange = range;
  }
  
@end
