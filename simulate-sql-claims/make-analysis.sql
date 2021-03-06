/*The number of inpatient admissions per patient_id for all patients between the ages of 18 and 64 who have an ICD-9 diagnosis code 290 - 319, and have an inpatient admission between 1/1/2017 and 12/31/2017.  */ 
SELECT SUM(QualifiedAdmissions)*0.1/(COUNT(patient_id)*0.1) AS AverageQualifiedAdmission/*count the encounters of...*/
FROM
  (SELECT patient_id,
          Count(encounter_ID) AS QualifiedAdmissions/*count number of encounters per patient*/ 
   FROM 
     /*an encounter-id based data joining the three datasets*/
     (SELECT *
      FROM /*patient data with age variable*/
        (SELECT ("2020/03/14" - Birthdate) AS Age,
                *
         FROM patient)
      /*filter patient age*/
      WHERE Age BETWEEN 18 AND 64) AS p 
      JOIN /*encounter data*/
        (SELECT *
         FROM Encounter 
         /*filter only admissions in given date and service type*/
         WHERE service_date BETWEEN "2017-01-01" AND "2017-12-31"
           AND service_type IN ("inpatient")) AS e USING (patient_id)
      JOIN
        (SELECT *
         FROM /*diagnosis data*/
           (SELECT Count(CASE
                             WHEN Icd9_code BETWEEN 290 AND 319 THEN 1
                             ELSE NULL
                         END) AS Num_PositiveICD9_Diagnosis, /*count total cases of positive icd9 code*/ *
            FROM Diagnosis /*grouped by encounter_id*/
            GROUP BY encounter_ID)/*filter only positive admissions*/
      WHERE Num_PositiveICD9_Diagnosis>0 ) AS d USING (encounter_id)/*for each patient id*/
   GROUP BY patient_id)
   
/*create a person level table with the number of inpatient, outpatient, and ED visits per person, as well as flags for people who have the following diagnoses: bipolar, or schizophrenia*/
SELECT patient_id,
       Name,
       SUM(inpatient) AS TotalInpatient,
       SUM(outpatient) AS TotalOutpatient,
       SUM(ED) AS TotalED,
       CASE
           WHEN SUM(bipolarSum)>0 THEN 1
           ELSE 0
       END AS FlagBipolar,
       CASE
           WHEN SUM(schizophreniaSum)>0 THEN 1
           ELSE 0
       END AS FlagSchizophrenia /*engineer the desired output*/
FROM /*an encounter-id based data joining the three datasets*/ (
                                                                  (SELECT *
                                                                   FROM patient) AS p /*patient data*/
                                                                JOIN /*encounter data*/
                                                                  (SELECT CASE
                                                                              WHEN service_type ="inpatient" THEN 1
                                                                              ELSE 0
                                                                          END AS inpatient,/*flag for inpatient admission*/
                                                                          CASE
                                                                              WHEN service_type ="outpatient" THEN 1
                                                                              ELSE 0
                                                                          END AS outpatient,/*flag for outpatient admission*/
                                                                          CASE
                                                                              WHEN service_type ="ED" THEN 1
                                                                              ELSE 0
                                                                          END AS ED,/*flag for ED admission*/
                                                                          *
                                                                   FROM Encounter) AS e USING (patient_id)
                                                                JOIN
                                                                  (SELECT SUM (bipolar) AS bipolarSum,/*sum of bipolar in a given encounter*/
                                                                              SUM (schizophrenia) AS schizophreniaSum,/*sum of schizophreniaSum in a given encounter*/
                                                                                  *
                                                                   FROM /*diagnosis data*/
                                                                     (SELECT CASE
                                                                                 WHEN Icd9_code IN (296.00, 296.01, 296.02, 296.03, 296.04, 296.05, 296.06, 296.10, 296.11, 296.12, 296.13, 296.14, 296.15, 296.16, 296.40, 296.41, 296.42, 296.43, 296.44, 296.45, 296.46, 296.50, 296.51, 296.52, 296.53, 296.54, 296.55, 296.56, 296.60, 296.61, 296.62, 296.63, 296.64, 296.65, 296.66, 296.7, 296.80, 296.81, 296.82, 296.89, 296.90, 296.99) THEN 1
                                                                                 ELSE 0
                                                                             END AS bipolar, /*flag for bipolar*/
                                                                             CASE
                                                                                 WHEN Icd9_code IN (295.00, 295.01, 295.02, 295.03, 295.04, 295.05, 295.10, 295.11, 295.12, 295.13, 295.14, 295.15, 295.20, 295.21, 295.22, 295.23, 295.24, 295.25, 295.30, 295.31, 295.32, 295.33, 295.34, 295.35, 295.40, 295.41, 295.42, 295.43, 295.44, 295.45, 295.50, 295.51,295.52, 295.53, 295.54, 295.55, 295.60, 295.61, 295.62, 295.63,295.64, 295.65, 295.70, 295.71, 295.72, 295.73, 295.74, 295.75,
295.80, 295.81, 295.82, 295.83, 295.84, 295.85, 295.90, 295.91, 295.92, 295.93, 295.94, 295.95) THEN 1
                                                                                 ELSE 0
                                                                             END AS schizophrenia, /*flag for schizophreniaSum*/
                                                                             *
                                                                      FROM Diagnosis)
                                                                   /*grouped by encounter_id*/
                                                                   GROUP BY encounter_ID) AS d USING (encounter_id))
GROUP BY patient_id
ORDER BY patient_id 