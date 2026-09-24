{% set start_date = var('start_date') %}
{% set end_date = var('end_date') %}

{% if start_date > end_date %}
    {{ exceptions.raise_compiler_error(
        "Invalid date range: start_date must be on or before end_date."
    ) }}
{% endif %}

with parameters as (
    select
        to_date('{{ start_date }}', 'yyyy-MM-dd') as start_date,
        to_date('{{ end_date }}', 'yyyy-MM-dd') as end_date
),

bronze as (
    select *
    from {{ ref('ipcap_bedcharges_bronze') }}
),

formatted as (
    select
        ENCOUNTER_NO,
        cast(cast(EPIC_CSN as bigint) as string) as EPIC_CSN,
        MSMRN,
        case FACILITY_MSX
            when 'BIB' then 'MSB'
            when 'BIP' then 'MSBI'
            when 'RVT' then 'MSW'
            when 'STL' then 'MSM'
            else FACILITY_MSX
        end as FACILITY_MSX,
        DSCH_DT_SRC,
        DSCH_TIME_SRC,
        ADMIT_DT_SRC,
        ADMIT_TIME_SRC,
        LOS_NO_SRC,
        ENC_ZIP_SRC,
        ADMIT_UNIT_CD_SRC,
        ADMIT_UNIT_DESC_MSX,
        DSCH_UNIT_CD_SRC,
        DSCH_UNIT_DESC_MSX,
        ATTENDING_MD_CD_SRC,
        ATTENDING_MD_NAME_MSX,
        ATTENDING_VERITY_DEPT_CD,
        ATTENDING_VERITY_DEPT_DESC,
        ATTENDING_VERITY_DIV_CD,
        ATTENDING_VERITY_DIV_DESC,
        ATTENDING_VERITY_REPORT_SERVICE,
        PRINCIPAL_SURGEON_CD_SRC,
        PRINCIPAL_SURGEON_NAME_MSX,
        PRINCIPAL_SURGEON_VERITY_DEPT_DESC,
        PRINCIPAL_SURGEON_VERITY_DIV_DESC,
        MSDRG_CD_SRC,
        MSDRG_DESC_MSX,
        ADMIT_TYPE_CD_SRC,
        ADMIT_TYPE_DESC_SRC,
        VIZ_EX_LOS,
        SERVICE_DESC_MSX,
        cast(FACILITY_ABBR as string) as FACILITY_ABBR,
        cast(COST_CENTER_C as string) as COST_CENTER_C,
        cast(CHARGE_C as string) as CHARGE_C,
        cast(EPIC_DEPT_ID as string) as EPIC_DEPT_ID,
        cast(EPIC_DEPT_NAME as string) as EPIC_DEPT_NAME,
        QUANTITY,
        coalesce(
            try_cast(cast(SERVICE_DATE as string) as date),
            cast(try_to_timestamp(cast(SERVICE_DATE as string), 'yyyyMMdd') as date)
        ) as SERVICE_DATE,
        cast(CPT_HCPCS_C as string) as CPT_HCPCS_C,
        BILLING_CAT_C,
        trim(upper(BILLING_CAT_DESC)) as BILLING_CAT_DESC,
        cast(RPT_GRP_NINETEEN_C as string) as RPT_GRP_NINETEEN_C,
        cast(RPT_GRP_NINETEEN_DESC as string) as RPT_GRP_NINETEEN_DESC,
        cast(NEW_COST_CENTER_C as string) as NEW_COST_CENTER_C,
        cast(NEW_GL_COMPONENT as string) as NEW_GL_COMPONENT,
        EXTERNAL_NAME,
        coalesce(SERVICE_GROUP, 'Other') as SERVICE_GROUP,
        case LOC_NAME
            when 'THE MOUNT SINAI HOSPITAL' then 'MSH'
            when 'MOUNT SINAI QUEENS' then 'MSQ'
            when 'MOUNT SINAI BROOKLYN' then 'MSB'
            when 'MOUNT SINAI BETH ISRAEL' then 'MSBI'
            when 'MOUNT SINAI MORNINGSIDE' then 'MSM'
            when 'MOUNT SINAI WEST' then 'MSW'
            else LOC_NAME
        end as LOC_NAME
    from bronze
),

enriched as (
    select
        formatted.* except (LOC_NAME),
        case
            when SERVICE_GROUP = 'Other'
              and FACILITY_MSX in ('MSH', 'MSQ', 'MSBI', 'MSB', 'MSM', 'MSW', 'MSSN')
                then FACILITY_MSX
            else LOC_NAME
        end as LOC_NAME,
        trunc(SERVICE_DATE, 'MONTH') as SERVICE_MONTH
    from formatted
),

final as (
    select enriched.*
    from enriched
    cross join parameters
    where enriched.ADMIT_DT_SRC between parameters.start_date and parameters.end_date
      and enriched.DSCH_DT_SRC between parameters.start_date and parameters.end_date
      and enriched.BILLING_CAT_DESC = 'BED CHARGES'
)

select * from final
