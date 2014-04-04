/***********************************************************************
 ** Etresoft
 ** John W. Daniel
 ** Copyright (c) 2007
 **********************************************************************/

#import <Cocoa/Cocoa.h>
#import "CheckSpelling.h"

int firstArgc = 1;
BOOL useNetwork = false;
BOOL verbose = false;
BOOL checkLinks = false; 
NSString * root = nil;
NSString * learnWords = nil;
NSString * forgetWords = nil;
NSString * ignoreWords = nil;
NSString * lang = nil;
  
BOOL argumentsOK = YES;

// Perform the spell check.
int performSpellcheck(int argc, const char * argv[]);

// Print usage string.
void usage(void);

int main (int argc, const char * argv[]) 
  {
  // Check command line arguments.
  if(argc < 2)
    {
    usage();
    
    return 0;
    }
  
  // Check for help.
  if(argc >= 2 && 
    (!strcmp(argv[1], "--help") || !strcmp(argv[1], "-h")))
    {
    usage();
    
    return 0;
    }
    
  int result = 0;
    
  // Setup the MacOS X bootstrap code.
  @autoreleasepool
    {
    NSApplicationLoad();
    
    // Check for network option.
    while((firstArgc < argc) && (!strncmp(argv[firstArgc], "--", 2)))
      {
      if(!strcmp(argv[firstArgc], "--net"))
        useNetwork = true;
      else if(!strcmp(argv[firstArgc], "--verbose"))
        verbose = true;
      else if(!strcmp(argv[firstArgc], "--links"))
        checkLinks = true;
      else if(!strncmp(argv[firstArgc], "--root=", 7))
        root = [NSString stringWithCString: argv[firstArgc] + 7 
          encoding: NSUTF8StringEncoding];
      else if(!strncmp(argv[firstArgc], "--lang=", 7))
        lang = [NSString stringWithCString: argv[firstArgc] + 7 
          encoding: NSUTF8StringEncoding];
      else if(!strncmp(argv[firstArgc], "--learn=", 8))
        learnWords = [NSString stringWithCString: argv[firstArgc] + 8
          encoding: NSUTF8StringEncoding];
      else if(!strncmp(argv[firstArgc], "--forget=", 9))
        forgetWords = [NSString stringWithCString: argv[firstArgc] + 9
          encoding: NSUTF8StringEncoding];
      else if(!strncmp(argv[firstArgc], "--ignore=", 9))
        ignoreWords = [NSString stringWithCString: argv[firstArgc] + 9
          encoding: NSUTF8StringEncoding];
      else
        {
        printf("Invalid argument '%s'\n", argv[firstArgc]);
        
        usage();
        
        argumentsOK = NO;
        
        break;
        }
        
      ++firstArgc;
      }
      
    if(argumentsOK)
      result = performSpellcheck(argc, argv);
    }
    
  return result;
  }

int performSpellcheck(int argc, const char * argv[])
  {
  SpellChecker * spellChecker = [SpellChecker sharedSpellChecker];
  
  [spellChecker setUseNetwork: useNetwork];
  [spellChecker setCheckLinks: checkLinks];
  [spellChecker setVerbose: verbose];
  
  if(lang)
    [spellChecker setLanguage: lang];
    
  if(root)
    [spellChecker setRoot: root];
  
  if(learnWords)
    [spellChecker learn: learnWords];
  
  if(forgetWords)
    [spellChecker forget: forgetWords];

  if(ignoreWords)
    [spellChecker ignore: ignoreWords];

  int result = 0;
  
  // Go through all the program arguments.
  for(int i = firstArgc; i < argc; ++i)
    {
    NSString * path = 
      [NSString stringWithCString: argv[i] 
        encoding: NSUTF8StringEncoding];
        
    NSFileHandle * fh = 
      [path isEqualToString: @"-"]
        ? [NSFileHandle fileHandleWithStandardInput]
        : [NSFileHandle fileHandleForReadingAtPath: 
          [path stringByExpandingTildeInPath]];
            
    if(!fh)
      {
      printf("Error: could not open file: %s\n", argv[i]);
      
      continue;
      }
      
    NSData * data = [fh readDataToEndOfFile];
    
    NSString * text = 
      [[NSString alloc] initWithBytesNoCopy: (void *)[data bytes] 
        length: [data length] encoding: NSUTF8StringEncoding 
        freeWhenDone: NO];
        
    if(verbose)
      printf("Checking spelling on %s:\n", 
        ([path isEqualToString: @"-"] ? "standard input" : argv[i]));
    
    if(![spellChecker checkString: text])
      result = 1;
    
    if(verbose)
      printf("\n");
    }
    
  return result;
  }
  
// Print usage string.
void usage(void)
  {
  printf("EtreSpell 1.1 \xc2\xa9 2007-2014 Etresoft and John Daniel\n");
  printf("Usage: EtreSpell [options] [<files to check>]\n");
  printf("  where [options] is one or more of:\n");
  printf("    --verbose = Verbose output\n");
  printf("    --links = Validate links\n");
  printf("    --root=<URL or path> = Base URL or path for relative "
    "links\n");
  printf("    --net = Validate network addresses\n");
  printf("    --lang=<lang> = Use <lang> as language\n");
  printf("    --learn=<words> = Comma-delimited list of words to "
    "learn\n");
  printf("    --forget=<words> = Comma-delimited list of words to "
    "forget\n");
  printf("    --ignore=<words> = Comma-delimited list of words to "
    "ignore\n");
  printf("  and [<files to check>] can be:\n");
  printf("    - = Standard input\n");
  }
