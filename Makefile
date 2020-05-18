# export FINALPACKAGE = 1

export TARGET = iphone:clang:13.0:13.0
export ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = Music

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BetterQueuing
BetterQueuing_FILES = Tweak.xm BetterQueuing/BQQueueDataSource.m BetterQueuing/BQQueueViewController.m BetterQueuing/BQPlayerController.m

BetterQueuing_PRIVATE_FRAMEWORKS = MediaPlaybackCore
BetterQueuing_CFLAGS = -fobjc-arc -D__USE_CF_LOG

include $(THEOS_MAKE_PATH)/tweak.mk
