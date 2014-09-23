/***********************************************************************
 ** Etresoft
 ** John W. Daniel
 ** Copyright (c) 2007
 **********************************************************************/

#import <Cocoa/Cocoa.h>

#import "CheckSpelling.h"
#import "LineEnumerator.h"
#import "LineDescriptor.h"

// Some keys for the dictionaries inside the resulting array.
#define kMisspelledFile  @"misspelledfile"
#define kMisspelledLine  @"misspelledline"
#define kMisspelledRange @"misspelledrange"
#define kMisspelledWord  @"misspelledword"
#define kMisspelledLink  @"misspelledlink"
#define kMisspelledTag   @"misspelledtag"
#define kBadLinkResult   @"badlinkresult"

#define kTagName @"tagname"

SpellChecker * ourSharedSpellChecker = nil;

@implementation SpellChecker

// Return the shared spell checker.
+ (SpellChecker *) sharedSpellChecker
  {
  if(!ourSharedSpellChecker)
    ourSharedSpellChecker = [[SpellChecker alloc] init];
  
  return ourSharedSpellChecker;
  }
  
// Constructor.
- (id) init
  {
  if(self = [super init])
    {
    myLanguage = @"en";
    myRoot = [[NSString alloc] init];
    }
    
  return self;
  }
  
// Should I perform network checks?
- (void) setUseNetwork: (BOOL) useNetwork
  {
  myUseNetwork = useNetwork;
  }
  
// Should I check links?
- (void) setCheckLinks: (BOOL) checkLinks
  {
  myCheckLinks = checkLinks;
  }
  
// Should I be verbose?
- (void) setVerbose: (BOOL) verbose
  {
  myIsVerbose = verbose;
  }

// Set the language.
- (void) setLanguage: (NSString *) language
  {
  if(language && (language != myLanguage))
    myLanguage = [language copy];
  }
  
// Set the root path for relative links.
- (void) setRoot: (NSString *) root
  {
  if(root && (root != myRoot))
    {
    if([root hasPrefix: @"http://"])
      myRoot = [root copy];
    else
      myRoot = [[root stringByExpandingTildeInPath] copy];
    }
  }
  
// Get the language.
- (NSString *) language
  {
  return myLanguage;
  }
  
// Check spelling in a UTF-8 string, printing results to standard 
// output.
- (BOOL) checkString: (NSString *) text inFile: (NSString *) path
  {
  file = path;
  
  NSArray * misspellings = [self findMisspellingsInString: text];
    
  if(!misspellings || ([misspellings count] == 0))
    {
    if(myIsVerbose)
      printf("No misspellings\n");
    
    return YES;
    }
  
  NSArray * sorted =
    [misspellings
      sortedArrayWithOptions: 0
      usingComparator:
        ^NSComparisonResult(id obj1, id obj2)
          {
          NSDictionary * msp1 = obj1;
          NSDictionary * msp2 = obj2;
          
          if([msp1[kMisspelledFile] isEqualToString: msp2[kMisspelledFile]])
            return
              [msp1[kMisspelledWord] compare: msp2[kMisspelledWord] options: 0];
          
          return
            [msp1[kMisspelledFile] compare: msp2[kMisspelledFile] options: 0];
          }];
  
  NSEnumerator * enumerator = [sorted objectEnumerator];
  
  id misspelling;
  
  while(misspelling = [enumerator nextObject])
    [self print: misspelling];
    
  return NO;
  }

