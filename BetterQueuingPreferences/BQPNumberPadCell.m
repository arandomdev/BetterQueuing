#import "BQPNumberPadCell.h"

@implementation BQPNumberPadCell : PSEditableTableCell
- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.oldValue = textField.text;

	UIToolbar *toolbar = [[UIToolbar alloc] init];
	toolbar.items = @[
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)],
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil],
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)]
	];
	[toolbar sizeToFit];
	self.inputAccessoryView = toolbar;

	[super textFieldDidBeginEditing:textField];
}

- (void)cancelButtonPressed {
	[self textField].text = self.oldValue;
	[self resignFirstResponder];
}

- (void)doneButtonPressed {
	// reformats and validates some cases, i.e. "" and "00123".
	UITextField *textField = [self textField];
	textField.text = @(textField.text.integerValue).stringValue;

	[self resignFirstResponder];
}
@end