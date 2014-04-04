/***********************************************************************
 ** Etresoft
 ** John W. Daniel
 ** Copyright (c) 2007
 **********************************************************************/

#import "LineEnumerator.h"
#import "LineDescriptor.h"

@implementation LineEnumerator

// Count the lines in a string.
+ (NSUInteger) countLinesInString: (NSString *) data
  {
  LineEnumerator * enumerator = 
    [[LineEnumerator alloc] initWithString: data];
    
  int lines = 0; 
  
  while([enumerator nextLine])
    ++lines;
    
  return lines;
  }
  
// Constructor with string.
- (id) initWithString: (NSString *) data
  {
  if(self = [super init])
    {
    myData = data;
    myCurrentLine = [[LineDescriptor alloc] init];
    }
    
  return self;
  }

// Get the range for the next line.
- (LineDescriptor *) nextLine
  {
  if(myParagraphEnd >= [myData length])
    return nil;

  [myData getParagraphStart: & myParagraphStart end: & myParagraphEnd
    contentsEnd: & myContentsEnd 
    forRange: NSMakeRange(myParagraphEnd, 0)];
    
  [myCurrentLine 
    update: 
      NSMakeRange(myParagraphStart, myContentsEnd - myParagraphStart)];
      
  return myCurrentLine;
  }

// Find the line for a given range.
- (LineDescriptor *) findLineForRange: (NSRange) range
  {
  if([myCurrentLine containsRange: range])
    return myCurrentLine;
    
  do
    {
    if(![self nextLine])
      return nil;
    }
  while(![myCurrentLine containsRange: range]);
  
  return myCurrentLine;
  }
  
@end

@implementation NSString (LineEnumeratorCategory)

// Return a new line enumerator for the string.
- (LineEnumerator *) lineEnumerator
  {
  return [[LineEnumerator alloc] initWithString: self];
  }

@end