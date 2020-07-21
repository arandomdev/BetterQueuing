INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = BetterQueuingPreferences

BetterQueuingPreferences_FILES = BQPRootListController.m
BetterQueuingPreferences_INSTALL_PATH = /Library/PreferenceBundles
BetterQueuingPreferences_FRAMEWORKS = UIKit
BetterQueuingPreferences_PRIVATE_FRAMEWORKS = Preferences
BetterQueuingPreferences_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BetterQueuingPreferences.plist$(ECHO_END)
