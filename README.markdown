# XcodePlugin

## How to install Plugin?
To use plugin you have to build the project. It will automatically place plugin file to your plugin directory ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/. And restart the xocde is all right.

## How to use Plugin?
Just input @dealloc or @format, it will auto generate dealloc method or format the string to NSLocalizedString.

### For Example

When an Interface in TestInterface.h is:

	
	@interface TestInterface : NSObject
	{
    	NSString *var1;
    	NSInteger var2;
	}
	@property(nonatomic,strong)id property1;
	@property(nonatomic,assign)NSInteger property2;

And the implementation in TestInterface.m is:	

	@interface TestInterface()
	{	
    	id var3;
	}

	@property(nonatomic,copy)NSString *property3;

Then you just input @dealloc below the @implementation, it will auto generate the code:

	/**
 	* Interface TestInterface dealloc
 	*/
	-(void)dealloc
	{
	#if !__has_feature(objc_arc)
    	//This is member variables release, please check !!!!!!
    	[var3 release];
    	var3 = nil;
    	[var1 release];
   		 var1 = nil;
    
    	//This is retain/strong/copy property release
   		self.property3 = nil;
    	self.property1 = nil;
    
    	[super dealloc];
	#endif
	}


### Maybe not the end.
