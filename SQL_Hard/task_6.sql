-- training_battle_correlation - Влияние тренировок на результаты сражений. Для оценки тренировок возьмем количество тренировок умноженное на эффективность. 
                              -- Качество сражения зависит от: статуса (победа/поражение) и потерь (чем меньше тем лучше). 
                              -- Сложность сражения зависит от: состава отряда (с навыками), снаряжения и его качества, количества и силы противника. 
                              -- Тренировки влияют только на навыки членов отряда, поэтому изменения остальных параметров может нарушить расчет коэффициента корреляции.
                              -- В идеале для расчетов следует рассматривать эффект от всех изменяемых параметров. 
                              -- В этой задаче остановимся на простом CORR - для каждого периода между битвами рассчитаем оценку тренировок и сравним с коэффициентом битвы (1|0.2 * (1 - battle_casualty_rate)).
-- avg_combat_skill_improvement - разница между средним значением боевых навыков отряда при первой битве и при последней.                              

;
WITH sqaud_battle_gaps AS(
	SELECT sb.report_id
         , sb.squad_id
         , sb.date battle_date
         , sb.outcome
         , sb.casualties
         , sb.enemy_casualties
         , LAG(sb.date) OVER (PARTITION BY squad_id ORDER BY sb.date) previous_battle_date
    FROM squad_battles sb
),
warrior_battle_preparations AS(
	SELECT sbg.report_id
         , sbg.squad_id
         , sm.dwarf_id
         , sbg.battle_date
         , sbg.previous_battle_date
         , sbg.outcome
         , sbg.casualties
         , sbg.enemy_casualties
         , EXTRACT (DAY FROM (sbg.battle_date, sbg.previous_battle_date)) preparation_days
         , MAX(ds.level) max_combat_skill
      FROM squad_battle_gaps sbg
 LEFT JOIN squad_members sm ON (sm.squad_id = sbp.squad_id
                                AND sm.join_date < sbp.battle_date
                                AND (sm.end_date IS NULL OR sm.end_date > sbp.battle_date))
 LEFT JOIN dwarf_skills ds ON (ds.dwarf_id = sm.dwarf_id
                               AND ds.date > sbp.previous_battle_date
                               AND ds.date < sbp.battle_date
                               AND ds.skill_id IN (SELECT skill_id FROM skills WHERE category = 'Combat'))
  GROUP BY sb.report_id, sb.squad_id, sm.dwarf_id, sb.battle_date, sb.previous_battle_date
),
squad_battle_preparations AS(
	SELECT wbp.report_id
         , wbp.squad_id 
  	     , COUNT(DISTINCT wbp.dwarf_id) members_qty
         , wbp.battle_date
         , wbp.previous_battle_date
  		 , wbp.outcome
         , wbp.casualties
         , wbp.enemy_casualties
         , wbp.preparation_days
         , AVG(wbp.max_combat_skill) avg_squad_combat_skill
         , COUNT(st.schedule_id) training_count
         , AVG(st.effectivness) avg_training_effectivness
      FROM warrior_battle_preparations wbp
 LEFT JOIN squad_training st ON (st.squad_id = wbp.squad_id
                                 AND st.date > wbp.previous_battle_date
                                 AND st.date < wbp.battle_date)
 GROUP BY wbp.report_id, wbp.squad_id, wbp.battle_date, wbp.previous_battle_date, wbp.preparation_days
),
squad_training_info AS(
    SELECT st.squad_id
         , SUM(schedule_id) total_training_sessions
         , AVG(effectiveness) avg_training_effectivness
         , JSON_ARRAYAGG(st.schedule_ids) training_ids
      FROM squad_training st 
  GROUP BY st.squad_id
),
squad_equipment_info AS(
	SELECT sq.squad_id
         , AVG(e.quality) avg_equipment_quality
         , JSON_ARRAYAGG(sq.equipment_ids) equipment_ids
      FROM squad_equipment sq
      JOIN equipment e ON e.equipment_id = sq.equipment_id
  GROUP BY sq.squad_id
)
SELECT ms.squad_id
     , ms.squad_name
     , ms.formation_type
     , leader.name leader_name
     , COUNT(sbp.report_id) total_battles
     , SUM(CASE WHEN sbp.outcome = 'Victory' THEN 1 ELSE 0 END ) victories
     , ROUND(SUM(CASE WHEN sbp.outcome = 'Victory' THEN 1 ELSE 0 END ) * 1.0 / COUNT (sbp.report_id), 2) * 100 victories_rate
	 , ROUND(SUM(sbp.casualties)*1.0 / SUM(sbp.members_qty) , 2)*100 casualty_rate
     , ROUND(SUM(sbp.casualties)*1.0 / SUM(sbp.enemy_casualties), 2) casualty_exchange_ratio
     , SUM(CASE WHEN sm.exit_date IS NULL THEN 1 ELSE 0 END) current_members
     , COUNT(sm.dwarf_id) total_members_ever
     , ROUND(SUM(CASE WHEN sm.join_date IS NOT NULL AND sm.exit_date IS NULL THEN 1 ELSE 0 END)  * 1.0 / COUNT(sm.dwarf_id), 2) * 100 retention_rate
     , sqi.avg_equipment_quality
	 , COALESCE(sti.total_training_sessions, 0) total_training_sessions
     , ROUND(COALESCE(spb.avg_training_effectivness, 0), 2) avg_training_effectivness
     , CORR(sbp.training_count * sbp.avg_training_effectivness, (CASE WHEN spb.outcome = 'Victory' THEN 1.0 ELSE 0.25 END) * (1.0 - (SUM(sbp.casualties)*1.0 / SUM(sbp.members_qty)))) training_battle_correlation
     , (MAX(spb.avg_squad_combat_skill) - MIN(sbp.avg_squad_combat_skill)) avg_combat_skill_improvement
     , ROUND(
          (1.0 - (SUM(sbp.casualties)*1.0 / SUM(sbp.members_qty))                                   -- survavial_rate
        + SUM(CASE WHEN sbp.outcome = 'Victory' THEN 1 ELSE 0 END ) * 1.0 / COUNT (sbp.report_id)   -- victory_rate
        + COALESCE(spb.avg_training_effectivness, 0) / 3.0)                                         -- training_efficiency
          , 2) overall_effectivness_score
     , JSON_OBJECT(
          'member_ids', JSON_ARRAYAGG(SELECT dwarf_id FROM squad_members WHERE squad_id = ms.squad_id AND exit_date IS NULL),
          'equipment_ids', sqi.equipment_ids,
          'battle_report_ids', JSON_ARRAYAGG(SELECT report_id FROM battle_report WHERE squad_id = ms.squad_id),
          'training_ids', sti.training_ids
       ) as related_entities
  FROM military_squad ms
LEFT JOIN dwarves leader ON leader.dwarf_id = ms.leader_id                  
LEFT JOIN squad_battle_preparations sbp on sbp.squad_id = ms.squad_id
LEFT JOIN squad_members sm ON (sm.squad_id = ms.squad_id)
LEFT JOIN squad_equipment_info sqi on sqi.squad_id = ms.dwarf_id
LEFT JOIN squad_training_info sti on sti.squad_id = ms.squad_id
 GROUP BY ms_squad.id, ms.squad_name, ms.formation_type, leader.name
        , sqi.avg_equipment_quality
;