// Validates a UTF-8 string and returns an array of all misspelled words
// or links.
- (NSArray *) findMisspellingsInString: (NSString *) text
  {
  // Array for results.
  NSMutableArray * misspellings = [[NSMutableArray alloc] init];
  
  // Enumerate through the lines in the string.
  LineEnumerator * lineEnumerator = [text lineEnumerator];
  
  // A scanner to parse for markup tags.
  NSScanner * scanner = [NSScanner scannerWithString: text];

  // Don't skip any characters with the scanner.
  [scanner setCharactersToBeSkipped:
    [NSCharacterSet characterSetWithCharactersInString: @""]];

  while(![scanner isAtEnd])
    {
    // Find all the misspellings up to the next tag.
    [misspellings 
      addObjectsFromArray:
        [self findMisspellingsUsingScanner: scanner 
          withEnumerator: lineEnumerator]];
    
    // See if the link is bad.
    if(![scanner isAtEnd])
      {
      NSDictionary * badLink = [self findBadLinkUsingScanner: scanner 
        withEnumerator: lineEnumerator];

      if(badLink)
        [misspellings addObject: badLink];
      }
    }
    
  return misspellings;
  }
  
// Learn words in a comma-delimited string.
- (void) learn: (NSString *) words
  {
  [self learnArray: [words componentsSeparatedByString: @","]];
  }

// Learn words in an array.
- (void) learnArray: (NSArray *) words
  {
  // The MacOS X spell checker.
  NSSpellChecker * checker = [NSSpellChecker sharedSpellChecker];

  NSEnumerator * enumerator = [words objectEnumerator];
  
  NSString * word = nil;
  
  while(word = [enumerator nextObject])
    [checker learnWord: word];
  }

// Forget words in a comma-delimited string.
- (void) forget: (NSString *) words
  {
  [self forgetArray: [words componentsSeparatedByString: @","]];
  }

// Forget words in an array.
- (void) forgetArray: (NSArray *) words
  {
  // The MacOS X spell checker.
  NSSpellChecker * checker = [NSSpellChecker sharedSpellChecker];

  NSEnumerator * enumerator = [words objectEnumerator];
  
  NSString * word = nil;
  
  while(word = [enumerator nextObject])
    [checker unlearnWord: word];
  }

// Ignore words in a comma-delimited string.
- (void) ignore: (NSString *) words
  {
  [self ignoreArray: [words componentsSeparatedByString: @","]];
  }

// Ignore words in an array.
- (void) ignoreArray: (NSArray *) words 
  {
  myIgnoreArray = [words copy];
  }

// Print a misspelling dictionary entry.
- (void) print: (NSDictionary *) misspelling
  {
  if(myIsVerbose)
    {
    if([misspelling objectForKey: kMisspelledWord])
      printf("File: %s, Line: %5d, Misspelled word: %s\n",
        [[misspelling objectForKey: kMisspelledFile] UTF8String],
        [[misspelling objectForKey: kMisspelledLine] intValue],
        [[misspelling objectForKey: kMisspelledWord] UTF8String]);

    else if([misspelling objectForKey: kMisspelledLink])
      printf("File: %s, Line: %5d, Bad link: %s, %s\n",
        [[misspelling objectForKey: kMisspelledFile] UTF8String],
        [[misspelling objectForKey: kMisspelledLine] intValue],
        [[misspelling objectForKey: kMisspelledLink] UTF8String],
        [[misspelling objectForKey: kBadLinkResult] UTF8String]);
    }
  else
    {
    if([misspelling objectForKey: kMisspelledWord])
      printf("%s\n",
        [[misspelling objectForKey: kMisspelledWord] UTF8String]);

    else if([misspelling objectForKey: kMisspelledLink])
      printf("%s\n", 
        [[misspelling objectForKey: kMisspelledLink] UTF8String]);
    }
  }
  
// Find misspellings until a given mark occurs.
// Returns an NSArray of dictionaries containing the line number, range 
// of misspelled word (as an NSString), and the misspelling itself. 
- (NSArray *) findMisspellingsUsingScanner: (NSScanner *) scanner 
  withEnumerator: (LineEnumerator *) lineEnumerator
  {
  // Save my starting location.
  NSUInteger start = [scanner scanLocation];

  // Look for the start of a tag. I will check all text before the next
  // tag for misspellings.
  NSString * text = 0;

  [scanner scanUpToString: @"<" intoString: & text];
  
  NSUInteger end = [scanner scanLocation];

  // Spell check the substring before the tag.
  return 
    [self findMisspellingsInString: [text substringToIndex: end - start]
      withEnumerator: lineEnumerator
      inRange: NSMakeRange(start, end - start)];
  }
  
