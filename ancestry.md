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

### What's inside a Layer?

### What's the connection between Layers

### How does Docker squash the layers

### Extract information from one layer blob as a Clair layer

### How does Clair squash the Layer (Ancestry Model)

#### Find Feature's Namespace correctly

##### Explicit Model

##### Implicit Model

## Conclusion

### Layer

### Ancestry
