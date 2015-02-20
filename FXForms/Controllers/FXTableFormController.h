//
//  FXTableFormController.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/20/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormController.h"

@interface FXTableFormController : FXFormController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@end

@interface FXFormTableViewController : UIViewController <FXFormFieldViewController, FXFormControllerDelegate>

@property (nonatomic, readonly) FXTableFormController *formController;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end