// Find bad links until a given mark occurs.
// Return an NSDictionary describing the bad tag, or nil if the tag is 
// good.
- (NSDictionary *) findBadLinkUsingScanner: (NSScanner *) scanner
  withEnumerator: (LineEnumerator *) lineEnumerator
  {
  // Scan the tag start.
  if([scanner scanString: @"<" intoString: nil])
    {
    // Save my starting location.
    NSUInteger start = [scanner scanLocation];

    // Look for the end of the tag.
    NSString * text = 0;

    [scanner scanUpToString: @">" intoString: & text];

    NSUInteger end = [scanner scanLocation];

    // Absorb the tag end.
    [scanner scanString: @">" intoString: nil];

    if(myCheckLinks)
      // Check for a bad link.
      return 
        [self findBadLinkInString: [text substringToIndex: end - start]
          withEnumerator: lineEnumerator
          inRange: NSMakeRange(start, end - start)];
    }
    
  return nil;
  }
  
// Returns an NSArray of dictionaries containing the line number, range 
// of misspelled word (as an NSString), and the misspelling itself. 
- (NSArray *) findMisspellingsInString: (NSString *) text
  withEnumerator: (LineEnumerator *) lineEnumerator
  inRange: (NSRange) range
  {
  // The misspellings result array.
  NSMutableArray * misspellings = [[NSMutableArray alloc] init];
  
  if(text)
    {
    NSMutableString * newText = 
      [[NSMutableString alloc] initWithString: text];
    
    // Replace any single quotes.
    unichar smartSingleQuoteData[] = { 0x2019 };
    NSString * smartSingleQuote = 
      [NSString stringWithCharacters: smartSingleQuoteData length: 1];
      
    //[newText replaceOccurrencesOfString: @"'" withString: @" "
    //  options: NSLiteralSearch range: NSMakeRange(0, [newText length])];
    [newText replaceOccurrencesOfString: smartSingleQuote 
      withString: @"'" options: NSLiteralSearch 
      range: NSMakeRange(0, [newText length])];
      
    // The MacOS X spell checker.
    NSSpellChecker * checker = [NSSpellChecker sharedSpellChecker];

    if(checker)
      {
      NSInteger tag = [NSSpellChecker uniqueSpellDocumentTag];

      [self ignoreWordInSpellDocumentWithTag: tag];
      
      unsigned long offset = 0;
      
      while(true)
        {      
        // Check spelling in the string from the offset.
        NSRange misspelled = 
          [checker checkSpellingOfString: newText startingAt: offset
            language: myLanguage wrap: NO 
            inSpellDocumentWithTag: tag wordCount: 0];
        
        // Break out of the loop if I didn't find anything.  
        if(misspelled.length == 0)
          break;

        // Move the offset to look for the next misspelled word.
        offset = misspelled.location + misspelled.length;
        
        NSRange misspelledRange = 
          NSMakeRange(
            range.location + misspelled.location, misspelled.length);
        
        // Get the line information for the location of the misspelling.
        LineDescriptor * currentLine = 
          [lineEnumerator findLineForRange: misspelledRange];
        
        // Add the misspelling to my result.
        [misspellings addObject: 
          [NSDictionary dictionaryWithObjectsAndKeys:
            file, kMisspelledFile,
            [NSNumber numberWithUnsignedInteger: [currentLine number]],
              kMisspelledLine,
            [text substringWithRange: misspelled], kMisspelledWord,
            NSStringFromRange(misspelledRange), kMisspelledRange,
            nil]];
            
        // Don't go too far.
        if(offset >= range.length)
          break;
        }
        
      [checker closeSpellDocumentWithTag: tag];
      }
    }
    
  return misspellings;
  }

