export AbstractPathSampler
abstract type AbstractPathSampler end

function _samplepaths!(_npaths, npaths, pmf, semirandom::Bool, canmodifypmf::Bool)
    if semirandom
        sampled = 0
        for i in 1:length(pmf)
            p = pmf[i]
            n = floor(Int, p * npaths + 1e-6)
            if n > 0
                if sampled == 0 && !canmodifypmf
                    pmf = copy(pmf)
                end
                pmf[i] -= n / npaths
                _npaths[i] += n
                sampled += n
            end
        end
        if sampled < npaths
            if sampled > 0
                # sum(pmf) should be equal to (npaths - sampled) / npaths
                # since we have removed sampled / npaths
                # pmf is not modified as it could be the vector of probas
                pmf ./= (npaths - sampled) / npaths
                npaths -= sampled
            end
            _samplepaths!(_npaths, npaths, pmf, false, true)
        else
            _npaths
        end
    else
        cmf = cumsum(pmf)
        @assert isapprox(cmf[end], 1)
        cmf[end] = 1
        samples = rand(Float64, npaths)
        sort!(samples)
        i = 1
        for j in samples
            while j >= cmf[i]
                i += 1
            end
            _npaths[i] += 1
        end
        _npaths
    end
end
function _samplepaths(npaths, pmf, semirandom::Bool, canmodifypmf::Bool)
    _samplepaths!(zeros(Int, length(pmf)), npaths, pmf, semirandom, canmodifypmf)
end
infpaths(g, node) = fill(-1, outdegree(g, node))

function samplepaths(pathsampler::AbstractPathSampler, sp::AbstractStochasticProgram, node, npaths::Vector{Int}, t, num_stages)
    npathss = Vector{Int}[similar(npaths) for i in 1:outdegree(sp, node)]
    for i in 1:length(npaths)
        _npaths = samplepaths(pathsampler, sp, node, npaths[i], t, num_stages)
        for c in 1:outdegree(sp, node)
            npathss[c][i] = _npaths[c]
        end
    end
    npathss
end

struct ProbaPathSampler <: AbstractPathSampler
    semirandom::Bool
end
function samplepaths(pathsampler::ProbaPathSampler, g::AbstractStochasticProgram, node, npaths::Int, t, num_stages)
    if npaths == -1
        infpaths(g, node)
    else
        pmf = probability.(g, out_transitions(g, node))
        _samplepaths(npaths, pmf, pathsampler.semirandom, false)
    end
end

struct NumPathsPathSampler <: AbstractPathSampler
    semirandom::Bool
end
function samplepaths(pathsampler::NumPathsPathSampler, g::AbstractStochasticProgram, node, npaths::Int, t, num_stages)
    if npaths == -1
        infpaths(g, node)
    else
        den = numberofpaths(g, node, t-1, num_stages)
        pmf = map(tr->numberofpaths(g, target(tr), t, num_stages) / den, out_transitions(g, node))
        _samplepaths(npaths, pmf, pathsampler.semirandom, true)
    end
end
