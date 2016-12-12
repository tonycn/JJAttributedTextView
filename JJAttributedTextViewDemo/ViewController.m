//
//  ViewController.m
//  JJAttributedTextViewDemo
//
//  Created by Jianjun on 07/12/2016.
//  Copyright © 2016 jianjun. All rights reserved.
//

#import "ViewController.h"

#import "JJAttributedTextView.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet JJAttributedTextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.textView.highlightBackgroundColor = [UIColor lightGrayColor];
    
    NSString *helloStr = @"Hello JJAttributedTextView!\n Have fun :)";
    
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:helloStr];
    NSRange linkRange = [helloStr rangeOfString:@"JJAttributedTextView"];
    NSURL *url = [NSURL URLWithString:@"JJAttributedTextViewDemo://"];
    [self.textView addLinkToURL:url
                      withRange:linkRange
               activeAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18],
                                  NSBackgroundColorAttributeName: [UIColor lightGrayColor],
                                  NSForegroundColorAttributeName: [UIColor blueColor]}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
