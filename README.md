# Automated KF5 builds on various distros

![Main pipeline](https://github.com/TheAssassin/prebuilt-kf5/workflows/Main%20pipeline/badge.svg)

This project generates builds of KF5 on various distros for various architectures. It allows for using an up-to-date KF5 in various distros.


## Disclaimer

The builds provided by this script are not provided officially by the KF5 project. They are built automatically by GitHub actions.


## Usage

The released archives contain an "install tree". The directory layout is as follows:

```
kf5-v[version]-[dist]-[arch]/
├── bin
│   ├── cmake
│   ├── cpack
│   └── ctest
├── doc
│   [...]
└── share
    [...]

# "graphics" courtesy of tree
```

The easiest way to use these binaries is to extract them into `/usr/local`:

```sh
wget .../cmake-v[version]-[dist]-[arch].tar.gz -O- | tar -xz -C /usr/local --strip-components=1
```
