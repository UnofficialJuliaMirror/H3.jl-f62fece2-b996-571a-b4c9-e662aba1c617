using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libh3"], :libh3),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/wookay/H3Builder/releases/download/v3.4.2"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, libc=:glibc) => ("$bin_prefix/H3.v3.4.2.aarch64-linux-gnu.tar.gz", "e6da88ea58a15ba89eff9856abd470d7e75d4f17540d5fdb7d53585bcaf0a50e"),
    Linux(:aarch64, libc=:musl) => ("$bin_prefix/H3.v3.4.2.aarch64-linux-musl.tar.gz", "3c35d961cbb2734aba61e9b75f794abbb3efc4e5f23de2bc16ba05180271e3d3"),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf) => ("$bin_prefix/H3.v3.4.2.arm-linux-gnueabihf.tar.gz", "b5e9dade89d853fb2ac20ec0a7a9903f3711e7e703cec83221e0edeaded49955"),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf) => ("$bin_prefix/H3.v3.4.2.arm-linux-musleabihf.tar.gz", "c82470e95330592f3bbe5594a8cd4001940d6e81ed950488c93c63a4d020e2d7"),
    Linux(:i686, libc=:glibc) => ("$bin_prefix/H3.v3.4.2.i686-linux-gnu.tar.gz", "698214c84ec941b203ad09406cc55dc8543c833705e25a46f1f8c928f75440cc"),
    Linux(:i686, libc=:musl) => ("$bin_prefix/H3.v3.4.2.i686-linux-musl.tar.gz", "4040a861d8375e4163003d484b4cf89816990511e82b88193685854eaa1ad838"),
    Windows(:i686) => ("$bin_prefix/H3.v3.4.2.i686-w64-mingw32.tar.gz", "4e6bac5d8502250be984d97f0db67478f9b61dad6ec295ac80a778f7f5514ae3"),
    Linux(:powerpc64le, libc=:glibc) => ("$bin_prefix/H3.v3.4.2.powerpc64le-linux-gnu.tar.gz", "133f001722a8d11b5017d62f047d645dd50e36954083495e76797d3dbdeddfeb"),
    MacOS(:x86_64) => ("$bin_prefix/H3.v3.4.2.x86_64-apple-darwin14.tar.gz", "01c75c369d70604e3aa547a76123feb3be70960900e02ed09e8107cc1ef61b9a"),
    Linux(:x86_64, libc=:glibc) => ("$bin_prefix/H3.v3.4.2.x86_64-linux-gnu.tar.gz", "3b5e76830456a863258b85ba3fe463065c8c64ea322e56ea7bd9113ab0f63b2c"),
    Linux(:x86_64, libc=:musl) => ("$bin_prefix/H3.v3.4.2.x86_64-linux-musl.tar.gz", "f079b11f67bb40e4595fd41871f01bf1b01cc558198edbec5343c808b91ffec0"),
    FreeBSD(:x86_64) => ("$bin_prefix/H3.v3.4.2.x86_64-unknown-freebsd11.1.tar.gz", "c93b48b5dd3358c6e39fac11514662e8f3bfb4f785c98b5f0b77363ca8c292d1"),
    Windows(:x86_64) => ("$bin_prefix/H3.v3.4.2.x86_64-w64-mingw32.tar.gz", "d0e9c78e9dae2d1266fcbf663c2b5565e359922782b0341a683704a5453454ca"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    # If we don't have a compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# If we have a download, and we are unsatisfied (or the version we're
# trying to install is not itself installed) then load it up!
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    install(dl_info...; prefix=prefix, force=true, verbose=verbose)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)