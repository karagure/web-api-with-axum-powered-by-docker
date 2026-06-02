// The Zig binary is produced on the host by build.sh (zig + sstrip), because the
// toolchain is far bigger than the artifact. The final image is just the binary.
FROM scratch
COPY numbers-zig /numbers
ENTRYPOINT ["/numbers"]
