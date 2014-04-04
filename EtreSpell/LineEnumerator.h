/***********************************************************************
 ** Etresoft
 ** John W. Daniel
 ** Copyright (c) 2007
 **********************************************************************/

#import <Cocoa/Cocoa.h>

// Forward declaration.
@class LineDescriptor;

// An enumerator for walking through a file by line or for finding
// the line of a particular range.
@interface LineEnumerator : NSObject 
  {
  @private
  
    // The string data.
    NSString * myData;
    
    // Parameters for getLineStart:end:contentsEnd:forRange:.
    NSUInteger myParagraphStart;
    NSUInteger myParagraphEnd;
    NSUInteger myContentsEnd;
    
    // The current line descriptor.
    LineDescriptor * myCurrentLine;
  }

// Count the lines in a string.
+ (NSUInteger) countLinesInString: (NSString *) data;

// Constructor with string.
- (id) initWithString: (NSString *) data;

// Get the range for the next line.
- (LineDescriptor *) nextLine;

// Find the line for a given range.
- (LineDescriptor *) findLineForRange: (NSRange) range;

@end

@interface NSString (LineEnumeratorCategory)

// Return a new line enumerator for the string.
- (LineEnumerator *) lineEnumerator;

@end
