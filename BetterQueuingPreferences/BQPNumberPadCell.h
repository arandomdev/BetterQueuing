#import <Preferences/PSEditableTableCell.h>

@interface PSEditableTableCell ()
- (void)textFieldDidBeginEditing:(UITextField *)textField;
- (UITextField *)textField;
@end

@interface BQPNumberPadCell : PSEditableTableCell
@property(nonatomic, readwrite, strong) __kindof UIView *inputAccessoryView;
@property(nonatomic, retain) NSString *oldValue;

- (void)textFieldDidBeginEditing:(UITextField *)textField;
- (void)cancelButtonPressed;
- (void)doneButtonPressed;
@end