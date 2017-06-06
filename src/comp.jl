#const threshold = 1e-8

_isapproxzero{T<:Real}(x::T, ztol) = x == zero(T)
_isapproxzero{T<:AbstractFloat}(x::T, ztol) = -ztol < x < ztol
_isapproxzero{T<:Real}(x::Vector{T}, ztol) = _isapproxzero(sum(abs, x), ztol)

_isapprox{T<:Real}(x::T, y::T, ztol) = x == y
# I check with zero because isapprox(0, 1e-100) is false...
# but isapprox(1e-100, 2e-100) should be false
_isapprox{T<:AbstractFloat}(x::T, y::T, ztol) = (x == zero(T) ? _isapproxzero(y, ztol) : (y == zero(T) ? _isapproxzero(x, ztol) : isapprox(x, y)))
_isapprox{T<:Real, S<:Real}(x::T, y::S) = _isapprox(promote(x, y)...)
_isapprox{T<:AbstractFloat}(x::Vector{T}, y::Vector{T}, ztol) = (x == zero(x) ? _isapproxzero(y, ztol) : (y == zero(y) ? _isapproxzero(x, ztol) : isapprox(x, y)))

_lt{T<:Real}(x::T, y::T, ztol) = x < y
_lt{T<:AbstractFloat}(x::T, y::T, ztol) = x < y && !_isapprox(x, y, ztol)
_lt{S<:Real,T<:Real}(x::S, y::T, ztol) = _lt(promote(x, y)..., ztol)
# _gt{S<:Real, T<:Real}(x::S, y::T) = _lt(y, x)
# _leq{T<:Real}(x::T, y::T) = x <= y
# _leq{T<:AbstractFloat}(x::T, y::T) = x <= y || _isapprox(x, y)
# _leq{S<:Real,T<:Real}(x::S, y::T) = myleq(promote(x, y)...)
# _geq{T<:Real}(x::T, y::T) = myleq(y, x)
# _pos{T<:Real}(x::T) = mygt(x, zero(T))
# _neg{T<:Real}(x::T) = _lt(x, zero(T))
# _nonneg{T<:Real}(x::T) = mygeq(x, zero(T))
# _nonpos{T<:Real}(x::T) = myleq(x, zero(T))