// Return an NSDictionary describing the bad tag, or nil if the tag is 
// good.
- (NSDictionary *) findBadLinkInString: (NSString *) text 
  withEnumerator: (LineEnumerator *) lineEnumerator
  inRange: (NSRange) range
  {
  if(text)
    {
    // Get the line information for the location of the misspelling.
    LineDescriptor * currentLine = 
      [lineEnumerator findLineForRange: range];
    
    return [self validateTag: text 
      atLine: [currentLine number] 
      atLocation: range.location];
    }
    
  return nil;
  }

// Validate a tag at a given line and location.
// Return an NSDictionary describing the bad tag, or nil if the tag is 
// good.
- (NSDictionary *) validateTag: (NSString *) text 
  atLine: (NSUInteger) line
  atLocation: (NSUInteger) location
  {
  // Create a scanner to look for strings.
  NSScanner * scanner = [NSScanner scannerWithString: text];
 
  NSString * tagName = nil;

  // Create a dictionary to store all my tag parts.
  NSMutableDictionary * tag = [[NSMutableDictionary alloc] init];

  // Scan the first word.
  if([scanner scanUpToCharactersFromSet: 
    [NSCharacterSet whitespaceAndNewlineCharacterSet] 
    intoString: & tagName])
    {
    // Store the tag name.
    [tag setObject: [tagName lowercaseString] forKey: kTagName];

    // Scan for the tag attributes.
    while(![scanner isAtEnd])
      {
      NSString * attributeName = nil;
      NSString * attributeValue = nil;

      if([scanner scanUpToString: @"=" intoString: & attributeName])
      
        if([scanner scanString: @"=" intoString: nil])
          {
          // Handle a quoted value.
          if([scanner scanString: @"\"" intoString: nil])
            [scanner scanUpToString: @"\"" 
              intoString: & attributeValue];
              
          // Just read the next unquoted string.
          else 
            [scanner scanUpToCharactersFromSet: 
              [NSCharacterSet whitespaceAndNewlineCharacterSet] 
              intoString: & attributeValue];
          }
        
      if(attributeName && attributeValue)
        [tag setObject: attributeValue 
          forKey: [attributeName lowercaseString]];
      }

    NSRange range = 
      NSMakeRange(location, [scanner scanLocation] - location);

    return [self validateTag: tag atLine: line inRange: range];
    }

  return nil;
  }
  
// Validate a tag (consisting of a dictionary of tag attributes) at a 
// given line and location.
// Return an NSDictionary describing the bad tag, or nil if hte tag is
// good.
- (NSDictionary *) validateTag: (NSDictionary *) tag
  atLine: (NSUInteger) line
  inRange: (NSRange) range
  {
  NSString * tagName = [tag objectForKey: kTagName];

  // Handle an ending tag.
  if([tagName hasPrefix: @"/"])
  
    return nil;
    
  // Valid starting tag.
  else if([tagName isEqualToString: @"a"])
    return [self validateLink: [tag objectForKey: @"href"] 
      atLine: line inRange: range];
        
  else if([tagName isEqualToString: @"img"])
    return [self validateLink: [tag objectForKey: @"src"] 
      atLine: line inRange: range];

  return nil;
  }

