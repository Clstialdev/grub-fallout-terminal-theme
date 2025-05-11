# Build variables.
BUILD_DIR   := build
THEME_DIR   := grub-fallout-terminal-theme

# OS Detection
OS_NAME := $(shell if [ -f /etc/os-release ]; then . /etc/os-release; echo $$ID; elif [ -f /etc/arch-release ]; then echo "arch"; else echo "unknown"; fi)
IS_UEFI := $(shell [ -d /sys/firmware/efi ] && echo "true" || echo "false")

# Package names based on OS
ifeq ($(OS_NAME),fedora)
    GRUB_PKG := grub2-tools
    GRUB_MKFONT := grub2-mkfont
    GRUB_MKCONFIG := grub2-mkconfig
    INSTALL_DIR := /boot/grub2/themes
    GRUB_CONFIG := /etc/default/grub
    GRUB_CFG := /boot/grub2/grub.cfg
else ifeq ($(OS_NAME),ubuntu)
    GRUB_PKG := grub2-common
    GRUB_MKFONT := grub2-mkfont
    GRUB_MKCONFIG := grub2-mkconfig
    INSTALL_DIR := /boot/grub/themes
    GRUB_CONFIG := /etc/default/grub
    GRUB_CFG := $(shell if [ "$(IS_UEFI)" = "true" ]; then echo "/boot/efi/EFI/ubuntu/grub.cfg"; else echo "/boot/grub/grub.cfg"; fi)
else ifeq ($(OS_NAME),arch)
    GRUB_PKG := grub
    GRUB_MKFONT := grub-mkfont
    GRUB_MKCONFIG := grub-mkconfig
    INSTALL_DIR := /boot/grub/themes
    GRUB_CONFIG := /etc/default/grub
    GRUB_CFG := $(shell if [ "$(IS_UEFI)" = "true" ]; then echo "/boot/efi/EFI/arch/grub.cfg"; else echo "/boot/grub/grub.cfg"; fi)
else
    # Default paths (traditional GRUB)
    GRUB_PKG := grub2-common
    GRUB_MKFONT := grub2-mkfont
    GRUB_MKCONFIG := grub2-mkconfig
    INSTALL_DIR := /boot/grub/themes
    GRUB_CONFIG := /etc/default/grub
    GRUB_CFG := /boot/grub/grub.cfg
endif

# Required commands with their package names
REQUIRED_CMDS := $(GRUB_MKFONT):$(GRUB_PKG) magick:imagemagick $(GRUB_MKCONFIG):$(GRUB_PKG)

# Customizable properties.
BACKGROUND_SIZE   := 1920x1080
FONT_SIZE         := 20
ICON_SIZE         := 24
THEME_COLOR       := 25d46c
BACKGROUND_COLOR  := black
SELECTED_FG_COLOR := white
SELECTED_BG_COLOR := $(THEME_COLOR)40

# Helper vars.
bg_w := $(firstword $(subst x, ,$(BACKGROUND_SIZE)))
bg_w := $(firstword $(subst X, ,$(bg_w)))

