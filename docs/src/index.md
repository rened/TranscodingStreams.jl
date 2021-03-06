TranscodingStreams.jl
=====================

Overview
--------

TranscodingStreams.jl is a package for transcoding (e.g. compression) data
streams. It exports a type `TranscodingStream`, which is a subtype of `IO` and
supports various I/O operations like other usual I/O streams in the standard
library. Operations are quick, simple, and consistent.

In this page, we intorduce the basic concepts of TranscodingStreams.jl and
available packages. The [Examples](@ref) page demonstrates common usage. The
[References](@ref) page offers a comprehensive API document.


Introduction
------------

`TranscodingStream` has two type parameters, `C<:Codec` and `S<:IO`, and hence
the actual type should be written as `TranscodingStream{C<:Codec,S<:IO}`. This
type wraps an underlying I/O stream `S` by a codec `C`. The codec defines
transformation (or transcoding) of the stream. For example, when `C` is a
lossless decompressor type and `S` is a file, `TranscodingStream{C,S}` behaves
like a data stream that incrementally decompresses data from the file.

Codecs are defined in other packages listed below:

```@raw html
<table>
    <tr>
        <th>Package</th>
        <th>Library</th>
        <th>Format</th>
        <th>Codec</th>
        <th>Stream</th>
        <th>Description</th>
    </tr>
    <tr>
        <td rowspan="6"><a href="https://github.com/bicycle1885/CodecZlib.jl">CodecZlib.jl</a></td>
        <td rowspan="6"><a href="http://zlib.net/">zlib</a></td>
        <td rowspan="2"><a href="https://tools.ietf.org/html/rfc1952">RFC1952</a></td>
        <td><code>GzipCompressor</code></td>
        <td><code>GzipCompressorStream</code></td>
        <td>Compress data in gzip (.gz) format.</td>
    </tr>
    <tr>
        <td><code>GzipDecompressor</code></td>
        <td><code>GzipDecompressorStream</code></td>
        <td>Decompress data in gzip (.gz) format.</td>
    </tr>
    <tr>
        <td rowspan="2"><a href="https://tools.ietf.org/html/rfc1950">RFC1950</a></td>
        <td><code>ZlibCompressor</code></td>
        <td><code>ZlibCompressorStream</code></td>
        <td>Compress data in zlib format.</td>
    </tr>
    <tr>
        <td><code>ZlibDecompressor</code></td>
        <td><code>ZlibDecompressorStream</code></td>
        <td>Decompress data in zlib format.</td>
    </tr>
    <tr>
        <td rowspan="2"><a href="https://tools.ietf.org/html/rfc1951">RFC1951</a></td>
        <td><code>DeflateCompressor</code></td>
        <td><code>DeflateCompressorStream</code></td>
        <td>Compress data in deflate format.</td>
    </tr>
    <tr>
        <td><code>DeflateDecompressor</code></td>
        <td><code>DeflateDecompressorStream</code></td>
        <td>Decompress data in deflate format.</td>
    </tr>
    <tr>
        <td rowspan="2"><a href="https://github.com/bicycle1885/CodecBzip2.jl">CodecBzip2.jl</a></td>
        <td rowspan="2"><a href="http://www.bzip.org/">bzip2</a></td>
        <td rowspan="2"></td>
        <td><code>Bzip2Compressor</code></td>
        <td><code>Bzip2CompressorStream</code></td>
        <td>Compress data in bzip2 (.bz2) format.</td>
    </tr>
    <tr>
        <td><code>Bzip2Decompressor</code></td>
        <td><code>Bzip2DecompressorStream</code></td>
        <td>Decompress data in bzip2 (.bz2) format.</td>
    </tr>
    <tr>
        <td rowspan="2"><a href="https://github.com/bicycle1885/CodecXz.jl">CodecXz.jl</a></td>
        <td rowspan="2"><a href="https://tukaani.org/xz/">xz</a></td>
        <td rowspan="2"><a href="https://tukaani.org/xz/xz-file-format.txt">The .xz File Format</a></td>
        <td><code>XzCompressor</code></td>
        <td><code>XzCompressorStream</code></td>
        <td>Compress data in xz (.xz) format.</td>
    </tr>
    <tr>
        <td><code>XzDecompressor</code></td>
        <td><code>XzDecompressorStream</code></td>
        <td>Decompress data in xz (.xz) format.</td>
    </tr>
    <tr>
        <td rowspan="2"><a href="https://github.com/bicycle1885/CodecZstd.jl">CodecZstd.jl</a></td>
        <td rowspan="2"><a href="http://facebook.github.io/zstd/">zstd</a></td>
        <td rowspan="2"><a href="https://github.com/facebook/zstd/blob/dev/doc/zstd_compressor_format.md">Zstandard Compressor Format</a></td>
        <td><code>ZstdCompressor</code></td>
        <td><code>ZstdCompressorStream</code></td>
        <td>Compress data in zstd (.zst) format.</td>
    </tr>
    <tr>
        <td><code>ZstdDecompressor</code></td>
        <td><code>ZstdDecompressorStream</code></td>
        <td>Decompress data in zstd (.zst) format.</td>
    </tr>
    <tr>
        <td rowspan="6"><a href="https://github.com/bicycle1885/CodecBase.jl">CodecBase.jl</a></td>
        <td rowspan="6">native</td>
        <td rowspan="6"><a href="https://tools.ietf.org/html/rfc4648">RFC4648</a></td>
        <td><code>Base16Encoder</code></td>
        <td><code>Base16EncoderStream</code></td>
        <td>Encode binary in base16 format.</td>
    </tr>
    <tr>
        <td><code>Base16Decoder</code></td>
        <td><code>Base16DecoderStream</code></td>
        <td>Decode binary in base16 format.</td>
    </tr>
    <tr>
        <td><code>Base32Encoder</code></td>
        <td><code>Base32EncoderStream</code></td>
        <td>Encode binary in base32 format.</td>
    </tr>
    <tr>
        <td><code>Base32Decoder</code></td>
        <td><code>Base32DecoderStream</code></td>
        <td>Decode binary in base32 format.</td>
    </tr>
    <tr>
        <td><code>Base64Encoder</code></td>
        <td><code>Base64EncoderStream</code></td>
        <td>Encode binary in base64 format.</td>
    </tr>
    <tr>
        <td><code>Base64Decoder</code></td>
        <td><code>Base64DecoderStream</code></td>
        <td>Decode binary in base64 format.</td>
    </tr>
</table>
```

Install packages you need by calling `Pkg.add(<package name>)` in a Julia
session. For example, if you want to read gzip-compressed files, call
`Pkg.add("CodecZlib")` to use `GzipDecompressor` or `GzipDecompressorStream`.
By convention, codec types have a name that matches `.*(Co|Deco)mpression` and
I/O types have a codec name with `Stream` suffix. All codecs are a subtype
`TranscodingStreams.Codec` and streams are a subtype of `Base.IO`. An important
thing is these packages depend on TranscodingStreams.jl and not *vice versa*.
This means you can install any codec package you need without installing all
codec packages.  Also, if you want to define your own codec, it is totally
feasible like these packages.  TranscodingStreams.jl requests a codec to
implement some interface functions which will be described later.


Error handling
--------------

You may encounter an error while processing data with this package. For example,
your compressed data may be corrupted or truncated and the decompressor codec
cannot handle it properly. In this case, the codec informs the stream of the
error and the stream goes to an unrecoverable mode. In this mode, the only
possible operations are `isopen` and `close`. Other operations, such as `read`
or `write`, will result in an argument error exception. Resources allocated in
the codec will be released by the stream and hence you must not call the
finalizer of a codec that is once passed to a transcoding stream object.
