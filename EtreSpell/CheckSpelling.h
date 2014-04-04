/***********************************************************************
 ** Etresoft
 ** John W. Daniel
 ** Copyright (c) 2007
 **********************************************************************/

#import <Cocoa/Cocoa.h>

@interface SpellChecker : NSObject
  {
  @private
  
    // Should I validate network links?
    BOOL myUseNetwork;
    
    // Should I check links?
    BOOL myCheckLinks;
    
    // Should I be verbose?
    BOOL myIsVerbose;
    
    // What is my language?
    NSString * myLanguage;

    // My root path for relative links.
    NSString * myRoot;
    
    // An array of words to ignore.
    NSArray * myIgnoreArray;
  }
  
// Return the shared spell checker.
+ (SpellChecker *) sharedSpellChecker;

// Should I perform network checks?
- (void) setUseNetwork: (BOOL) useNetwork;

// Should I check links?
- (void) setCheckLinks: (BOOL) checkLinks;

// Should I be verbose?
- (void) setVerbose: (BOOL) verbose;

// Set the language.
- (void) setLanguage: (NSString *) language;

// Set the root path for relative links.
- (void) setRoot: (NSString *) root;

// Get the language.
- (NSString *) language;

// Performs a spell check of the input string.
- (BOOL) checkString: (NSString *) text;

// Returns an NSArray of strings representing ranges of misspelled
// words. Returns null if there were no misspelled words.
- (NSArray *) findMisspellingsInString: (NSString *) text;

// Learn words in a comma-delimited string.
- (void) learn: (NSString *) words;

// Learn words in an array.
- (void) learnArray: (NSArray *) words;

// Forget words in a comma-delimited string.
- (void) forget: (NSString *) words;

// Forget words in an array.
- (void) forgetArray: (NSArray *) words;

// Ignore words in a comma-delimited string.
- (void) ignore: (NSString *) words;

// Ignore words in an array.
- (void) ignoreArray: (NSArray *) words;

@end
