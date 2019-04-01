# Clair Onboarding

For anyone who is interested in developing Clair, please read this to understand the motivations and designs.

## Introduction
Clair relates docker image content to vulnerabilities through “namespaced feature”. 
Major Features:
Report the vulnerabilities of a docker image to user
Notify changes in affected docker images when a vulnerability changes.

## Vulnerabilities

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

### How does Clair read the vulnerability reports?

It's easier to use an example, for the example above, Clair reads it as:

`high**` urgency vulnerability `CVE-2008-7220` affects source package `prototypejs` with any version less than `1.6.0.2-1` in Debian version `jessie`, `buster`, and `sid`. We recommend to upgrade to version `1.6.0.2-1` or later.

`CVE-2007-2383` does not affect `prototypejs` because it's not important.

Clair generalizes and stores all vulnerabilities in the following model:
#### Vulnerability and Affected Package Data Model
1. CVE Name, e.g. `CVE-2008-7220`
2. Urgency, e.g. `High`
3. Platform, e.g. `Debian jessie`
4. Affected Packages
	1. Name e.g. `prototypejs`
	2. Affected Version e.g. `< 1.6.0.2-1`
	3. Recommended Fixed in Version e.g. `1.6.0.2-1`
	4. Package Type e.g. `Source Package`

### How does Clair knows if a package is affected?
To determine if a package affected or not, it requires 4 pieces of information:

- Name of the package, e.g. `prototypejs`
- Version of the package, e.g. `1.5.0`
- Platform of the package, e.g. `Debian jessie`
- Type of the package, e.g. `Source Package`

For example, based on `CVE-2008-7220` of previous section, source package `prototypejs:1.5.0` on `Debian jessie` is affected by `CVE-2008-7220` because it has a version that is less than `1.6.0.2-1`.

In order to generalize the concept to include non-package things that can be affected by vulnerabilities, Clair store them in the following model:
#### Feature and Namespace Data Model
1. Feature Name, e.g. `prototypejs`
2. Feature Version, e.g. `1.5.0`
3. Feature Type, e.g. `Source Package`
4. Feature Namespace
	1. Name, e.g. `Debian`
	2. Version, e.g. `jessie`

## Container Image and Feature

Once we know how vulnerability sources report their vulnerabilities, we can extract **features** to try match their reports and see if an **Container Image** is affected. 

### What is a Container Image?
A container image is a file system that's designed for usage with container.
Most people use Docker Container Image using *union filesystem* like `AUFS` or `overlay` drivers. 
