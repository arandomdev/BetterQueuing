export TARGET = iphone:clang:13.0:13.0

export ARCHS = arm64

INSTALL_TARGET_PROCESSES = Music

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EnhancedMusic

EnhancedMusic_FILES = Tweak.xm EnhancedMusic/EMQueueDataSource.m EnhancedMusic/EMQueueViewController.m EnhancedMusic/EMPlayerController.m
EnhancedMusic_PRIVATE_FRAMEWORKS = MediaPlaybackCore
EnhancedMusic_CFLAGS = -fobjc-arc -D__USE_CF_LOG

include $(THEOS_MAKE_PATH)/tweak.mk
