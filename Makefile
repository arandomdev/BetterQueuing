# export FINALPACKAGE = 1 // TODO: uncomment

export TARGET = iphone:clang:13.0:13.0
export ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = Music

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BetterQueuing
BetterQueuing_FILES = Tweak.xm BetterQueuing/BQPickerDataSource.m BetterQueuing/BQPlayerController.m BetterQueuing/BQSongProvider.m BetterQueuing/BQPickerController.m BetterQueuing/BQQueuePickerController.m BetterQueuing/NSArray+Mappable.m

BetterQueuing_PRIVATE_FRAMEWORKS = MediaPlaybackCore
BetterQueuing_CFLAGS = -fobjc-arc -D__USE_CF_LOG

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += BetterQueuingPreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
