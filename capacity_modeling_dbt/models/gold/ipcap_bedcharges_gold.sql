{{ config(materialized='table') }}

with silver as (
    select *
    from {{ ref('ipcap_bedcharges_silver') }}
),

aggregated as (
    select
        FACILITY_MSX,
        ENCOUNTER_NO,
        MSMRN,
        DSCH_DT_SRC,
        ADMIT_DT_SRC,
        MSDRG_CD_SRC,
        LOC_NAME,
        ATTENDING_VERITY_REPORT_SERVICE,
        DSCH_UNIT_DESC_MSX,
        EXTERNAL_NAME,
        SERVICE_GROUP,
        SERVICE_MONTH,
        SERVICE_DATE,
        LOS_NO_SRC,
        coalesce(sum(QUANTITY), 0) as BED_CHARGES
    from silver
    group by
        FACILITY_MSX,
        ENCOUNTER_NO,
        MSMRN,
        DSCH_DT_SRC,
        ADMIT_DT_SRC,
        MSDRG_CD_SRC,
        LOC_NAME,
        ATTENDING_VERITY_REPORT_SERVICE,
        DSCH_UNIT_DESC_MSX,
        EXTERNAL_NAME,
        SERVICE_GROUP,
        SERVICE_MONTH,
        SERVICE_DATE,
        LOS_NO_SRC
),

final as (
    select
        * except (BED_CHARGES),
        case
            when BED_CHARGES > 1 then 1
            else BED_CHARGES
        end as BED_CHARGES,
        current_timestamp() as CREATED_DATETIME
    from aggregated
)

select *
from final
