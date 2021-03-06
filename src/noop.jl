# Noop Codec
# ==========

"""
    Noop()

Create a noop codec.

Noop (no operation) is a codec that does nothing. The data read from or written
to the stream are kept as-is without any modification. This is often useful as a
buffered stream or an identity element of a composition of streams.

The implementations are specialized for this codec. For example, a `Noop` stream
uses only one buffer rather than a pair of buffers, which avoids copying data
between two buffers and the throughput will be larger than a naive
implementation.
"""
struct Noop <: Codec end

const NoopStream{S} = TranscodingStream{Noop,S} where S<:IO

"""
    NoopStream(stream::IO)

Create a noop stream.
"""
function NoopStream(stream::IO; kwargs...)
    return TranscodingStream(Noop(), stream; kwargs...)
end

function TranscodingStream(codec::Noop, stream::IO;
                           bufsize::Integer=DEFAULT_BUFFER_SIZE,
                           sharedbuf::Bool=(stream isa TranscodingStream))
    checkbufsize(bufsize)
    checksharedbuf(sharedbuf, stream)
    if sharedbuf
        buffer = stream.state.buffer1
    else
        buffer = Buffer(bufsize)
    end
    return TranscodingStream(codec, stream, State(buffer, buffer))
end

"""
    position(stream::NoopStream)

Get the current poition of `stream`.

Note that this method may return a wrong position when
- some data have been inserted by `TranscodingStreams.unread`, or
- the position of the wrapped stream has been changed outside of this package.
"""
function Base.position(stream::NoopStream)
    return position(stream.stream) - buffersize(stream.state.buffer1)
end

function Base.seek(stream::NoopStream, pos::Integer)
    seek(stream.stream, pos)
    initbuffer!(stream.state.buffer1)
    return
end

function Base.seekstart(stream::NoopStream)
    seekstart(stream.stream)
    initbuffer!(stream.state.buffer1)
    return
end

function Base.seekend(stream::NoopStream)
    seekend(stream.stream)
    initbuffer!(stream.state.buffer1)
    return
end

function Base.unsafe_read(stream::NoopStream, output::Ptr{UInt8}, nbytes::UInt)
    changemode!(stream, :read)
    buffer = stream.state.buffer1
    p = output
    p_end = output + nbytes
    while p < p_end && !eof(stream)
        if buffersize(buffer) > 0
            m = min(buffersize(buffer), p_end - p)
            copydata!(p, buffer, m)
        else
            # directly read data from the underlying stream
            m = p_end - p
            Base.unsafe_read(stream.stream, p, m)
        end
        p += m
    end
    if p < p_end && eof(stream)
        throw(EOFError())
    end
    return
end

function Base.unsafe_write(stream::NoopStream, input::Ptr{UInt8}, nbytes::UInt)
    changemode!(stream, :write)
    buffer = stream.state.buffer1
    if marginsize(buffer) ≥ nbytes
        copydata!(buffer, input, nbytes)
        return Int(nbytes)
    else
        flushbuffer(stream)
        # directly write data to the underlying stream
        return unsafe_write(stream.stream, input, nbytes)
    end
end

function Base.transcode(::Noop, data::Vector{UInt8})
    # Copy data because the caller may expect the return object is not the same
    # as from the input.
    return copy(data)
end


# Stats
# -----

function stats(stream::NoopStream)
    state = stream.state
    mode = state.mode
    @checkmode (:idle, :read, :write)
    buffer = state.buffer1
    @assert buffer == stream.state.buffer2
    if mode == :idle
        consumed = supplied = 0
    elseif mode == :read
        supplied = buffer.total
        consumed = supplied - buffersize(buffer)
    elseif mode == :write
        supplied = buffer.total + buffersize(buffer)
        consumed = buffer.total
    else
        assert(false)
    end
    return Stats(consumed, supplied, supplied, supplied)
end


# Buffering
# ---------
#
# These methods are overloaded for the `Noop` codec because it has only one
# buffer for efficiency.

function fillbuffer(stream::NoopStream)
    changemode!(stream, :read)
    buffer = stream.state.buffer1
    @assert buffer === stream.state.buffer2
    if stream.stream isa TranscodingStream && buffer === stream.stream.state.buffer1
        # Delegate the operation when buffers are shared.
        return fillbuffer(stream.stream)
    end
    nfilled::Int = 0
    while buffersize(buffer) == 0 && !eof(stream.stream)
        makemargin!(buffer, 1)
        nfilled += readdata!(stream.stream, buffer)
    end
    buffer.total += nfilled
    return nfilled
end

function flushbuffer(stream::NoopStream, all::Bool=false)
    changemode!(stream, :write)
    buffer = stream.state.buffer1
    @assert buffer === stream.state.buffer2
    nflushed::Int = 0
    if all
        while buffersize(buffer) > 0
            nflushed += writedata!(stream.stream, buffer)
        end
    else
        nflushed += writedata!(stream.stream, buffer)
        makemargin!(buffer, 0)
    end
    buffer.total += nflushed
    return nflushed
end

function flushuntilend(stream::NoopStream)
    stream.state.buffer1.total += writedata!(stream.stream, stream.state.buffer1)
    return
end