# Target vars.
bg    := $(BUILD_DIR)/background.png
sel   := $(BUILD_DIR)/selected_c.png
font  := $(BUILD_DIR)/fixedsys$(FONT_SIZE).pf2
icons := $(patsubst icons/%.png, $(BUILD_DIR)/icons/%.png, $(wildcard icons/*.png))
theme := $(BUILD_DIR)/theme

.PHONY: all clean check install uninstall preview check-deps info

check-deps:
	@echo "Checking required dependencies..."
	@for cmd_pkg in $(REQUIRED_CMDS); do \
		cmd=$${cmd_pkg%%:*}; \
		pkg=$${cmd_pkg#*:}; \
		if ! command -v $$cmd >/dev/null 2>&1; then \
			echo "Error: Required command '$$cmd' not found." >&2; \
			echo "Please install the package '$$pkg' using your package manager:" >&2; \
			case "$(OS_NAME)" in \
				fedora) \
					echo "  sudo dnf install $$pkg" >&2; \
					;; \
				ubuntu) \
					echo "  sudo apt install $$pkg" >&2; \
					;; \
				arch) \
					echo "  sudo pacman -S $$pkg" >&2; \
					;; \
				*) \
					echo "  Please install the package '$$pkg' using your distribution's package manager" >&2; \
					;; \
			esac; \
			exit 1; \
		fi; \
	done
	@echo "All dependencies are installed."

all: check-deps $(bg) $(sel) $(font) $(icons) $(theme)

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/icons: | $(BUILD_DIR)
	mkdir -p $@

$(bg): scanline.png vaultboy.png | $(BUILD_DIR)
	@echo "Generating background image..."
	@magick scanline.png -fuzz 100% -fill '#$(THEME_COLOR)' -opaque white \
		-background '$(BACKGROUND_COLOR)' -alpha remove - |\
		magick -size '$(BACKGROUND_SIZE)' tile:- -strip $@
	@magick vaultboy.png -resize $(bg_w) -scale 25% -fuzz 100% -fill '#$(THEME_COLOR)' -opaque white - |\
		magick $@ - -gravity SouthEast -geometry +40+40 -composite -strip png32:$@

$(sel): | $(BUILD_DIR)
	@echo "Generating selection highlight..."
	@magick 'xc:#$(SELECTED_BG_COLOR)' -strip png32:$@

$(font): fixedsys.ttf | $(BUILD_DIR)
	@echo "Generating font file..."
	@rm -rf $(BUILD_DIR)/*.pf2
	@$(GRUB_MKFONT) -s $(FONT_SIZE) -o $@ $<

$(BUILD_DIR)/icons/%.png: icons/%.png | $(BUILD_DIR)/icons
	@echo "Copying icon: $<"
	@magick $< -resize '$(ICON_SIZE)x$(ICON_SIZE)' -strip png32:$@

$(theme): theme | $(BUILD_DIR)
	@echo "Generating theme file..."
	@cp $< $@
	@sed -i 's/@font@/fixedsys$(FONT_SIZE).pf2/' $@
	@sed -i 's/@iconsize@/$(ICON_SIZE)/' $@
	@sed -i 's/@themecolor@/#$(THEME_COLOR)/' $@
	@sed -i 's/@selectedfgcolor@/$(SELECTED_FG_COLOR)/' $@

clean:
	@echo "Cleaning build directory..."
	@if [ -d "$(BUILD_DIR)" ]; then \
		find "$(BUILD_DIR)" -type l -delete; \
		rm -rf "$(BUILD_DIR)"; \
	fi
	@echo "Build directory cleaned."

check:
	@echo "Checking system requirements..."
	@[ $$(id -u) -eq 0 ] || { echo 'ERROR: This action requires root privileges.' >&2; exit 1; }
	@[ -f $(GRUB_CONFIG) ] || { echo 'ERROR: Unable to locate grub user configuration! Edit GRUB_CONFIG at the top of this Makefile.' >&2; exit 1; }
	@[ -f $(GRUB_CFG) ] || { echo 'ERROR: Unable to locate grub.cfg! Current path: $(GRUB_CFG)' >&2; \
		echo 'Detected OS: $(OS_NAME)' >&2; \
		echo 'Boot mode: $(if $(filter true,$(IS_UEFI)),UEFI,BIOS)' >&2; \
		echo 'Please check if GRUB is properly installed and configured.' >&2; \
		exit 1; }
	@echo "System check passed."
	@echo "Detected OS: $(OS_NAME)"
	@echo "Boot mode: $(if $(filter true,$(IS_UEFI)),UEFI,BIOS)"
	@echo "Using GRUB config: $(GRUB_CFG)"
	@echo "Using install directory: $(INSTALL_DIR)"

# Add a new target to show system info
info:
	@echo "System Information:"
	@echo "------------------"
	@echo "OS: $(OS_NAME)"
	@echo "Boot Mode: $(if $(filter true,$(IS_UEFI)),UEFI,BIOS)"
	@echo "GRUB Config: $(GRUB_CFG)"
	@echo "Install Directory: $(INSTALL_DIR)"
	@echo "GRUB User Config: $(GRUB_CONFIG)"
	@echo "Required Packages:"
	@for cmd_pkg in $(REQUIRED_CMDS); do \
		pkg=$${cmd_pkg#*:}; \
		echo "  - $$pkg"; \
	done
	@echo "------------------"

install: check check-deps all
	@echo "Installing theme..."
	@[ -d $(INSTALL_DIR)/$(THEME_DIR) ] && rm -rf $(INSTALL_DIR)/$(THEME_DIR) || true
	@mkdir -p $(INSTALL_DIR)
	@cp -r $(BUILD_DIR) $(INSTALL_DIR)/$(THEME_DIR)
	@sed -i '/^GRUB_TERMINAL[ _A-Z]*=/ s/^/#/' $(GRUB_CONFIG)
	@sed -i '\|GRUB_THEME=$(INSTALL_DIR)/$(THEME_DIR)/theme|d' $(GRUB_CONFIG)
	@echo 'GRUB_THEME=$(INSTALL_DIR)/$(THEME_DIR)/theme' >> $(GRUB_CONFIG)
	@$(GRUB_MKCONFIG) -o $(GRUB_CFG)
	@echo "Theme installed successfully. Please reboot to see changes."

uninstall: check
	@echo "Uninstalling theme..."
	@rm -rf $(INSTALL_DIR)/$(THEME_DIR)
	@sed -i '\|GRUB_THEME=$(INSTALL_DIR)/$(THEME_DIR)/theme|d' $(GRUB_CONFIG)
	@$(GRUB_MKCONFIG) -o $(GRUB_CFG)
	@grep -q 'GRUB_TERMINAL' $(GRUB_CONFIG) && echo 'NOTE: Uncomment GRUB_TERMINAL=... in $(GRUB_CONFIG) and re-run this if you wish to disable the graphical terminal.' >&2 || true
	@echo "Theme uninstalled successfully."

preview:
	@echo "Starting GRUB emulator preview..."
	@sleep 5 && kill -9 `pidof grub2-emu` 2>/dev/null || true &
	@grub2-emu || { echo "Error: grub2-emu not found. Please install grub2-tools-extra package." >&2; exit 1; }
	@reset
