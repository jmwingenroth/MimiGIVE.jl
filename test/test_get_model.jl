module TestGetModel

using MimiGIVE
using Test
using MooreAg

import MimiGIVE: get_model, compute_scc

# This module will test that the public facing API (1) runs without error
# (2) picks up relevant keyword arguments and (2) produces outputs of the 
# expected dimensions and types

##------------------------------------------------------------------------------
## get_model
##------------------------------------------------------------------------------

# function get_model(; 
#     Agriculture_gtap::String = "midDF",
#     socioeconomics_source::Symbol = :RFF,
#     SSP_scenario::Union{Nothing, String} = nothing,       
#     RFFSPsample::Union{Nothing, Int} = nothing,
#     Agriculture_floor_on_damages::Bool = true,
#     Agriculture_ceiling_on_benefits::Bool = false,
#     vsl::Symbol= :epa
# )

##------------------------------------------------------------------------------
## full API - ensure all possible combinations of keyword args run without error
##------------------------------------------------------------------------------

m = get_model()
run(m)

# RFF socioeconomics
for Agriculture_gtap in ["AgMIP_AllDF", "AgMIP_NoNDF", "highDF", "lowDF", "midDF"]
    for RFFSPsample in [1,2]
        for Agriculture_floor_on_damages in [true, false]
            for Agriculture_ceiling_on_benefits in [true, false]
                for vsl in [:epa, :fund]
                    get_model(;Agriculture_gtap = Agriculture_gtap, 
                                socioeconomics_source = :RFF,
                                RFFSPsample = RFFSPsample,
                                Agriculture_floor_on_damages = Agriculture_floor_on_damages,
                                Agriculture_ceiling_on_benefits = Agriculture_ceiling_on_benefits,
                                vsl = vsl)
                end
            end
        end
    end
end

# SSP socioeconomics
for Agriculture_gtap in ["AgMIP_AllDF", "AgMIP_NoNDF", "highDF", "lowDF", "midDF"]
    for SSP_scenario in ["SSP126", "SSP245", "SSP370", "SSP585"]
        for Agriculture_floor_on_damages in [true, false]
            for Agriculture_ceiling_on_benefits in [true, false]
                for vsl in [:epa, :fund]
                    get_model(;Agriculture_gtap = Agriculture_gtap, 
                                socioeconomics_source = :SSP,
                                SSP_scenario = SSP_scenario, 
                                Agriculture_floor_on_damages = Agriculture_floor_on_damages,
                                Agriculture_ceiling_on_benefits = Agriculture_ceiling_on_benefits,
                                vsl = vsl)
                end
            end
        end
    end
end

##------------------------------------------------------------------------------
## keyword arguments and values
##------------------------------------------------------------------------------

# Agriculture GTAP Parameter (Agriculture_gtap)

sccs = []
agcosts = []

for Agriculture_gtap in ["AgMIP_AllDF", "AgMIP_NoNDF", "highDF", "lowDF", "midDF"]
    m = get_model(; Agriculture_gtap=Agriculture_gtap)
    run(m)
    
    append!(sccs, compute_scc(m, year=2020))
    append!(agcosts, sum(skipmissing(m[:Agriculture, :agcost])))
    gtap_idx = findfirst(isequal(Agriculture_gtap), MooreAg.gtaps)

    @test m[:Agriculture, :gtap_df] == MooreAg.gtap_df_all[:, :, gtap_idx]
end

@test allunique(sccs)
@test allunique(agcosts)

# socioeconomics_source and SSP_scenario and RFFSPsample

sccs = []
co2_emissions = []
gdp = []
pop = []

for id in [1,2,3]
    m_rff = get_model(;RFFSPsample=id)
    run(m_rff)

    append!(sccs, compute_scc(m_rff, year=2020))
    push!(co2_emissions, m_rff[:Socioeconomic, :co2_emissions])
    push!(gdp, m_rff[:Socioeconomic, :gdp_global])
    push!(pop, m_rff[:Socioeconomic, :population_global])

    @test(m_rff[:Socioeconomic, :id] == id)
end
for ssp in ["SSP126", "SSP245", "SSP370", "SSP585"]
    m_ssp = get_model(;socioeconomics_source=:SSP, SSP_scenario=ssp)
    run(m_ssp)

    append!(sccs, compute_scc(m_ssp, year=2020))
    push!(co2_emissions, m_ssp[:Socioeconomic, :co2_emissions])
    push!(gdp, m_ssp[:Socioeconomic, :gdp_global])
    push!(pop, m_ssp[:Socioeconomic, :population_global])

    @test(m_ssp[:Socioeconomic, :SSP] == ssp[1:4])
    @test(m_ssp[:Socioeconomic, :emissions_scenario] == ssp)
end

@test allunique(sccs)
for i in 1:length(gdp), j in 1:length(gdp)
    if i !== j
        @test gdp[i] !== gdp[j]
        @test pop[i] !== pop[j]
        @test co2_emissions[i] !== co2_emissions[j]
    end
end

# vsl
m_epa = get_model(vsl=:epa)
m_fund = get_model(vsl=:fund)
run(m_epa)
run(m_fund)
@test skipmissing(m_epa[:VSL, :vsl]) !== skipmissing(m_fund[:VSL, :vsl])

end # module
