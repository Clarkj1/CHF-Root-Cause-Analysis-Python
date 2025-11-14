WITH
  chf_admissions AS (
    SELECT DISTINCT hadm_id, subject_id
    FROM `mimic3_demo.DIAGNOSES_ICD`
    WHERE ICD9_CODE LIKE "428%"
    
  ),

  lab_features AS (
    SELECT 
    HADM_ID,
    AVG(CASE WHEN ITEMID = 50912 THEN valuenum ELSE NULL END) AS avg_creatinine, 
          AVG(CASE WHEN ITEMID = 51006 THEN valuenum ELSE NULL END) AS avg_bun
    FROM `mimic3_demo.LABEVENTS`
    WHERE ITEMID IN (50912, 51006)
    GROUP BY HADM_ID
  ),

  readmission_logic AS (
    SELECT
      adm.HADM_ID,
      adm.SUBJECT_ID,
      adm.ADMITTIME,
      adm.DISCHTIME,
      adm.INSURANCE,

      TIMESTAMP_DIFF(adm.DISCHTIME, adm.ADMITTIME, DAY) AS length_of_stay,

      LEAD(adm.ADMITTIME, 1) OVER(
        PARTITION BY adm.SUBJECT_ID
        ORDER BY adm.ADMITTIME
        ) AS next_admittime
        FROM `mimic3_demo.ADMISSIONS` adm
        INNER JOIN chf_admissions chf
        ON adm.HADM_ID = chf.HADM_ID
  )

SELECT 
  r.HADM_ID, 
  r.SUBJECT_ID, 
  CASE 
    WHEN TIMESTAMP_DIFF(r.ADMITTIME, p.DOB, DAY) / 365.25 > 90 THEN 90 

    ELSE TIMESTAMP_DIFF(r.ADMITTIME, p.DOB, DAY) / 365

    END AS age_on_admission,

    p.gender,
    r.insurance,
    r.length_of_stay,
    l.avg_creatinine,
    l.avg_bun,
    
    CASE 
      WHEN TIMESTAMP_DIFF(r.next_admittime, r.dischtime, DAY) <=30 THEN 1
      ELSE 0
      END AS is_30_day_readmission

FROM readmission_logic r
LEFT JOIN 
  `mimic3_demo.PATIENTS` p
  ON r.SUBJECT_ID = p.SUBJECT_ID
  LEFT JOIN
    lab_features l
    ON r.HADM_ID = l.HADM_ID;


   
