# cmyk-to-rgb

## Installation

### Checkout repository

```bash
$ cd [installation-directory]
$ git checkout https://github.com/bjoern-hempel/bash-cmyk-to-rgb.git .
```

### Download Adobe colour profiles

* https://www.adobe.com/support/downloads/iccprofiles/icc_eula_win_end.html

Be sure that you comply with the licence conditions. Download, unzip and save the profiles in an accessible directory (`[profile-directory]`).

### Change to working directory

```bash
$ cd [working-directory]
```

Copy the .profiles.dist file into your working directory:

```bash
$ cp [installation-directory]/.profiles.dist .profiles
```

Adjust the profile paths (`SETTING_PROFILE_CMYK`, `SETTING_PROFILE_RGB`) according to your configuration:

```bash
$ vi .profiles
```

## Usage

### Help

```bash
$ [working-directory]/bin/convert-cmyk-to-rgb.sh -h

Usage: convert-cmyk-to-rgb.sh [options...]

-f,    --filter                      Change the image filter (default: jpg|gif|png|jpeg|tif)
-w,    --working-directory           Change the working directory (default: current directory)

-d,    --no-dry-run                  Force to convert the image (no dry run).

-x,    --verbose                     Set output to verbose.

-h,    --help                        Shows this help.
-v,    --version                     Shows the version number.
```

### Dry run

```bash
$ [working-directory]/bin/convert-cmyk-to-rgb.sh -x

→ Filename:         ./user_upload/folder1/file1.jpg
→ Colorspace:       sRGB
→ Size:             568K
→ STATUS:           fine


→ Filename:         ./user_upload/folder1/file2.jpg
→ Colorspace:       sRGB
→ Size:             392K
→ STATUS:           fine


→ Filename:         ./user_upload/file3.jpg
→ Colorspace:       CMYK
→ Size:             12M
→ STATUS:           to be converted
→ Dryrun. Use -f to convert.

...
```

### Force image creation

```bash
$ bin/convert-cmyk-to-rgb.sh -w /path/to/images -i "jpg|gif|png|jpeg" -f -x
```



## A. Authors

* **Björn Hempel** - *Initial work* - [Björn Hempel](https://github.com/bjoern-hempel)

## B. License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## C. Closing words

Have fun! :)
