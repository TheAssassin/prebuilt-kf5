# Automated KF5 builds on various distros

![Main pipeline](https://github.com/TheAssassin/prebuilt-kf5/workflows/Main%20pipeline/badge.svg)

This project generates builds of KF5 on various distros for various architectures. It allows for using an up-to-date KF5 in various distros.


## Disclaimer

The builds provided by this script are not provided officially by the KDE project. They are built automatically on GitHub actions.


## Acknowledgements

This work was partly inspired by https://github.com/chigraph/precompiled-kf5-linux.


## Usage

The released archives contain an "install tree". The directory layout is as follows:

```
kf5-v[version]-[dist]-[arch]/
├── bin
│   [...]
├── lib
│   [...]
└── share
    [...]
[...]

# "graphics" courtesy of tree
```

The easiest way to use these binaries is to extract them into `/usr/local`:

```sh
wget .../kf5-v[version]-[dist]-[arch].tar.gz -O- | tar -xz -C /usr/local --strip-components=1
```
