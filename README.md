# GRUB Fallout Terminal Theme

A modern graphical theme for the [GNU GRUB 2][1] bootloader, inspired by the iconic [terminals][2] from the Fallout series. This theme brings the post-apocalyptic aesthetic to your boot screen with a fully customizable experience.

![screenshot][screenshot-img]

## Features

- Authentic Fallout terminal aesthetic
- Fully customizable colors and dimensions
- Modern GRUB 2 compatibility
- Progress bar for boot timeout
- Improved menu item styling
- High-resolution support
- Easy installation and customization

## Prerequisites

Before installing, ensure you have the following packages installed:

```bash
# For Fedora/RHEL-based systems:
sudo dnf install grub2-tools ImageMagick xcf2png

# For Debian/Ubuntu-based systems:
sudo apt install grub2-common imagemagick xcftools
```

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/grub-fallout-terminal-theme.git
cd grub-fallout-terminal-theme
```

2. Build and install the theme:
```bash
make
sudo make install
```

3. Reboot your system to see the changes:
```bash
sudo reboot
```

## Preview

To preview the theme without installing:
```bash
sudo make preview
```

## Uninstallation

To remove the theme:
```bash
sudo make uninstall
```

## Customization

The theme is highly customizable through the `Makefile`. You can modify these options either by editing the `Makefile` directly or by passing them to `make`:

```bash
make OPTION1=value1 OPTION2=value2 ...
```

### Available Options

| Option | Description | Default |
|--------|-------------|---------|
| `BACKGROUND_SIZE` | Background dimensions in pixels (WxH) | 1920x1080 |
| `FONT_SIZE` | Font size for menu text (pt) | 20 |
| `ICON_SIZE` | Size of boot entry icons (px) | 24 |
| `THEME_COLOR` | Main theme color (6-digit hex) | 25d46c |
| `BACKGROUND_COLOR` | Screen background color | black |
| `SELECTED_FG_COLOR` | Selected entry text color | white |
| `SELECTED_BG_COLOR` | Selected entry background | THEME_COLOR40 |

### Examples

To create a theme with a different color scheme:
```bash
make THEME_COLOR=ff0000 BACKGROUND_COLOR=#000033
```

To adjust the size for a smaller screen:
```bash
make BACKGROUND_SIZE=1366x768 FONT_SIZE=16
```

## Troubleshooting

If you encounter any issues:

1. Ensure all prerequisites are installed
2. Check that GRUB is properly configured
3. Verify file permissions
4. Check the GRUB configuration file at `/etc/default/grub`

## Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

## License

This project is licensed under the terms of the license included in the repository.

## Acknowledgments

- Inspired by the Fallout series by Bethesda Game Studios
- Built on [GNU GRUB 2][1]
- Original theme concept by the original author

[screenshot-img]: https://i.imgur.com/szAdrXa.png
[1]: https://www.gnu.org/software/grub/
[2]: http://fallout.wikia.com/wiki/Terminal
