-- Задача 1*: Анализ эффективности экспедиций

-- Напишите запрос, который определит наиболее и наименее успешные экспедиции, учитывая:
-- - Соотношение выживших участников к общему числу
-- - Ценность найденных артефактов
-- - Количество обнаруженных новых мест
-- - Успешность встреч с существами (отношение благоприятных исходов к неблагоприятным)
-- - Опыт, полученный участниками (сравнение навыков до и после)


-- EXPEDITIONS expedition_id, destination, status, departure_date, return_date (duration); - Экспедиции
-- EXPEDITION_MEMBERS expedition_id, dwarf_id, role, survived                              - Участники экспедиций (survived - выжил/не выжил, предположительно boolean)
-- EXPEDITION_SITES expedition_id, site_id, discovery_date;                                - Места экспедиций
-- EXPEDITION_CREATURES expedition_id, creature_id, encounter_date, outcome                - Встречи с существами (outcome - результат, предположительно, success/fail)
-- EXPEDITION_ARTIFACTS expedition_id, artifact_id, discovery_date, value                  - Артефакты экспедиций

-- DWARF_SKILLS dwarf_id, skill_id, level, experience,date; SKILLS skill_id, name          - Навыки и связь с гномами
-- Без доступа к схеме БД для того, чтобы сохранить исходные параметры навыков для гномов,
--   например, в т.EXPEDITION_MEMBERS и без доступа к логике заполнения DWARF_SKILLS.date,
--   чтобы понять какая именно дата попадает в это поле, остается два варианта: всегда отдавать
--   пустое значение или предположить, при каком формате использования таблицы DWARF_SKILLS
--   решение задачи возможно. Фактически, работать корректно это будет только в случае, если 
--   DWARF_SKILLS представляет собой лог получения гномом опыта по конкретному навыку. 
--   Добавлю в свое решение именно такой вариант, но в реальной задаче заведомо неверный результат (-1)
--   может быть предпочтительнее. 

WITH 
exp_members_stat AS(
   SELECT em.expedition_id
        , SUM(CASE WHEN em.survived THEN 1 ELSE 0 END) survived_members
        , COUNT(em.dwarf_id) total_members
        , SUM(CASE WHEN em.survived THEN 1.0 ELSE 0.0 END)/COUNT(em.dwarf_id) survivial_rate
        , SUM(ds.experience) skill_improvement
        , JSON_ARRAYAGG(em.dwarf_id) member_ids
     FROM expedition_members em
     JOIN expedition e on (em.expedition_id = e.expedition_id)
     LEFT JOIN dwarf_skill ds 
            ON (ds.dwarf_id = em.dwarf_id AND ds.date >= e.departure_date AND ds.date <= e.return_date AND em.survived)
 GROUP BY em.expedition_id
),
exp_artifact_stat AS(
   SELECT ea.expedition_id
        , COUNT(ea.artifact_id) total_qty
        , SUM(ea.value) total_value
        , JSON_ARRAYAGG(ea.artifact_id) artifact_ids
     FROM expedition_artifacts ea
 GROUP BY ea.expedition_id 
),
exp_discovered_sites AS(
   SELECT es.expedition_id
        , COUNT(es.id) total_qty
        , JSON_ARRAYAGG(es.site_id) site_ids
     FROM expedition_sites es
 GROUP BY ex.expedition_id
),
creature_encounter_stat AS (
   SELECT ec.expedition_id
        , ec.creature_id
        , SUM(CASE WHEN ec.outcome = 'success' THEN 1 ELSE 0 END) success_count
        , COUNT(ex.creature_id) total_encounters
        , SUM(CASE WHEN ec.outcome = 'success' THEN 1.0 ELSE 0.0 END) / COUNT(ex.creature_id) encounter_success_rate
     FROM expedition_creature ec
 GROUP BY ec.expedition_id
)
SELECT e.expedition_id
     , e.destination
     , e.status
     , ems.survivial_rate
     , eas.total_value artifacts_value
     , eds.total_qty discovered_sites
     , ces.encounter_success_rate
     , ems.skill_improvement
     , (e.return_date - e.departure_date) expedition_duration 
     , ((ems.survivial_rate 
         + ces.encounter_success_rate
		 + (CASE WHEN MAX(eas.total_value) OVER () = 0 THEN 0.0
                 ELSE (eas.total_value * 1.0) / MAX(eas.total_value) OVER ()
           END)
       ) / 3) overall_success_score
     , JSON_OBJECT(
          'member_ids', ems.member_ids, 
          'artifact_ids', eas.artifact_ids,
          'site_ids', eds.site_ids
      ) AS related_entities
  FROM expedition e
  JOIN exp_members_stat ems ON ems.expedition_id = e.expedition_id
  JOIN exp_artifact_stat eas ON eas.expedition_id = e.expedition_id
  JOIN exp_discovered_sites eds ON eds.expedition_id = e.expedition_id
  JOIN creature_encounter_stat ces ON ces.expedition_id = e.expedition_id;
