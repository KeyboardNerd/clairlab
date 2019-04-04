# Clair Onboarding 2: Ancestry Model

The previous onboarding chapter talked about how does Clair extracts features from a one-layer image.
We'll talk about how does Clair extracts features from a multiple-layer image.

## Motivation
We want Clair to be fast to scan the images. The bottleneck is typically downloading layer blobs, which can be a few hundreds of MB. In order to remove this bottle neck, we created a new API restriction to enforce users to use content addressable hash on layer blobs along with a download link for the blob. 

This system could be very easily exploited if a malicious client sends fake layer blob download links with a content addressable hash of a real layer. Therefore, Clair must absolutely trust the client. And thus, typically, Clair talks to one authenticated client only.

## Multiple Layer Image
A typical docker container contains multiple layers.

A simple example is this one:
```
docker pull quay.io/keyboardnerd/onboard:latest
```

Dockerfile
```
FROM alpine:latest
RUN apk add go
RUN apk del go
ENTRYPOINT ["sh"]
```

### Layer Blob

When all layers are combined into one image, it forms a mountable file system for container runtime.

A layer typically contains:

1. any file that is added or changed in its full form.
2. any file that is removed only as a tar ball file path name with `.wh` as prefix.

There are different graph drivers for combining the layers, e.g. `overlay2`, `aufs`, `vfs`. 
However, as I tested, it seems that any graph driver results in very small difference in the published container image. We should deep dive into this later.

https://github.com/moby/moby/blob/master/daemon/graphdriver/driver.go#L95

You can checkout [graph driver](https://github.com/KeyboardNerd/clairlab/tree/master/graph%20driver) folder to retrieve image layers from some public repo, and take a look inside the decompressed layers to see what's inside. 

Some examples are 

`blobs.sh quay.io keyboardnerd/onboard latest-vfs` built using `vfs` driver

`blobs.sh quay.io keyboardnerd/onboard overlay2` built using `overlay2` driver

### Clair Layer

A Clair Layer is a "compressed" view of the whole layer blob that Clair uses to squash into an image.

For example, for this image:
```
FROM alpine:latest
RUN apk add go
RUN apk del go
ENTRYPOINT ["sh"]
```

`alpine:latest` uses `apk` to install packages. Clair uses the `/var/lib/

#### Find Feature's Namespace correctly

##### Explicit Model

##### Implicit Model

## Conclusion

### Layer

### Ancestry
