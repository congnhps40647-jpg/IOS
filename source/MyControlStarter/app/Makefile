ARCHS = arm64
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = MyControl

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MyControl
MyControl_FILES = main.m MCAppDelegate.m MCRootViewController.m
MyControl_FRAMEWORKS = UIKit
MyControl_CFLAGS = -fobjc-arc -Wall -Wextra
MyControl_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk
