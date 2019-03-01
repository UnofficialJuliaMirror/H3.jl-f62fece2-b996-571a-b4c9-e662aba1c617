module API # module H3

# types
export H3Index, GeoCoord, CoordIJ, Vec2d, Vec3d, CoordIJK, FaceIJK

# Indexing functions
export geoToH3, h3ToGeo, h3ToGeoBoundary

# Index inspection functions
export h3GetResolution, h3GetBaseCell, stringToH3, h3ToString, h3IsValid, h3IsResClassIII, h3IsPentagon

# Grid traversal functions
export kRing, maxKringSize, kRingDistances, hexRange, hexRangeDistances, hexRanges, hexRing, h3Line, h3LineSize, h3Distance, experimentalH3ToLocalIj, experimentalLocalIjToH3

# Hierarchical grid functions
export h3ToParent, h3ToChildren, maxH3ToChildrenSize, compact, uncompact, maxUncompactSize

# Region functions
export polyfill, maxPolyfillSize, h3SetToLinkedGeo, destroyLinkedPolygon

# Unidirectional edge functions
export h3IndexesAreNeighbors, getH3UnidirectionalEdge, h3UnidirectionalEdgeIsValid, getOriginH3IndexFromUnidirectionalEdge, getDestinationH3IndexFromUnidirectionalEdge, getH3IndexesFromUnidirectionalEdge, getH3UnidirectionalEdgesFromHexagon, getH3UnidirectionalEdgeBoundary

# Miscellaneous H3 functions
export degsToRads, radsToDegs, hexAreaKm2, hexAreaM2, edgeLengthKm, edgeLengthM, numHexagons, getRes0Indexes, res0IndexCount

# Coordinate Systems
export ijkToHex2d, hex2dToCoordIJK, h3ToFaceIjk, geoToVec3d, geoToFaceIjk, ijkNormalize


using ..Lib
using .Lib: H3Index, GeoCoord, GeoBoundary, CoordIJ, GeoPolygon, LinkedGeoPolygon
using .Lib: Vec2d, Vec3d, CoordIJK, FaceIJK

###
#
# * the documents taken from
#   - https://github.com/uber/h3/tree/master/docs/api
#   - https://github.com/uber/h3/blob/master/src/h3lib/include/h3api.h.in
#
###


# Indexing functions

"""
    geoToH3(location::GeoCoord, resolution::Int)::H3Index

Indexes the location at the specified resolution.
"""
function geoToH3(location::GeoCoord, resolution::Int)::H3Index
    Lib.geoToH3(Ref(location), resolution)
end

"""
    h3ToGeo(h::H3Index)::GeoCoord

Finds the centroid of the index.
"""
function h3ToGeo(h::H3Index)::GeoCoord
    refcenter = Ref{GeoCoord}()
    Lib.h3ToGeo(h, refcenter)
    refcenter[]
end

"""
    h3ToGeoBoundary(h::H3Index)::Vector{GeoCoord}

Finds the boundary of the index.
"""
function h3ToGeoBoundary(h::H3Index)::Vector{GeoCoord}
    refboundary = Ref{GeoBoundary}()
    Lib.h3ToGeoBoundary(h, refboundary)
    numVerts = refboundary[].numVerts
    verts = refboundary[].verts[1:numVerts]
    collect(verts)
end


# Index inspection functions

"""
    h3GetResolution(h::H3Index)::Int

Returns the resolution of the index.
"""
function h3GetResolution(h::H3Index)::Int
    Lib.h3GetResolution(h)
end

"""
    h3GetBaseCell(h::H3Index)::Int

Returns the base cell number of the index.
"""
function h3GetBaseCell(h::H3Index)::Int
    Lib.h3GetBaseCell(h)
end

"""
    stringToH3(str::String)::H3Index

Converts the string representation to H3Index (UInt64) representation.
"""
function stringToH3(str::String)::H3Index
    Lib.stringToH3(str)
end

"""
    h3ToString(h::H3Index)::String

Converts the H3Index representation of the index to the string representation.
"""
function h3ToString(h::H3Index)::String
    bufSz = 17
    buf = Base.unsafe_convert(Cstring, "")
    Lib.h3ToString(h, buf, bufSz)
    Base.unsafe_string(buf)
end

"""
    h3IsValid(h::H3Index)::Bool

Returns `true` if this is a valid H3 index.
"""
function h3IsValid(h::H3Index)::Bool
    Bool(Lib.h3IsValid(h))
end

"""
    h3IsResClassIII(h::H3Index)::Bool

Returns `true` if this index has a resolution with Class III orientation.
"""
function h3IsResClassIII(h::H3Index)::Bool
    Bool(Lib.h3IsResClassIII(h))
end

"""
    h3IsPentagon(h::H3Index)::Bool

Returns `true` if this index represents a pentagonal cell.
"""
function h3IsPentagon(h::H3Index)::Bool
    Bool(Lib.h3IsPentagon(h))
end


# Grid traversal functions

"""
    kRing(origin::H3Index, k::Int)::Vector{H3Index}

k-rings produces indices within `k` distance of the origin index.
"""
function kRing(origin::H3Index, k::Int)::Vector{H3Index}
    array_len = Lib.maxKringSize(k)
    krings = Vector{H3Index}(undef, array_len)
    Lib.kRing(origin, k, krings)
    krings
end

"""
    maxKringSize(k::Int)::Int

Maximum number of indices that result from the kRing algorithm with the given `k`.
"""
function maxKringSize(k::Int)::Int
    Lib.maxKringSize(k)
end

"""
    kRingDistances(origin::H3Index, k::Int)::NamedTuple{(:out, :distances)}

k-rings produces indices within `k` distance of the origin index.
"""
function kRingDistances(origin::H3Index, k::Int)::NamedTuple{(:out, :distances)}
    array_len = Lib.maxKringSize(k)
    out = Vector{H3Index}(undef, array_len)
    distances = Vector{Cint}(undef, array_len)
    Lib.kRingDistances(origin, k, out, distances)
    (out = out, distances = distances)
end

"""
    hexRange(origin::H3Index, k::Int)::Vector{H3Index}

`hexRange` produces indexes within `k` distance of the origin index.
"""
function hexRange(origin::H3Index, k::Int)::Vector{H3Index}
    array_len = Lib.maxKringSize(k)
    out = Vector{H3Index}(undef, array_len)
    Lib.hexRange(origin, k, out)
    out
end

"""
    hexRangeDistances(origin::H3Index, k::Int)::NamedTuple{(:out, :distances)}

`hexRange` produces indexes within `k` distance of the origin index.
"""
function hexRangeDistances(origin::H3Index, k::Int)::NamedTuple{(:out, :distances)}
    array_len = Lib.maxKringSize(k)
    out = Vector{H3Index}(undef, array_len)
    distances = Vector{Cint}(undef, array_len)
    Lib.hexRangeDistances(origin, k, out, distances)
    (out = out, distances = distances)
end

"""
    hexRanges(h3Set::Vector{H3Index}, k::Int)::Vector{H3Index}

`hexRanges` takes an array of input hex IDs and a max k-ring and returns an array of hexagon IDs sorted first by the original hex IDs and then by the k-ring (0 to max), with no guaranteed sorting within each k-ring group.
"""
function hexRanges(h3Set::Vector{H3Index}, k::Int)::Vector{H3Index}
    array_len = Lib.maxKringSize(k)
    out = Vector{H3Index}(undef, array_len)
    Lib.hexRanges(h3Set, length(h3Set), k, out)
    out
end

"""
    hexRing(origin::H3Index, k::Int)::Vector{H3Index}

Produces the hollow hexagonal ring centered at `origin` with sides of length `k`.
"""
function hexRing(origin::H3Index, k::Int)::Vector{H3Index}
    out = Vector{H3Index}(undef, 6k)
    Lib.hexRing(origin, k, out)
    out
end

"""
    h3Line(origin::H3Index, destination::H3Index)::Vector{H3Index}

Given two H3 indexes, return the line of indexes between them (inclusive).
"""
function h3Line(origin::H3Index, destination::H3Index)::Vector{H3Index}
    line_size = Lib.h3LineSize(origin, destination)
    out = Vector{H3Index}(undef, line_size)
    Lib.h3Line(origin, destination, out)
    out
end

"""
    h3LineSize(origin::H3Index, destination::H3Index)::Int

Number of indexes in a line from the start index to the end index, to be used for allocating memory.
"""
function h3LineSize(origin::H3Index, destination::H3Index)::Int
    Lib.h3LineSize(origin, destination)
end

"""
    h3Distance(origin::H3Index, h::H3Index)::Int

Returns the distance in grid cells between the two indexes.
"""
function h3Distance(origin::H3Index, h::H3Index)::Int
    Lib.h3Distance(origin, h)
end

"""
    experimentalH3ToLocalIj(origin::H3Index, h::H3Index)::CoordIJ

Produces local IJ coordinates for an H3 index anchored by an origin.
"""
function experimentalH3ToLocalIj(origin::H3Index, h::H3Index)::CoordIJ
    refij = Ref{CoordIJ}()
    Lib.experimentalH3ToLocalIj(origin, h, refij)
    refij[]
end

"""
    experimentalLocalIjToH3(origin::H3Index, ij::CoordIJ)::H3Index

Produces an H3 index from local IJ coordinates anchored by an `origin`.
"""
function experimentalLocalIjToH3(origin::H3Index, ij::CoordIJ)::H3Index
    refh = Ref{H3Index}()
    Lib.experimentalLocalIjToH3(origin, Ref(ij), refh)
    refh[]
end


# Hierarchical grid functions

"""
    h3ToParent(h::H3Index, parentRes::Integer)::H3Index

Returns the parent (coarser) index containing h.
"""
function h3ToParent(h::H3Index, parentRes::Integer)::H3Index
    Lib.h3ToParent(h, parentRes)
end

"""
    h3ToChildren(h::H3Index, childRes::Integer)::Vector{H3Index}

Populates children with the indexes contained by h at resolution childRes. children must be an array of at least size maxH3ToChildrenSize(h, childRes).
"""
function h3ToChildren(h::H3Index, childRes::Integer)::Vector{H3Index}
    children_size = Lib.maxH3ToChildrenSize(h, childRes)
    children = Vector{H3Index}(undef, children_size)
    Lib.h3ToChildren(h, childRes, children)
    children
end

"""
    maxH3ToChildrenSize(h::H3Index, childRes::Integer)::Int

Returns the size of the array needed by h3ToChildren for these inputs.
"""
function maxH3ToChildrenSize(h::H3Index, childRes::Integer)::Int
    Lib.maxH3ToChildrenSize(h, childRes)
end

"""
    compact(h3Set::Vector{H3Index})::Vector{H3Index}

Compacts the set h3Set of indexes as best as possible, into the array compactedSet. compactedSet must be at least the size of h3Set in case the set cannot be compacted.
"""
function compact(h3Set::Vector{H3Index})::Vector{H3Index}
    numHexes = length(h3Set)
    compactedSet = Vector{H3Index}(undef, numHexes)
    Lib.compact(h3Set, compactedSet, numHexes)
    compactedSet
end

"""
    uncompact(compactedSet::Vector{H3Index}, res::Int)::Vector{H3Index}

Uncompacts the set compactedSet of indexes to the resolution res.
"""
function uncompact(compactedSet::Vector{H3Index}, res::Int)::Vector{H3Index}
    hexCount = length(compactedSet)
    maxHexes = Lib.maxUncompactSize(compactedSet, hexCount, res)
    h3Set = Vector{H3Index}(undef, maxHexes)
    Lib.uncompact(compactedSet, hexCount, h3Set, maxHexes, res)
    h3Set
end

"""
    maxUncompactSize(compactedSet::Vector{H3Index}, res::Int)::Int

Returns the size of the array needed by uncompact.
"""
function maxUncompactSize(compactedSet::Vector{H3Index}, res::Int)::Int
    hexCount = length(compactedSet)
    Lib.maxUncompactSize(compactedSet, hexCount, res)
end


# Region functions

"""
    polyfill(geoPolygon::GeoPolygon, res::Int)::Vector{H3Index}
"""
function polyfill(geoPolygon::GeoPolygon, res::Int)::Vector{H3Index}
    numHexagons = Lib.maxPolyfillSize(Ref(geoPolygon), res)
    out = Vector{H3Index}(undef, numHexagons)
    Lib.polyfill(Ref(geoPolygon), res, out)
    out
end

"""
    maxPolyfillSize(geoPolygon::GeoPolygon, res::Int)::Int

maxPolyfillSize returns the number of hexagons to allocate space for when performing a polyfill on the given GeoJSON-like data structure.
"""
function maxPolyfillSize(geoPolygon::GeoPolygon, res::Int)::Int
    Lib.maxPolyfillSize(Ref(geoPolygon), res)
end

"""
    h3SetToLinkedGeo(h3Set::Vector{H3Index})::Ref{LinkedGeoPolygon}

Create a LinkedGeoPolygon describing the outline(s) of a set of hexagons. Polygon outlines will follow GeoJSON MultiPolygon order: Each polygon will have one outer loop, which is first in the list, followed by any holes.
"""
function h3SetToLinkedGeo(h3Set::Vector{H3Index})::Ref{LinkedGeoPolygon}
    refpolygon = Ref{LinkedGeoPolygon}(LinkedGeoPolygon(C_NULL,C_NULL,C_NULL))
    Lib.h3SetToLinkedGeo(C_NULL, 0, refpolygon)
    refpolygon
end

"""
    destroyLinkedPolygon(polygon::Ref{LinkedGeoPolygon})

Free all allocated memory for a linked geo structure. The caller is responsible for freeing memory allocated to the input polygon struct.
"""
function destroyLinkedPolygon(refpolygon::Ref{LinkedGeoPolygon})
    Lib.destroyLinkedPolygon(refpolygon)
end


# Unidirectional edge functions

"""
    h3IndexesAreNeighbors(origin::H3Index, destination::H3Index)::Bool

Returns whether or not the provided H3Indexes are neighbors.
Returns `true` if the indexes are neighbors, `false` otherwise.
"""
function h3IndexesAreNeighbors(origin::H3Index, destination::H3Index)::Bool
    Bool(Lib.h3IndexesAreNeighbors(origin, destination))
end

"""
    getH3UnidirectionalEdge(origin::H3Index, destination::H3Index)::H3Index

Returns a unidirectional edge H3 index based on the provided origin and destination.
"""
function getH3UnidirectionalEdge(origin::H3Index, destination::H3Index)::H3Index
    Lib.getH3UnidirectionalEdge(origin, destination)
end

"""
    h3UnidirectionalEdgeIsValid(edge::H3Index)::Bool

Determines if the provided H3Index is a valid unidirectional edge index.
Returns `true` if it is a unidirectional edge H3Index, otherwise `false`.
"""
function h3UnidirectionalEdgeIsValid(edge::H3Index)::Bool
    Bool(Lib.h3UnidirectionalEdgeIsValid(edge))
end

"""
    getOriginH3IndexFromUnidirectionalEdge(edge::H3Index)::H3Index

Returns the origin hexagon from the unidirectional edge H3Index.
"""
function getOriginH3IndexFromUnidirectionalEdge(edge::H3Index)::H3Index
    Lib.getOriginH3IndexFromUnidirectionalEdge(edge)
end

"""
    getDestinationH3IndexFromUnidirectionalEdge(edge::H3Index)::H3Index

Returns the destination hexagon from the unidirectional edge H3Index.
"""
function getDestinationH3IndexFromUnidirectionalEdge(edge::H3Index)::H3Index
    Lib.getDestinationH3IndexFromUnidirectionalEdge(edge)
end

"""
    getH3IndexesFromUnidirectionalEdge(edge::H3Index)::Tuple{H3Index, H3Index}

Returns the origin, destination pair of hexagon IDs for the given edge ID, which are placed at originDestination[0] and originDestination[1] respectively.
"""
function getH3IndexesFromUnidirectionalEdge(edge::H3Index)::Tuple{H3Index, H3Index}
    originDestination = Vector{H3Index}(undef, 2)
    Lib.getH3IndexesFromUnidirectionalEdge(edge, originDestination)
    tuple(originDestination...)
end

"""
    getH3UnidirectionalEdgesFromHexagon(origin::H3Index)::Vector{H3Index}

Provides all of the unidirectional edges from the current H3Index. edges must be of length 6, and the number of undirectional edges placed in the array may be less than 6.
"""
function getH3UnidirectionalEdgesFromHexagon(origin::H3Index)::Vector{H3Index}
    edges = Vector{H3Index}(undef, 6)
    Lib.getH3UnidirectionalEdgesFromHexagon(origin, edges)
    edges
end

"""
    getH3UnidirectionalEdgeBoundary(edge::H3Index)::Vector{GeoCoord}

Provides the coordinates defining the unidirectional edge.
"""
function getH3UnidirectionalEdgeBoundary(edge::H3Index)::Vector{GeoCoord}
    refboundary = Ref{GeoBoundary}()
    Lib.getH3UnidirectionalEdgeBoundary(edge, refboundary)
    numVerts = refboundary[].numVerts
    verts = refboundary[].verts[1:numVerts]
    collect(verts)
end


# Miscellaneous H3 functions

"""
    degsToRads(degrees::Union{Cdouble,Integer})::Cdouble

Converts degrees to radians.
"""
function degsToRads(degrees::Union{Cdouble,Integer})::Cdouble
    Lib.degsToRads(degrees)
end

"""
    radsToDegs(radians::Union{Cdouble,Integer})::Cdouble

Converts radians to degrees.
"""
function radsToDegs(radians::Union{Cdouble,Integer})::Cdouble
    Lib.radsToDegs(radians)
end

"""
    hexAreaKm2(res::Integer)::Cdouble

Average hexagon area in square kilometers at the given resolution.
"""
function hexAreaKm2(res::Integer)::Cdouble
    Lib.hexAreaKm2(res)
end

"""
    hexAreaM2(res::Integer)::Cdouble

Average hexagon area in square meters at the given resolution.
"""
function hexAreaM2(res::Integer)::Cdouble
    Lib.hexAreaM2(res)
end

"""
    edgeLengthKm(res::Integer)::Cdouble

Average hexagon edge length in kilometers at the given resolution.
"""
function edgeLengthKm(res::Integer)::Cdouble
    Lib.edgeLengthKm(res)
end

"""
    edgeLengthM(res::Integer)::Cdouble

Average hexagon edge length in meters at the given resolution.
"""
function edgeLengthM(res::Integer)::Cdouble
    Lib.edgeLengthM(res)
end

"""
    numHexagons(res::Integer)::Int64

Number of unique H3 indexes at the given resolution.
"""
function numHexagons(res::Integer)::Int64
    Lib.numHexagons(res)
end

"""
    getRes0Indexes()::Vector{H3Index}

All the resolution 0 H3 indexes.
"""
function getRes0Indexes()::Vector{H3Index}
    out = Vector{H3Index}(undef, Lib.res0IndexCount() * sizeof(H3Index))
    Lib.getRes0Indexes(out)
    out
end

"""
    res0IndexCount()::Cint

Number of resolution 0 H3 indexes.
"""
function res0IndexCount()::Int
    Lib.res0IndexCount()
end


### Coordinate Systems

"""
    ijkToHex2d(c::CoordIJK)::Vec2d

Find the center point in 2D cartesian coordinates of a hex.
"""
function ijkToHex2d(c::CoordIJK)::Vec2d
    ref = Ref{Vec2d}()
    ccall((:_ijkToHex2d, Lib.libh3), Cvoid, (Ptr{CoordIJK}, Ptr{Vec2d}), Ref(c), ref)
    ref[]
end

"""
    hex2dToCoordIJK(v::Vec2d)::CoordIJK

Determine the containing hex in ijk+ coordinates for a 2D cartesian coordinate vector (from DGGRID).
"""
function hex2dToCoordIJK(v::Vec2d)::CoordIJK
    ref = Ref{CoordIJK}()
    ccall((:_hex2dToCoordIJK, Lib.libh3), Cvoid, (Ptr{Vec2d}, Ptr{CoordIJK}), Ref(v), ref)
    ref[]
end

"""
    ijkNormalize(c::CoordIJK)::CoordIJK

Normalizes ijk coordinates by setting the components to the smallest possible values. Works in place.
"""
function ijkNormalize(c::CoordIJK)::CoordIJK
    ref = Ref(c)
    ccall((:_ijkNormalize, Lib.libh3), Cvoid, (Ptr{CoordIJK},), ref)
    ref[]
end

"""
    h3ToFaceIjk(h::H3Index)::FaceIJK

Convert an H3Index to a FaceIJK address.
"""
function h3ToFaceIjk(h::H3Index)::FaceIJK
    ref = Ref{FaceIJK}()
    ccall((:_h3ToFaceIjk, Lib.libh3), Cvoid, (H3Index, Ptr{FaceIJK}), h, ref)
    ref[]
end

"""
    geoToVec3d(geo::GeoCoord)::Vec3d

Calculate the 3D coordinate on unit sphere from the latitude and longitude.
"""
function geoToVec3d(geo::GeoCoord)::Vec3d
    ref = Ref{Vec3d}()
    ccall((:_geoToVec3d, Lib.libh3), Cvoid, (Ptr{GeoCoord}, Ptr{Vec3d}), Ref(geo), ref)
    ref[]
end

"""
    geoToFaceIjk(geo::GeoCoord, res::Int)::FaceIJK

Encodes a coordinate on the sphere to the FaceIJK address of the containing cell at the specified resolution.
"""
function geoToFaceIjk(geo::GeoCoord, res::Int)::FaceIJK
    ref = Ref{FaceIJK}()
    ccall((:_geoToFaceIjk, Lib.libh3), Cvoid, (Ptr{GeoCoord}, Cint, Ptr{FaceIJK}), Ref(geo), res, ref)
    ref[]
end


### ≈

function Base.isapprox(A::Vector{GeoCoord}, B::Vector{GeoCoord})
    A === B && return true
    axes(A) != axes(B) && return false
    for (a, b) in zip(A, B)
        if !(isapprox(a.lat, b.lat) && isapprox(a.lon, b.lon))
            return false
        end
    end
    return true
end

function Base.isapprox(A::Vector{Tuple{Float64,Float64}}, B::Vector{Tuple{Float64,Float64}})
    A === B && return true
    axes(A) != axes(B) && return false
    for (a, b) in zip(A, B)
        if !(isapprox(a[1], b[1]) && isapprox(a[2], b[2]))
            return false
        end
    end
    return true
end

end # module H3.API
