# Clair Onboarding

For anyone who is interested in developing Clair, please read this to understand the motivations and designs.

## What is Clair
Clair reports the vulnerabilities of container images to users and notifies changes in affected container images when a vulnerability changes. For a Clair instance, all images will only be posted once and scanned once.

Clair relates container images to vulnerabilities through “namespaced feature”. 

## Instruction

1. Understand Vulnerabilities and Vulnerability Sources
2. Understand Namespaced Feature, Namespace, Feature, and how they are related to vulnerabilities.
3. Understand one-layer container image, and how to extract Namespaced Feature from it.
4. Understand multiple-layer container image, how to extract Namespaced Feature from it, and explicit and implicit relation between namespace and feature.
6. Understand how to compute the notification.

## Vulnerability Sources

### What is vulnerability?
It’s a thing that people can use to do damage to a system.

### Where does Clair get those vulnerabilities?
Clair aggregates the vulnerabilities from different sources, including [OVAL](https://www.redhat.com/security/data/oval/), [Alpine-secdb](https://github.com/alpinelinux/alpine-secdb), and etc.

### How does vulnerability sources report the vulnerabilities?
Different sources have different styles of reports, our goal for Clair is to understand all of them internally.

One example is Debian, you can view the source code [here](https://github.com/coreos/clair/blob/master/ext/vulnsrc/debian/debian.go). Debian tracker lists source package names, and their associated CVEs, including fixed versions for different Debian distros.

One block of the report looks like this:

```javascript
 {
  "prototypejs": {
    "CVE-2008-7220": {
      "scope": "remote",
      "debianbug": 555217,
      "description": "Unspecified vulnerability in Prototype JavaScript framework (prototypejs) before 1.6.0.2 allows attackers to make \"cross-site ajax requests\" via unknown vectors.",
      "releases": {
        "jessie": {
          "status": "resolved",
          "repositories": {
            "jessie": "1.7.1-3"
          },
          "fixed_version": "1.6.0.2-1",
          "urgency": "high**"
        },
        "buster": {
          "status": "resolved",
          "repositories": {
            "buster": "1.7.1-3"
          },
          "fixed_version": "1.6.0.2-1",
          "urgency": "high**"
        },
        "sid": {
          "status": "resolved",
          "repositories": {
            "sid": "1.7.1-3"
          },
          "fixed_version": "1.6.0.2-1",
          "urgency": "high**"
        }
      }
    },
    "CVE-2007-2383": {
      "scope": "remote",
      "debianbug": 555217,
      "description": "The Prototype (prototypejs) framework before 1.5.1 RC3 exchanges data using JavaScript Object Notation (JSON) without an associated protection scheme, which allows remote attackers to obtain the data via a web page that retrieves the data through a URL in the SRC attribute of a SCRIPT element and captures the data using other JavaScript code, aka \"JavaScript Hijacking.\"",
      "releases": {
        "jessie": {
          "status": "resolved",
          "repositories": {
            "jessie": "1.7.1-3"
          },
          "fixed_version": "0",
          "urgency": "unimportant"
        },
        "buster": {
          "status": "resolved",
          "repositories": {
            "buster": "1.7.1-3"
          },
          "fixed_version": "0",
          "urgency": "unimportant"
        },
        "sid": {
          "status": "resolved",
          "repositories": {
            "sid": "1.7.1-3"
          },
          "fixed_version": "0",
          "urgency": "unimportant"
        }
      }
    }
  }
```

## Vulnerability and Affected Feature
### How does Clair reads the vulnerability reports?

It's easier to use an example, for the example above, Clair reads it as:

- `CVE-2007-2383` does not affect `prototypejs` because it's not important.

- `high**` urgency vulnerability `CVE-2008-7220` affects source package `prototypejs` with any version less than `1.6.0.2-1` in Debian version `jessie`, `buster`, and `sid`. We recommend to upgrade to version `1.6.0.2-1` or later.

For the second sentence:

Clair saves this whole sentence as a **Vulnerability**.

Clair saves the following sentence "source package `prototypejs` with any version less than `1.6.0.2-1` in Debian version `jessie`, `buster`, and `sid`. We recommend to upgrade to version `1.6.0.2-1` or later" as an **Affected Feature**.

Clair then generalizes and stores all vulnerabilities in the following model:
#### Vulnerability and Affected Feature Data Model
1. CVE Name, e.g. `CVE-2008-7220`
2. Urgency, e.g. `High`
3. Platform, e.g. `Debian jessie`
4. Affected Features
	1. Name e.g. `prototypejs`
	2. Affected Version e.g. `< 1.6.0.2-1`
	3. Recommended Fixed in Version e.g. `1.6.0.2-1`
	4. Package Type e.g. `Source Package`

## Feature, Namespace and Namespaced Feature
### How does Clair knows if a package is affected?
To determine if a package affected or not, it requires 4 pieces of information:

- Name of the package, e.g. `prototypejs`
- Version of the package, e.g. `1.5.0`
- Platform of the package, e.g. `Debian jessie`
- Type of the package, e.g. `Source Package`

For example, based on `CVE-2008-7220` of previous section, source package `prototypejs:1.5.0` on `Debian jessie` is affected by `CVE-2008-7220` because it has a version that is less than `1.6.0.2-1`.

We generalize the 4 pieces of information as **Namespaced Feature**, in which the "Platform of the package" is called **Namespace** and the rest 3 pieces are called **Feature**.

#### Namespaced Feature Data Model
1. Feature Name, e.g. `prototypejs`
2. Feature Version, e.g. `1.5.0`
3. Feature Type, e.g. `Source Package`
4. Namespace
	1. Name, e.g. `Debian`
	2. Version, e.g. `jessie`

## Container Image, Feature, and Namespace

Once we know how vulnerability sources report their vulnerabilities, and the meaning of **Namespaced Feature**, **feature**, **namespace**, and how are they related vulnerabilities, we can start to see how are they extracted from a **container image**.

### What is a Container Image?
A container image is a file system that's designed for usage with container.
Most people use Docker Container Image using *union filesystem* by `AUFS` or `overlay` drivers.

### How does it extract Namespaced Features from one-Layer container image?
Let's start from a simple example, one layer, no *union filesystem*.

A layer blob contains a whole file system to be used to run the container. For example, you can try it by `docker pull alpine:latest && docker save alpine:latest -o test.tar `, and untar `test.tar` to see the actual file system.

Clair reads files of interest from the layer blob to extract features and namespaces. You can look at the source code [here for extracting namespaces](https://github.com/coreos/clair/tree/master/ext/featurens), and [here for extracting features](https://github.com/coreos/clair/tree/master/ext/featurefmt).

#### alpine:latest Example

The file `/etc/os-release` typically contains the operating system information. Here is one example from `alpine:latest`: 

```
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.9.2
PRETTY_NAME="Alpine Linux v3.9"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://bugs.alpinelinux.org/"
```

Clair understands the file and knows that the operating system is `alpine linux version 3.9.2`.

Thus we get a namespace:

```
name = Alpine Linux
version = 3.9.2
```

For the features, we know that typically package managers have specific location for their databases to understand what packages are installed in the operating system. 

So, for example, `APK` package manager, Clair looks at the `lib/apk/db/installed` file.

Here is one block from the file representing one package:

```
C:Q1waOPPaq4OKcCPC7AMZfadaYwC+8=
P:musl
V:1.1.20-r3
A:x86_64
S:369577
I:602112
T:the musl c library (libc) implementation
U:http://www.musl-libc.org/
L:MIT
o:musl
m:Timo Teräs <timo.teras@iki.fi>
t:1546526764
c:7b32fee49798e36cb5a7dfde30183f9717472cf6
p:so:libc.musl-x86_64.so.1=1
F:lib
R:libc.musl-x86_64.so.1
a:0:0:777
Z:Q17yJ3JFNypA4mxhJJr0ou6CzsJVI=
R:ld-musl-x86_64.so.1
a:0:0:755
Z:Q1D/i9VqW+lt5Bk0EA8UDoHaiHr8g=
F:usr
F:usr/lib
```

Clair understands the block and knows that it's a `MUSL` with version `1.1.20-r3`. Clair assumes `APK` installs compiled packages, and therefore it's of `Binary Package` type.

Thus, we get a feature: 

```
name = MUSL
version = 1.1.20-r3
type = binary package
```

Combining the information we're given, Clair decides that `MUSL` is a package running on platform `Alpine Linux version 3.9.2` based on the assumption that `APK` installs operating system wide packages.

Thus, we get a namespaced feature:

```
name = MUSL
version = 1.1.20-r3
type = binary package
namespace:
  name = Alpine Linux
  version = 3.9.2
```

Thus, it can be related to a vulnerability as we shown in the `vulnerability` section.

