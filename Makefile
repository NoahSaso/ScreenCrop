ARCHS = armv7 arm64
TARGET = iphone:clang:latest

include theos/makefiles/common.mk

TWEAK_NAME = ScreenCrop
ScreenCrop_FILES = Tweak.xm Drag.xm iOSVersion/iOSVersion.m
ScreenCrop_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
