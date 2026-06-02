# Build stage: assemble the tiny ELF (nasm only lives here, not in the image).
FROM alpine:3 AS build
RUN apk add --no-cache nasm
WORKDIR /b
COPY numbers.asm .
RUN nasm -f bin numbers.asm -o numbers && chmod +x numbers

# Final image: nothing but the ~170-byte binary on an empty filesystem.
FROM scratch
COPY --from=build /b/numbers /numbers
ENTRYPOINT ["/numbers"]
