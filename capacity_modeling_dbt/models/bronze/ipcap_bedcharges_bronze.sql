with ip as (
    select *
    from {{ source('datahub_msx', 'msx_ip_output') }}
),

charge as (
    select *
    from {{ source('capacity_modeling', 'oe_charge_detail')}}
),

service_group as (
    select LOC_NAME, EPIC_DEPT_ID, EXTERNAL_NAME, SERVICE_GROUP, VALID_FROM,
        coalesce(VALID_TO, current_date()) as VALID_TO
    from {{ source('capacity_modeling', 'service_groups')}}
),

principal_surgeon as (
       select *
       from {{ source('datahub_msx', 'msx_provider_v')}}
),

final as (
    select
        ip.ENCOUNTER_NO,
        ip.EPIC_CSN,
        ip.MSMRN,
        ip.FACILITY_MSX,
        ip.DSCH_DT_SRC,
        ip.DSCH_TIME_SRC,
        ip.ADMIT_DT_SRC,
        ip.ADMIT_TIME_SRC,
        ip.LOS_NO_SRC,
        ip.ENC_ZIP_SRC,
        ip.ADMIT_UNIT_CD_SRC,
        ip.ADMIT_UNIT_DESC_MSX,
        ip.DSCH_UNIT_CD_SRC,
        ip.UNIT_DESC_MSX AS DSCH_UNIT_DESC_MSX,
        ip.ATTENDING_MD_CD_SRC,
        ip.ATTENDING_MD_NAME_MSX,
        ip.VERITY_DEPT_CD_SRC AS ATTENDING_VERITY_DEPT_CD,
        ip.VERITY_DEPT_DESC_SRC AS ATTENDING_VERITY_DEPT_DESC,
        ip.VERITY_DIV_CD_SRC AS ATTENDING_VERITY_DIV_CD,
        ip.VERITY_DIV_DESC_SRC AS ATTENDING_VERITY_DIV_DESC,
        ip.VERITY_REPORT_SERVICE_MSX AS ATTENDING_VERITY_REPORT_SERVICE,
        ip.PRINCIPAL_SURGEON_CD_SRC,
        ip.PRINCIPAL_SURGEON_NAME_MSX,
        principal_surgeon.VERITY_DEPT_1_DESC_SRC as PRINCIPAL_SURGEON_VERITY_DEPT_DESC,
        principal_surgeon.VERITY_DIV_DESC_SRC as PRINCIPAL_SURGEON_VERITY_DIV_DESC,
        ip.MSDRG_CD_SRC,
        ip.MSDRG_DESC_MSX,
        ip.ADMIT_TYPE_CD_SRC,
        ip.ADMIT_TYPE_DESC_SRC,
        ip.VIZ_EX_LOS,
        ip.SERVICE_DESC_MSX,
        charge.FACILITY_ABBR,
        charge.COST_CENTER_C,
        charge.CHARGE_C,
        charge.EPIC_DEPT_ID,
        charge.EPIC_DEPT_NAME,
        charge.QUANTITY,
        charge.SERVICE_DATE,
        charge.CPT_HCPCS_C,
        charge.BILLING_CAT_C,
        charge.BILLING_CAT_DESC,
        charge.RPT_GRP_NINETEEN_C,
        charge.RPT_GRP_NINETEEN_DESC,
        charge.NEW_COST_CENTER_C,
        charge.NEW_GL_COMPONENT,
        service_group.EXTERNAL_NAME,
        service_group.SERVICE_GROUP,
        service_group.LOC_NAME
    from ip
       left join charge
         on ip.ENCOUNTER_NO = cast(charge.HSP_ACCOUNT_ID as string)
       left join service_group
         on charge.EPIC_DEPT_ID = service_group.EPIC_DEPT_ID and
            to_date(charge.SERVICE_DATE, 'yyyyMMdd') between service_group.VALID_FROM and service_group.VALID_TO
       left join principal_surgeon
         on ip.PRINCIPAL_SURGEON_CD_SRC = principal_surgeon.MSH_PROV_CD
)

select * from final