// Validate a link at a given line and range.
// Return an NSDictionary describing the bad tag, or nil if the tag is 
// good.
- (NSDictionary *) validateLink: (NSString *) link
  atLine: (NSUInteger) line
  inRange: (NSRange) range
  {
  if([link hasPrefix: @"mailto:"])
    return [self validateMailURL: link atLine: line inRange: range];
    
  // Strip off any anchors.
  NSRange anchor = [link rangeOfString: @"#"];
  
  NSString * baseLink = 
    ((anchor.location == NSNotFound)
      ? link
      : [link substringToIndex: anchor.location]);
    
  if([baseLink length] == 0)
    return nil;
    
  // Start with the base link.
  NSString * URL = baseLink;
  
  // If the URL isn't already an HTTP link, prepend the root.
  if(![URL hasPrefix: @"http://"])
    {
    // Be careful! I have to strip out the http part before appending
    // paths.
    if([myRoot hasPrefix: @"http://"])
      URL = [NSString stringWithFormat: @"http://%@",
        [[myRoot substringFromIndex: 7] 
          stringByAppendingPathComponent: URL]];
    else    
      URL = [myRoot stringByAppendingPathComponent: URL];
    }
    
  // Check for HTTP URLs.
  if([URL hasPrefix: @"http://"])
    return [self validateHTTPURL: [NSURL URLWithString: URL]
      atLine: line inRange: range];
      
  // This must be a relative link.
  return [self validateRelativeURL: URL atLine: line inRange: range];
  }
  
// Validate an HTTP URL at a given line and range.
// Return an NSDictionary describing the bad tag, or nil if the tag is 
// good.
- (NSDictionary *) validateHTTPURL: (NSURL *) URL 
  atLine: (NSUInteger) line
  inRange: (NSRange) range
  {
  if(URL)
    if(myUseNetwork)
      {
      // Create a URL request to check the link.
      NSMutableURLRequest * request = [[NSMutableURLRequest alloc] init];

      // Perform a HEAD request for the given URL.
      [request setURL: URL];
      [request setHTTPMethod: @"HEAD"];

      // Check the link and wait for the result.
      NSHTTPURLResponse * response;
      NSError * error;

      [NSURLConnection sendSynchronousRequest: request 
        returningResponse: & response error: & error];

      if(response)
        {
        NSInteger statusCode = [response statusCode];

        NSString * msg =
          [NSString
            stringWithFormat:
              @"%ld - %@",
              (long)statusCode,
              [NSHTTPURLResponse localizedStringForStatusCode: statusCode]];

        // If the status code isn't 200, I'll report it.
        if(statusCode != 200)
          return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithUnsignedInteger: line], kMisspelledLine,
            [URL absoluteString], kMisspelledLink,
            msg, kBadLinkResult,
            NSStringFromRange(range), kMisspelledRange,
            nil];
        }
      }
      
  return nil;
  }

// Validate a mail URL.
// Return an NSDictionary describing the bad tag, or nil if the tag is 
// good.
- (NSDictionary *) validateMailURL: (NSString *) URL
  atLine: (NSUInteger) line inRange: (NSRange) range
  {
  NSRange spacePos = [URL rangeOfString: @" "];
  
  if(spacePos.location != NSNotFound)
    return [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithUnsignedInteger: line], kMisspelledLine,
      URL, kMisspelledLink,
      NSStringFromRange(range), kMisspelledRange,
      nil];

  return nil;
  }

// Validate a relative link at a given line and range.
// Return an NSDictionary describing the bad tag, or nil if the tag is 
// good.
- (NSDictionary *) validateRelativeURL: (NSString *) path
  atLine: (NSUInteger) line
  inRange: (NSRange) range
  {
  if(![[NSFileManager defaultManager] fileExistsAtPath: path])
    return [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithUnsignedInteger: line], kMisspelledLine,
      path, kMisspelledLink,
      @"does not exist", kBadLinkResult,
      NSStringFromRange(range), kMisspelledRange,
      nil];

  return nil;
  }

// Tell the spell checker to ignore my ignore words.
- (void) ignoreWordInSpellDocumentWithTag: (NSInteger) tag
  {
  // The MacOS X spell checker.
  NSSpellChecker * checker = [NSSpellChecker sharedSpellChecker];

  NSEnumerator * enumerator = [myIgnoreArray objectEnumerator];
  
  NSString * word = nil;
  
  while(word = [enumerator nextObject])
    [checker ignoreWord: word inSpellDocumentWithTag: tag];
  }

@end
